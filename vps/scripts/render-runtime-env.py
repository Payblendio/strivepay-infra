#!/usr/bin/env python3
"""Render Docker env files from preserved Lightsail environment JSON."""

import json
import pathlib
import sys


def docker_quote(value: object) -> str:
    # Compose interpolates dollar signs even inside env_file values. Doubling
    # them preserves the original credential verbatim inside the container.
    text = "" if value is None else str(value)
    return json.dumps(text.replace("$", "$$"), ensure_ascii=False)


def write_env(source: pathlib.Path, destination: pathlib.Path) -> dict[str, str]:
    values = json.loads(source.read_text(encoding="utf-8-sig"))
    values["STRIVEPAY_DB_URL"] = "jdbc:postgresql://postgres:5432/strivepay_consumer"
    values["STRIVEPAY_DB_USERNAME"] = "strivepay"
    destination.write_text(
        "".join(f"{key}={docker_quote(value)}\n" for key, value in sorted(values.items())),
        encoding="utf-8",
    )
    destination.chmod(0o600)
    return values


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: render-runtime-env.py SECRETS_DIR")
    directory = pathlib.Path(sys.argv[1]).resolve()
    api = write_env(directory / "api-environment.json", directory / "api.env")
    write_env(directory / "worker-environment.json", directory / "worker.env")
    password = api["STRIVEPAY_DB_PASSWORD"]
    (directory / "postgres.env").write_text(
        "POSTGRES_DB=strivepay_consumer\n"
        "POSTGRES_USER=strivepay\n"
        f"POSTGRES_PASSWORD={docker_quote(password)}\n",
        encoding="utf-8",
    )
    (directory / "postgres.env").chmod(0o600)
    print("Runtime environment files rendered; secret values were not displayed.")


if __name__ == "__main__":
    main()

