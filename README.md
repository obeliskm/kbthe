### KBTHE

The KBTHE calls for three sections:

1) upload transaction files from a local directory into S3
2) load transaction files into Snowflake
3) a CI/CD system for the project


#### S3 upload

1) upload a local directory into S3

- directory will be named "/data", files will be named transactions_<datestamp>.csv
- row contents include timestamps that span multiple hours
- destination in S3 will be s3://<bucketname>/transactions/2026/09/01/transactions_20260901.csv - so will require extraction of the time stamp from the filename to generate the object prefix in S3

assumptions:
- upload is a regular process - filenaming suggests it might be a daily process (ie the upstream system produces one file per day)
- data is not in git, and not reasonable to put in git, so won't be visible out-of-the-box to a cloud based CICD service (GHA, ADO)
- the THE notes: 'the workflow should be orchestrated with airflow' so reasonable to assume that there's an existing airflow installation that has visibility of the local data
- the THE is silent on how the DAG gets access to the bucket (ie how the DAG is authenticated to AWS).  For the purposes of the THE, running from a local machine in the context of a human (ie that a human supplies a working AWS_PROFILE).  This is a poor approach for a regular (daily) task (not least because the user would need to keep logging in), as opposed to granting permissions (if running in AWS) or an OIDC/WebIdentity integration to allow short term creds to be used.

thoughts:
in real life there are many, many ways this could be done, most of which are not in the spirit of the THE:
- modify the upstream system to write directly to S3
- use existing tools (the AWS CLI)

implementation:
- a simple DAG in dags/s3-copy.py
- minimal tests in /tests

todo:
- mock the s3 connection to allow it to be tested without requiring AWS credentials
- improve test coverage

#### Snowflake load

can be "Python code /or Airflow DAG/or Snowflake SQL", 

thoughts:
there are several ways this could be achieved:
- extend the s3 upload DAG above to push the data to snowflake.
- write a second DAG that uses S3KeySensor to check for new files arriving in S3, and
then CopyFromExternalStageToSnowflakeOperator to copy the data into Snowflake
- use snowpipe - integrate AWS-Snowflake with an external stage in Snowflake, with SQS
or lambda integration so that new transaction files are processed as they are created
in S3

The first option doesn't feel like a good one, as it mixes concerns - ideally the
process writing into s3 is decoupled from the process sending to snowflake, so that
they can be developed/changed/run independently. 

Choosing between the other two options really depends on the specific circumstances:
- writing a second DAG feels like the correct approach if there is existing airflow
infrastructure with access to Snowflake - adding yet another DAG is the path of least
resistance.  OTOH, it's a polling solution run on a schedule, so may have timeliness
issues, and depending on the number of files in the S3 bucket the costs of repeatedly
scanning the bucket may need to be considered. 
- integrating snowpipe with AWS, so that snowpipe pulls transaction files soon after
they're written to S3, will be more responsive - data will arrive in snowflake sooner.
OTOH, it's a process being orchestrated outside of airflow, which increases cognitive
load on humans.

code (or at least, discussion about possible code) in /snowflake

#### CI/CD

deploy the project - that is, the code for 1/2.  be prepared to describe:
- how environments are promoted
- how config differs between envs
- how application artifacts can be versioned. -= consider dag_bundles feature in airflow v3

There is a very basic, untested set of Github Actions workflows in .github/workflows.  The
intended approach is:

- developer pushes change to a feature branch, and creates a pull request.  At this point,
and for every subsequent push to the feature branch, GHA will run lints, unit tests, and other
tests that can be run in isolated containers without requiring write access to external systems,
so that test suites for multiple feature branches can run concurrently and be interrupted
without interfering with each other.
- once all PR tests have passed green and the PR is approved and merged, then the feature branch
tests may have to be repeated on main, then the workflow can build any artifacts required, then
deploy to a non-prod environment, run final smoke tests, then deploy to prod.

it's not technically part of the GHA config, but I'd also consider adding a pre-commit git hook
to run fast lints and tests before every git commit by the developer - saves a lot of cosmetic
rework early in the process.

how environments are promoted is a nuanced question, and depends on several factors:
- how often pushes to main are happening (how many deploys per day/week)
- the quality and completeness of the smoke testing is of the non-prod environment
if the answers are "often" and "covers all cases" then promotion can be automatic - once the 
non-prod deploy has passed smoke tests, prod can begin.

how configuration differs between environments - that is, how to cater for the inevitable 
differences between prod and non-prod environments.  The workflow here doesn't cate for that,
but in general I'd expect to deal with this by punting configuration differences outside of the
code - in a very naive sense, it could just be environment variables set by different stages in
the CI system.  That can be messy to manage manually in CI config files, so often is extended
by pulling config from an external configuration manager - AWS Parameter Store (or the comparable
equivalent in other clouds), or Vault/OpenBao.  My code cheerfully hardcodes configuration data
that should be pulled from the environment, it's disgraceful.

how application artifacts can be versioned.   Clearly versioning DAGs seems like a good idea, to
avoid the risk of a DAG getting updated midway through a pipeline.  At a very basic level, I'd
expect the pipeline to work with the specific git commit, rather than just naively pulling 'main'
at some arbitrary point in the pipeline, to avoid the possibility that a subsequent push to main
gets pulled into prod before it's been fully tested.  Beyond that, there are mechanisms to put
explicit versions on artifacts (dag bundles, OCI images) - particularly useful if processes
outside the pipeline need to be able to pull a specific version.


#### required infrastructure

Presently, it's just an S3 bucket in an AWS account, the terraform for that is in the /terraform
tree.  Further things I'd do in terraform for a 'proper' environment
- separate AWS accounts for non-prod/prod
- OIDC integration between github and AWS for each account, so that GHA can make changes
- airflow installations in each account, probably running AWS MWAA

and I'd add a separate 'infra' pipeline into GHA to apply the terraform changes to each account, 
so that I didn't have to bounce around running multiple terraform applies.  If I was going to have
separate snowflake environments for non-prod/prod, then I'd also do that in terraform, using the 
snowflake provider.

