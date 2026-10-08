from datetime import datetime, timedelta
from airflow.sdk import dag, task


@dag(
    "KBTHE_S3_copy",
    default_args={
        "depends_on_past": False,
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
    },
    description="A simple DAG to copy local files to S3",
    schedule=timedelta(days=1),
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["KBTHE"],
)
def copy_local_to_s3():
    """
    ### Copy local files to S3
    A simple DAG which checks CSV files in the data directory, and copies them to S3
    if they have a valid datestamp in the filename.

    TODO:
    - variables for PATH and BUCKET_NAME, so that the DAG can be run in different environment
    without changing the code.
    - consider whether to use LocalFilesystemToS3Operator instead of the boto3 client - may be
    more "airflow-native".
    - do something more reasonable with managing AWS credentials - currently they are assumed to be in
    the environment, which is pretty poor form.

    """

    import os
    import logging

    PATH = "/home/simon/data"
    BUCKET_NAME = "kbthe-transactions20261007042152138500000001"

    @task()
    def validate_local_files():
        """
        #### Validate local files task
        Scan a local directory, return the list of files named transaction_<datestamp>.csv.
        """

        # get list of transaction_*.csv files in ~/data directory
        csv_files = [
            f
            for f in os.listdir(PATH)
            if f.startswith("transactions_") and f.endswith(".csv")
        ]

        logging.info(
            "Found %d transaction_*.csv files in %s directory.", len(csv_files), PATH
        )

        # empty list to hold valid files
        valid_csv_files = []

        # loop through each CSV file and check it has a valid datestamp
        for csv_file in csv_files:
            # extract date stamp from filename
            date_str = csv_file.split("_")[1].split(".")[0]
            # and test that it is 8 digits
            if date_str.isdigit() and len(date_str) == 8:
                valid_csv_files.append(csv_file)
            else:
                logging.warning(
                    "Skipping %s as filename lacks a valid datestamp.", csv_file
                )
                continue
        return valid_csv_files

    @task(multiple_outputs=True)
    def copy_to_s3(csv_files: list):
        """
        #### Copy to S3 task
        Copy valid CSV files to S3.

        Assumes that the csv_files input has had any invalid file names filtered in the prevous
        task, so this loops through each file constructing the S3 path, copying to S3, and then
        renaming the local file to indicate that it has been copied.
        """

        import boto3
        from botocore.exceptions import ClientError

        s3 = boto3.client("s3")

        for csv_file in csv_files:
            # extract date stamp from filename
            date_str = csv_file.split("_")[1].split(".")[0]
            year = date_str[:4]
            month = date_str[4:6]
            day = date_str[6:8]

            # s3 object PATH will be in the format "s3://<BUCKET_NAME>/<year>/<month>/<day>/<filename>"
            s3_path = f"{year}/{month}/{day}/{csv_file}"
            full_s3_path = f"s3://{BUCKET_NAME}/{s3_path}"

            logging.info("Copying %s to %s...", csv_file, full_s3_path)
            # copy to S3 using AWS s3 SDK
            try:
                response = s3.upload_file(f"{PATH}/{csv_file}", BUCKET_NAME, s3_path)
            except ClientError as e:
                # if the copy to s3 failed, log an error and the loop will continue to the next
                # file.  The failed file will will be retried on the next DAG run - which may
                # recover if the failure was caused by a temporary network issue or S3 outage.
                logging.error(e)
                continue

        # if the copy was successful, log success and rename the file to "transactions_YYYYMMDD.csv.uploaded
        # s3_client.upload_file(f"{PATH}/{csv_file}", BUCKET_NAME, f"{year}/{month}/{day}/{csv_file}")
        logging.info("Copied %s to %s.", csv_file, full_s3_path)
        uploaded_file = f"{csv_file}.uploaded"
        logging.info("Renaming %s to %s...", csv_file, uploaded_file)
        os.rename(f"{PATH}/{csv_file}", f"{PATH}/{uploaded_file}")

        return ("Copied %s to %s.", csv_file, full_s3_path)

    copy_to_s3(validate_local_files())


copy_local_to_s3()

# this is no longer needed for testing - as the DAG is now defined as normal functions,
# we can do normal unit testing for each function
# if __name__ == "__main__":
#    dag.test()
