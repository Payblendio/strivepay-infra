#!/usr/bin/env python3
"""Create a custom-format dump from the existing managed staging database."""

import json
import os
import pathlib
import subprocess
import sys
from urllib.parse import urlparse


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: dump-managed-db.py API_ENV_JSON OUTPUT.dump")
    values = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8-sig"))
    jdbc_url = values["STRIVEPAY_DB_URL"]
    if not jdbc_url.startswith("jdbc:"):
        raise SystemExit("Expected a JDBC database URL")
    parsed = urlparse(jdbc_url.removeprefix("jdbc:"))
    command = [
        "pg_dump",
        "--host", parsed.hostname or "",
        "--port", str(parsed.port or 5432),
        "--username", values["STRIVEPAY_DB_USERNAME"],
        "--dbname", parsed.path.lstrip("/"),
        "--format", "custom",
        "--no-owner",
        "--no-acl",
        "--file", sys.argv[2],
    ]
    environment = os.environ.copy()
    environment["PGPASSWORD"] = values["STRIVEPAY_DB_PASSWORD"]
    environment["PGSSLMODE"] = "require"
    subprocess.run(command, env=environment, check=True)
    print(f"Database dump created at {sys.argv[2]}; credentials were not displayed.")


if __name__ == "__main__":
    main()

