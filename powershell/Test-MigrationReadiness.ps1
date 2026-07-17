<#
.SYNOPSIS
    Pre-flight readiness assessment for a source Windows / SQL Server host
    that is about to be migrated into the shared cloud platform.

.DESCRIPTION
    Runs a battery of non-destructive checks against a legacy source
    environment and emits a structured readiness report. Every check
    returns a PASS, WARN, or FAIL result so the migration engineer can
    make a go or no-go call from one screen.

    Checks:
      * Network reachability of the source host
      * SQL Server connectivity and version floor
      * Database size versus the tenant definition
      * Age of the most recent full backup
      * Free disk headroom for the final backup and log tail
      * Pending reboot state (a classic silent cutover killer)

.PARAMETER ComputerName
    Source host name or IP address.

.PARAMETER SqlInstance
    SQL Server instance, for example SRC-SQL01 or SRC-SQL01\PROD.

.PARAMETER DatabaseName
    Database scheduled for migration.

.PARAMETER MinSqlMajorVersion
    Lowest SQL Server major version accepted without a WARN. Defaults to 13
    (SQL Server 2016).

.PARAMETER MaxBackupAgeHours
    Oldest acceptable full backup, in hours. Defaults to 26.

.EXAMPLE
    ./Test-MigrationReadiness.ps1 -ComputerName src-app01 -SqlInstance src-sql01 -DatabaseName acmedb

.NOTES
    Author: Tyrone Madison
    Requires: PowerShell 5.1+, SqlServer module for the SQL checks.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ComputerName,

    [Parameter(Mandatory = $true)]
    [string]$SqlInstance,

    [Parameter(Mandatory = $true)]
    [string]$DatabaseName,

    [ValidateRange(11, 20)]
    [int]$MinSqlMajorVersion = 13,

    [ValidateRange(1, 168)]
    [int]$MaxBackupAgeHours = 26
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$results = New-Object System.Collections.Generic.List[object]

function Add-CheckResult {
    param(
        [string]$Check,
        [ValidateSet('PASS', 'WARN', 'FAIL')]
        [string]$Status,
        [string]$Detail
    )
    $results.Add([pscustomobject]@{
        Check  = $Check
        Status = $Status
        Detail = $Detail
    })
}

# 1. Network reachability -------------------------------------------------
try {
    $ping = Test-Connection -ComputerName $ComputerName -Count 2 -Quiet
    if ($ping) {
        Add-CheckResult -Check 'Network reachability' -Status 'PASS' -Detail "$ComputerName answered ICMP"
    }
    else {
        Add-CheckResult -Check 'Network reachability' -Status 'FAIL' -Detail "$ComputerName did not answer ICMP"
    }
}
catch {
    Add-CheckResult -Check 'Network reachability' -Status 'FAIL' -Detail $_.Exception.Message
}

