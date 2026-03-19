#
# BillU-Logger.psm1 -- BillU Sprint 6
# Chemin : C:\Scripts\BillU\BillU-Logger.psm1
#
# Usage :
#   Import-Module "C:\Scripts\BillU\BillU-Logger.psm1" -Force
#   $sn = "05-Create-Shares"
#   Write-BillULog -Script $sn -Level INFO    -Msg "Partage Homes cree"
#   Write-BillULog -Script $sn -Level WARNING -Msg "Groupe absent"
#   Write-BillULog -Script $sn -Level ERROR   -Msg "Acces refuse : $_"
#   Get-BillULog   -Script $sn -Level ERROR -Last 20
#

# Configuration
$script:LogDir      = "C:\Windows\Logs\BillU"    # Repertoire logs CMTrace
$script:EventLog    = "BillU"                      # Journal Observateur evenements
$script:EventSource = "BillU-Scripts"              # Source dans l Observateur
$script:GraylogHost = "172.16.100.21"              # IP Ubuntu Graylog
$script:GraylogPort = 12201                         # Port GELF UDP

# Creer le dossier si absent
New-Item $script:LogDir -ItemType Directory -Force -EA SilentlyContinue | Out-Null

# Creer la source EventLog si absente
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists($script:EventSource)) {
        New-EventLog -LogName $script:EventLog -Source $script:EventSource -EA Stop
    }
} catch {}

function Write-BillULog {
    param(
        [Parameter(Mandatory)] [string] $Script,
        [Parameter(Mandatory)] [ValidateSet("INFO","WARNING","ERROR")] [string] $Level,
        [Parameter(Mandatory)] [string] $Msg,
        [int] $EventId = 0
    )

    $now = Get-Date

    if ($EventId -eq 0) {
        $EventId = switch ($Level) { "INFO" {1000} "WARNING" {2000} "ERROR" {3000} }
    }
    $entryType = switch ($Level) {
        "INFO"    {"Information"} "WARNING" {"Warning"} "ERROR" {"Error"}
    }
    $typeNum = switch ($Level) { "INFO" {1} "WARNING" {2} "ERROR" {3} }

    # ---- 1. Fichier CMTrace (1 fichier par script) ----
    $logFile = "$script:LogDir\$Script.log"
    $time    = $now.ToString("HH:mm:ss.fff") + "+000"
    $date    = $now.ToString("MM-dd-yyyy")
    $cmLine  = "<![LOG[$Msg]LOG]!><time=`"$time`" date=`"$date`" component=`"$Script`" context=`"`" type=`"$typeNum`" thread=`"$PID`" file=`"$Script.ps1`">"
    Add-Content -Path $logFile -Value $cmLine -Encoding UTF8 -EA SilentlyContinue

    # ---- 2. Observateur d evenements Windows ----
    try {
        Write-EventLog -LogName $script:EventLog -Source $script:EventSource `
            -EventId $EventId -EntryType $entryType `
            -Message "[$Script][$Level] $Msg" -EA SilentlyContinue
    } catch {}

    # ---- 3. Console avec couleurs ----
    $color = switch ($Level) {
        "INFO" {"Cyan"} "WARNING" {"Yellow"} "ERROR" {"Red"}
    }
    Write-Host "  [$Level] $Msg" -ForegroundColor $color

    # ---- 4. Graylog GELF UDP ----
    # Format JSON GELF envoye en UDP directement vers Graylog
    try {
        $gelf = [ordered]@{
            version           = "1.1"
            host              = $env:COMPUTERNAME
            short_message     = $Msg
            timestamp         = [math]::Floor(($now - [datetime]"1970-01-01").TotalSeconds)
            level             = switch ($Level) { "INFO" {6} "WARNING" {4} "ERROR" {3} }
            _script           = $Script
            _level_name       = $Level
            _application_name = "BillU-Script"
            _event_id         = $EventId
        } | ConvertTo-Json -Compress

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($gelf)
        $udp   = New-Object System.Net.Sockets.UdpClient
        $udp.Send($bytes, $bytes.Length, $script:GraylogHost, $script:GraylogPort) | Out-Null
        $udp.Close()
    } catch {}
}

function Get-BillULog {
    <#
    .SYNOPSIS Affiche les derniers logs BillU depuis l Observateur d evenements.
    .EXAMPLE Get-BillULog -Script "05-Create-Shares" -Level ERROR -Last 20
    #>
    param(
        [string] $Script = "",
        [int]    $Last   = 20,
        [string] $Level  = ""
    )
    try {
        $events = Get-EventLog -LogName $script:EventLog -Newest ($Last * 3) -EA Stop
        if ($Script) {
            $events = $events | Where-Object { $_.Message -match "\[$Script\]" }
        }
        if ($Level) {
            $et = switch ($Level) {
                "INFO" {"Information"} "WARNING" {"Warning"} "ERROR" {"Error"}
            }
            $events = $events | Where-Object { $_.EntryType -eq $et }
        }
        $events | Select-Object -First $Last |
            Format-Table TimeGenerated, EntryType, EventID, Message -AutoSize -Wrap
    } catch {
        Write-Host "[ERR] Journal BillU inaccessible -- executer New-EventLog en admin" -ForegroundColor Red
    }
}

Export-ModuleMember -Function Write-BillULog, Get-BillULog
