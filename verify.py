"""Check a dataset against its rules.

    python verify.py ecommerce path/to/ecommerce.sqlite

Every dataset folder has a checks.sql file: one query per rule, each counting the rows that break the rule.
This script runs them all on a SQLite file and prints the result. It needs only Python 3.8+ (no packages).
For the cleaning dataset, run it on the clean file to see every rule hold, or on the dirty file to see what
the planted defects break.
"""
import shutil
import sqlite3
import sys
import tempfile
from pathlib import Path


def rules(folder: Path):
    """Yields (rule, query) pairs from checks.sql: a '-- rule' comment line followed by its query."""
    rule, sql = None, []
    for line in (folder / "checks.sql").read_text(encoding="utf-8").splitlines():
        if line.startswith("-- "):
            rule, sql = line[3:], []
        elif line.strip() and rule:
            sql.append(line)
            if line.rstrip().endswith(";"):
                yield rule, "\n".join(sql)
                rule = None


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    folder, db = Path(__file__).resolve().parent / sys.argv[1], Path(sys.argv[2])
    if not (folder / "checks.sql").exists():
        sys.exit(f"No dataset folder named '{sys.argv[1]}' here.")
    if not db.exists():
        sys.exit(f"File not found: {db}")
    # The checks run on a temporary copy with an index on every id column, so the joins are fast
    # and your file is left untouched.
    work = Path(tempfile.mkdtemp()) / db.name
    shutil.copyfile(db, work)
    con = sqlite3.connect(work)
    for (table,) in con.execute("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'").fetchall():
        for column in [r[1] for r in con.execute(f'PRAGMA table_info("{table}")')]:
            if column.endswith("_id") or column in ("email", "city"):
                con.execute(f'CREATE INDEX IF NOT EXISTS "ix_{table}_{column}" ON "{table}" ("{column}")')
    held = broken = 0
    for rule, sql in rules(folder):
        count = con.execute(sql).fetchone()[0] or 0
        if count:
            broken += 1
            print(f"  BROKEN  {count:>9,} rows  {rule}")
        else:
            held += 1
            print(f"  ok                      {rule}")
    print(f"\n{held} of {held + broken} rules hold" + ("." if not broken else f"; {broken} broken."))
    con.close()
    shutil.rmtree(work.parent, ignore_errors=True)
    sys.exit(1 if broken else 0)


if __name__ == "__main__":
    main()
