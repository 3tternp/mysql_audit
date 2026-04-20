param(
    [Parameter(Mandatory = $true)] [string]$HostName,
    [Parameter(Mandatory = $true)] [int]$Port,
    [Parameter(Mandatory = $true)] [string]$Username,
    [Parameter(Mandatory = $true)] [string]$Password,
    [string]$OutDir = ".\output"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command mysql -ErrorAction SilentlyContinue)) {
    throw "The MySQL command-line client 'mysql' was not found in PATH."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Invoke-MySqlQuery {
    param(
        [Parameter(Mandatory = $true)] [string]$Query,
        [string]$OutputFile
    )

    $args = @(
        "-h$HostName",
        "-P$Port",
        "-u$Username",
        "-p$Password",
        "--batch",
        "--raw",
        "--skip-column-names",
        "-e",
        $Query
    )

    if ($OutputFile) {
        & mysql @args | Out-File -FilePath $OutputFile -Encoding utf8
    }
    else {
        & mysql @args
    }
}

Write-Host "[*] Enabling MySQL general log to TABLE..."
Invoke-MySqlQuery -Query "SET GLOBAL log_output = 'TABLE'; SET GLOBAL general_log = 'ON';"

Write-Host "[*] Exporting executed SQL statements..."
Invoke-MySqlQuery -Query @"
SELECT
  event_time,
  user_host,
  thread_id,
  command_type,
  REPLACE(REPLACE(argument, '\n', ' '), '\r', ' ') AS executed_sql
FROM mysql.general_log
WHERE command_type = 'Query'
ORDER BY event_time DESC;
"@ -OutputFile (Join-Path $OutDir "all_queries.tsv")

Write-Host "[*] Exporting query counts by user..."
Invoke-MySqlQuery -Query @"
SELECT
  SUBSTRING_INDEX(user_host, '[', 1) AS username,
  COUNT(*) AS total_queries
FROM mysql.general_log
WHERE command_type = 'Query'
GROUP BY username
ORDER BY total_queries DESC;
"@ -OutputFile (Join-Path $OutDir "query_count_by_user.tsv")

Write-Host "[*] Exporting access logs..."
Invoke-MySqlQuery -Query @"
SELECT
  event_time,
  user_host,
  command_type,
  REPLACE(REPLACE(argument, '\n', ' '), '\r', ' ') AS details
FROM mysql.general_log
WHERE command_type IN ('Connect', 'Quit')
ORDER BY event_time DESC;
"@ -OutputFile (Join-Path $OutDir "access_logs.tsv")

Write-Host "[+] Export complete: $OutDir"
