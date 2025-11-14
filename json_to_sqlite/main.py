#!/usr/bin/env python

import argparse
import datetime
import json
import logging
import os
import time

import pandas as pd
import sqlalchemy


def setup_logging(uuid: str) -> logging.Logger:
    logging.basicConfig(
        filename=os.path.join(f"{uuid}.log"),
        level=logging.INFO,
        filemode="w",
        format="%(asctime)s %(levelname)s %(message)s",
        datefmt="%Y-%m-%d_%H:%M:%S_%Z",
    )
    logging.getLogger("sqlalchemy.engine").setLevel(logging.INFO)
    logger = logging.getLogger(__name__)
    return logger


def main() -> int:
    parser = argparse.ArgumentParser("convert json to column based sqlite")

    parser.add_argument("--input_json", required=True)
    parser.add_argument("--job_uuid", required=True)
    parser.add_argument("--table_name", required=True)

    args = parser.parse_args()
    input_json = args.input_json
    job_uuid = args.job_uuid
    table_name = args.table_name

    sqlite_name = f"{job_uuid}.db"
    engine_path = f"sqlite:///{sqlite_name}"
    engine = sqlalchemy.create_engine(engine_path, isolation_level="SERIALIZABLE")

    time_seconds = time.time()
    datetime_now = str(datetime.datetime.now())

    with open(input_json) as f:
        data = json.load(f)

    data["datetime_now"] = datetime_now
    data["time_seconds"] = [time_seconds]

    df = pd.DataFrame(data)
    df.to_sql(table_name, engine, if_exists="append")
    return 0


if __name__ == "__main__":
    main()
