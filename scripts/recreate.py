"""Re-create a dataset from this repository with the GenerateRealData API.

    export GRD_API_KEY=grd_live_...          (PowerShell:  $env:GRD_API_KEY = "grd_live_...")
    python scripts/recreate.py ecommerce               PostgreSQL script + SQLite file
    python scripts/recreate.py ecommerce csv           one CSV per table, zipped
    python scripts/recreate.py dirty-ecommerce clean   the cleaning dataset without its planted defects

It sends the dataset's plan.json, schema.sql and seed, so the result is the same data as the published files.
Each generated row uses one Core row of your plan; no AI rows are used. Files are saved to ./downloads/.
API reference: https://www.generaterealdata.com/docs/api/
"""
import json
import os
import sys
import time
from pathlib import Path

import requests

API = "https://www.generaterealdata.com/api/v1"
ROOT = Path(__file__).resolve().parent.parent


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    slug, option = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "sql")
    folder = ROOT / slug
    if not (folder / "plan.json").exists():
        sys.exit(f"No dataset folder named '{slug}'.")
    key = os.environ.get("GRD_API_KEY")
    if not key:
        sys.exit("Set the GRD_API_KEY environment variable to your API key first.")
    headers = {"Authorization": f"Bearer {key}"}
    settings = json.loads((folder / "generation.json").read_text(encoding="utf-8"))
    plan = json.loads((folder / "plan.json").read_text(encoding="utf-8"))
    plan["_source_ddl"] = (folder / "schema.sql").read_text(encoding="utf-8")

    body = {"mode": "schema", "schema": plan, "rows": settings["rows_requested"], "seed": settings["seed"],
            "name": settings["title"], "format": "csv" if option == "csv" else "sql"}
    if body["format"] == "sql":
        body["dialect"] = "postgresql"
    if settings.get("anomalies") and option != "clean":
        body.update(anomalies=True, anomaly_rate=settings["anomaly_rate"])

    check = requests.post(f"{API}/datasets", json={**body, "dry_run": True}, headers=headers, timeout=70).json()
    if "error" in check:
        sys.exit(f"{check['error']['code']}: {check['error']['message']}")
    print(f"Needs {check['credits_required']:,} Core rows (you have {check['credits_available']:,}) and "
          f"{check['ai_rows_required']} AI rows.")

    data = requests.post(f"{API}/datasets", json=body, headers=headers, timeout=70).json()
    if "error" in data:
        sys.exit(f"{data['error']['code']}: {data['error']['message']}")
    while data["status"] not in ("ready", "failed"):
        time.sleep(6)
        data = requests.get(f"{API}/datasets/{data['id']}", headers=headers, timeout=30).json()
        print("  ", data["status"])
    if data["status"] == "failed":
        sys.exit(data["error"]["message"])
    print("Rows per table:", data["rows_per_table"])

    out = ROOT / "downloads"
    out.mkdir(exist_ok=True)
    name = slug + ("_clean" if option == "clean" else "")
    files = [("", f"{name}.zip" if option == "csv" else f"{name}.sql")] + ([] if option == "csv" else [("?file=db", f"{name}.sqlite")])
    for query, filename in files:
        with requests.get(f"{API}/datasets/{data['id']}/download{query}", headers=headers, stream=True, timeout=600) as r:
            r.raise_for_status()
            with open(out / filename, "wb") as f:
                for chunk in r.iter_content(1 << 20):
                    f.write(chunk)
        print("Saved", out / filename)


if __name__ == "__main__":
    main()
