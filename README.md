# MySQL User Activity Audit Scripts

A small GitHub-ready toolkit to help collect and review MySQL user activity, executed SQL statements, and connection events.

## What this repository provides

This repository includes:

- **SQL scripts** to enable and query MySQL general logs
- **Bash script** to export query and access data into TSV files
- **PowerShell script** to export the same data from Windows
- **Python script** to export activity into CSV and JSON formats
- a **sample `.gitignore`**

## Important limitation

MySQL does **not** automatically retain a full historical record of every command executed by every user unless logging or auditing was already enabled earlier.

You can retrieve historical activity only if one of the following had already been configured:

- MySQL **general query log**
- an **audit plugin**
- **binary logging** for relevant statement coverage
- external logging, monitoring, or SIEM ingestion

If none of those were enabled before, these scripts will help you start collecting activity **from now onward**.

## Included files

```text
mysql_audit_repo/
├── README.md
├── .gitignore
└── scripts/
    ├── enable_general_log.sql
    ├── query_activity_reports.sql
    ├── export_mysql_audit.sh
    ├── export_mysql_audit.ps1
    └── export_mysql_audit.py
```

## Requirements

### MySQL

- MySQL 5.7+ or 8.x recommended
- administrative privileges required for enabling global logging

### Bash script

- Linux host with `mysql` client installed

### PowerShell script

- Windows PowerShell 5.1+ or PowerShell 7+
- MySQL command-line client available in PATH

### Python script

- Python 3.8+
- package: `mysql-connector-python`

Install Python dependency with:

```bash
pip install mysql-connector-python
```

## 1) Enable logging

Run the SQL script below using a privileged MySQL account:

```bash
mysql -u root -p < scripts/enable_general_log.sql
```

This enables:

- `log_output = TABLE`
- `general_log = ON`

That causes activity to be written to `mysql.general_log`.

## 2) Review activity directly in MySQL

Run:

```bash
mysql -u root -p < scripts/query_activity_reports.sql
```

This returns:

- recent SQL statements
- per-user query counts
- detailed user activity
- connect and quit events

## 3) Export data with Bash

Example:

```bash
chmod +x scripts/export_mysql_audit.sh
./scripts/export_mysql_audit.sh \
  --host 127.0.0.1 \
  --port 3306 \
  --user root \
  --password 'YourStrongPassword' \
  --outdir ./output
```

Generated files:

- `all_queries.tsv`
- `query_count_by_user.tsv`
- `access_logs.tsv`

## 4) Export data with PowerShell

Example:

```powershell
.\scripts\export_mysql_audit.ps1 `
  -HostName 127.0.0.1 `
  -Port 3306 `
  -Username root `
  -Password 'YourStrongPassword' `
  -OutDir .\output
```

Generated files:

- `all_queries.tsv`
- `query_count_by_user.tsv`
- `access_logs.tsv`

## 5) Export data with Python

Example:

```bash
python scripts/export_mysql_audit.py \
  --host 127.0.0.1 \
  --port 3306 \
  --user root \
  --password 'YourStrongPassword' \
  --outdir ./output
```

Generated files:

- `all_queries.csv`
- `query_count_by_user.csv`
- `access_logs.csv`
- `all_queries.json`

## Security notes

These logs may contain:

- SQL text with sensitive business data
- secrets passed unsafely in statements
- usernames, hosts, and application connection details

Protect the exported files carefully and apply least-privilege access controls.

## Performance warning

The MySQL **general log** can add overhead and increase storage usage, especially on busy production systems.

Disable it when finished if you do not need continuous logging:

```sql
SET GLOBAL general_log = 'OFF';
```

## Recommended production approach

For quick investigations:

- use `mysql.general_log`
- use `performance_schema` for recent activity

For long-term audit/compliance use cases:

- use a supported MySQL audit plugin
- rotate logs regularly
- forward logs to SIEM/Syslog
- restrict access to audit data

## Suggested GitHub repo name

- `mysql-user-activity-audit`
- `mysql-command-audit-scripts`
- `mysql-query-audit-toolkit`

## Disclaimer

Test in a non-production environment first. Review logging impact, storage growth, and access controls before enabling in production.
