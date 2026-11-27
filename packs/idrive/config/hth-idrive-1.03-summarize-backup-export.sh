#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: idrive-1.3
#   guide: https://howtoharden.com/guides/idrive/#13-review-backup-activity-reports
#   profile: L2
#   mode: read-only
#   requires: Bash, Python 3 standard library, controlled IDrive Backup Activity CSV, IDRIVE_REPORT_CSV, IDRIVE_STATUS_COLUMN, IDRIVE_APPROVED_STATUS
# Vendor contract: https://help.idrive.com/dashboard-faq-6series
# HTH Guide Excerpt: begin summarize-backup-export
set +x
set -euo pipefail

: "${IDRIVE_REPORT_CSV:?Set the path to a local IDrive Backup Activity CSV export}"
: "${IDRIVE_STATUS_COLUMN:?Set the exact exported status column header}"
: "${IDRIVE_APPROVED_STATUS:?Set the exact status value your policy treats as successful}"
# Export formats vary. Require the caller to identify the real header and success label.
python3 -I - <<'PYTHON'
import csv
import json
import os
from pathlib import Path

path = Path(os.environ["IDRIVE_REPORT_CSV"])
column = os.environ["IDRIVE_STATUS_COLUMN"].strip()
approved = os.environ["IDRIVE_APPROVED_STATUS"].strip()
if not column or not approved or not path.is_file() or path.stat().st_size > 16 * 1024 * 1024:
    raise SystemExit("Expected a local CSV of at most 16 MiB and nonblank status mapping.")

total = matched = other = missing = 0
try:
    with path.open(encoding="utf-8-sig", newline="") as report:
        rows = csv.reader(report, strict=True)
        header = [cell.strip() for cell in next(rows, [])]
        if header.count(column) != 1:
            raise SystemExit("The exact status column must occur once in the exported CSV.")
        idx = header.index(column)
        for row in rows:
            if not row:
                continue
            if len(row) != len(header):
                raise SystemExit("Malformed CSV row width; no assurance produced.")
            total += 1
            value = row[idx].strip()
            if not value:
                missing += 1
            elif value == approved:
                matched += 1
            else:
                other += 1
except (OSError, UnicodeError, csv.Error):
    raise SystemExit("Cannot parse the export as UTF-8 CSV.") from None

print(json.dumps({"scope": "export-only", "rows": total,
                  "approvedStatus": matched, "otherStatus": other, "missingStatus": missing}))
raise SystemExit(0 if total and not (other or missing) else 1)
PYTHON
# HTH Guide Excerpt: end summarize-backup-export