# 2. SQL connectivity and version ----------------------------------------
$sqlAvailable = $null -ne (Get-Module -ListAvailable -Name SqlServer | Select-Object -First 1)
if (-not $sqlAvailable) {
    Add-CheckResult -Check 'SQL Server version' -Status 'WARN' -Detail 'SqlServer module not installed on this workstation, skipped'
}
else {
    try {
        $versionRow = Invoke-Sqlcmd -ServerInstance $SqlInstance -Query "SELECT SERVERPROPERTY('ProductMajorVersion') AS MajorVersion, SERVERPROPERTY('ProductVersion') AS FullVersion" -TrustServerCertificate
        $major = [int]$versionRow.MajorVersion
        if ($major -ge $MinSqlMajorVersion) {
            Add-CheckResult -Check 'SQL Server version' -Status 'PASS' -Detail "Version $($versionRow.FullVersion)"
        }
        else {
            Add-CheckResult -Check 'SQL Server version' -Status 'WARN' -Detail "Version $($versionRow.FullVersion) is below the floor, plan a compatibility review"
        }

        # 3. Database size ------------------------------------------------
        $sizeRow = Invoke-Sqlcmd -ServerInstance $SqlInstance -Query "SELECT CAST(SUM(size) * 8.0 / 1024 / 1024 AS DECIMAL(10,1)) AS SizeGB FROM sys.master_files WHERE database_id = DB_ID('$DatabaseName')" -TrustServerCertificate
        if ($null -eq $sizeRow.SizeGB) {
            Add-CheckResult -Check 'Database size' -Status 'FAIL' -Detail "Database $DatabaseName not found on $SqlInstance"
        }
        else {
            Add-CheckResult -Check 'Database size' -Status 'PASS' -Detail "$DatabaseName is $($sizeRow.SizeGB) GB, confirm it matches the tenant YAML"
        }

        # 4. Backup freshness ----------------------------------------------
        $backupRow = Invoke-Sqlcmd -ServerInstance $SqlInstance -Query "SELECT MAX(backup_finish_date) AS LastFull FROM msdb.dbo.backupset WHERE database_name = '$DatabaseName' AND type = 'D'" -TrustServerCertificate
        if ($null -eq $backupRow.LastFull) {
            Add-CheckResult -Check 'Backup freshness' -Status 'FAIL' -Detail 'No full backup recorded in msdb'
        }
        else {
            $ageHours = [math]::Round(((Get-Date) - $backupRow.LastFull).TotalHours, 1)
            if ($ageHours -le $MaxBackupAgeHours) {
                Add-CheckResult -Check 'Backup freshness' -Status 'PASS' -Detail "Last full backup $ageHours hours ago"
            }
            else {
                Add-CheckResult -Check 'Backup freshness' -Status 'FAIL' -Detail "Last full backup $ageHours hours ago exceeds the $MaxBackupAgeHours hour budget"
            }
        }
    }
    catch {
        Add-CheckResult -Check 'SQL Server checks' -Status 'FAIL' -Detail $_.Exception.Message
    }
}

# 5. Disk headroom ---------------------------------------------------------
try {
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $ComputerName -Filter "DriveType = 3"
    foreach ($disk in $disks) {
        $freeGb = [math]::Round($disk.FreeSpace / 1GB, 1)
        $pct = if ($disk.Size -gt 0) { [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 0) } else { 0 }
        if ($pct -lt 10) {
            Add-CheckResult -Check "Disk headroom $($disk.DeviceID)" -Status 'FAIL' -Detail "$freeGb GB free ($pct percent)"
        }
        elseif ($pct -lt 20) {
            Add-CheckResult -Check "Disk headroom $($disk.DeviceID)" -Status 'WARN' -Detail "$freeGb GB free ($pct percent)"
        }
        else {
            Add-CheckResult -Check "Disk headroom $($disk.DeviceID)" -Status 'PASS' -Detail "$freeGb GB free ($pct percent)"
        }
    }
}
catch {
    Add-CheckResult -Check 'Disk headroom' -Status 'WARN' -Detail "CIM query failed: $($_.Exception.Message)"
}

# 6. Pending reboot ----------------------------------------------------------
try {
    $pendingKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    )
    $pending = $false
    foreach ($key in $pendingKeys) {
        if (Invoke-Command -ComputerName $ComputerName -ScriptBlock { param($k) Test-Path $k } -ArgumentList $key -ErrorAction SilentlyContinue) {
            $pending = $true
        }
    }
    if ($pending) {
        Add-CheckResult -Check 'Pending reboot' -Status 'WARN' -Detail 'Host has a pending reboot, clear it before the cutover window'
    }
    else {
        Add-CheckResult -Check 'Pending reboot' -Status 'PASS' -Detail 'No pending reboot flags found'
    }
}
catch {
    Add-CheckResult -Check 'Pending reboot' -Status 'WARN' -Detail "Remote check failed: $($_.Exception.Message)"
}

# Report ---------------------------------------------------------------------
$results | Format-Table -AutoSize

$failCount = @($results | Where-Object Status -eq 'FAIL').Count
$warnCount = @($results | Where-Object Status -eq 'WARN').Count

Write-Host ""
if ($failCount -gt 0) {
    Write-Host "NO-GO: $failCount failing check(s), $warnCount warning(s)." -ForegroundColor Red
    exit 2
}
elseif ($warnCount -gt 0) {
    Write-Host "GO WITH CAUTION: $warnCount warning(s) to review." -ForegroundColor Yellow
    exit 1
}
else {
    Write-Host "GO: all readiness checks passed." -ForegroundColor Green
    exit 0
}
