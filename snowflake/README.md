Hooking s3 up to snowflake, a short essay

As noted in the main README, there are many ways to plumb S3 to Snowflake.  
There are a couple of mechanisms to support loading data in near-realtime -
soon after the file is created in S3, rather than waiting for DAG to poll
the bucket on a schedule.  Those mechanisms are broadly:

- configure AWS Eventbridge to trigger a lambda when an object arrives in
the bucket, that lambda makes a call to the snowpipe REST API to instruct
snowpipe to process the file.
- configure AWS SQS integration between S3 and Snowflake so that when an
object arrives in the bucket, snowpipe processes the file.

They're similar processes - the lambda process is more flexible (in that
it allows us to do other things in the lambda), but also somewhat more
complicated in that we need to manage keypairs for authentication from
lambda to Snowflake.  The SQS process is somewhat simpler, in that we
are not responsible for any running code, and athentication is configured
during setup.

The process for the SQS integration is described here

https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto-s3

I'm not going to repeat chapter and verse here, essentially, it boils down to

in snowflake;
- configure an external stage pointing at the S3 bucket
- configure a cloud storage integration, using an AWS IAM role
- configure a pipe with auto-ingest
- configure a snowflake user to run the ingestion

the snowflake config will yield an AWS IAM user and SQS queue ARN, then use
that to configure AWS:

- create a policy granting access to the S3 bucket
- tie the policy to an IAM role
- allow the snowflake IAM user to access objects in the S3 bucket
- create an SNS queue for object event changes from S3
- subscribe the Snowflake SQS queue to our SNS queue

my inclination would be to do this in terraform, for every environment that
needed integration S3 and Snowflake

