#
# BillU-Logger.psm1 -- Module de journalisation centralise -- Sprint 6
# Chemin : C:\Scripts\BillU\BillU-Logger.psm1
#
# Import dans chaque script :
#   Import-Module "C:\Scripts\BillU\BillU-Logger.psm1" -Force
#   $scriptName = "05-Create-Shares"
#
# Usage :
#   Write-BillULog -Script $scriptName -Level INFO    -Msg "Partage Homes cree"
#   Write-BillULog -Script $scriptName -Level WARNING -Msg "Groupe absent"
#   Write-BillULog -Script $scriptName -Level ERROR   -Msg "Acces refuse : $_"
#

# Configuration -- adapter si besoin
$script:LogDir       = "C:\Windows\Logs\BillU"   # Repertoire des logs CMTrace
$script:EventLogName = "BillU"                     # Nom du journal Windows
$script:EventSource  = "BillU-Scripts"             # Source dans l Observateur
$script:SyslogHost   = "[IP-DEBIAN]"              # IP de la VM Debian Syslog-ng
$script:SyslogPort   = 514                         # Port Syslog UDP

# Creer le repertoire de logs si absent
New-Item $script:LogDir -ItemType Directory -Force -EA SilentlyContinue | Out-Null

# Creer la source EventLog si absente (necessite admin)
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists($script:EventSource)) {
        New-EventLog -LogName $script:EventLogName `
                     -Source  $script:EventSource -EA Stop
    }
} catch {}

function Write-BillULog {
    param(
        [Parameter(Mandatory)] [string] $Script,
        [Parameter(Mandatory)] [ValidateSet("INFO","WARNING","ERROR")] [string] $Level,
        [Parameter(Mandatory)] [string] $Msg
    )

    $now     = Get-Date
    $logFile = "$script:LogDir\$Script.log"

    # ---- 1. Fichier CMTrace (1 fichier par script) ----
    $typeNum = switch ($Level) { "INFO" {1} "WARNING" {2} "ERROR" {3} }
    $time    = $now.ToString("HH:mm:ss.fff") + "+000"
    $date    = $now.ToString("MM-dd-yyyy")
    $cmLine  = "<![LOG[$Msg]LOG]!><time=`"$time`" date=`"$date`" component=`"$Script`" context=`"`" type=`"$typeNum`" thread=`"$PID`" file=`"$Script.ps1`">"
    Add-Content -Path $logFile -Value $cmLine -Encoding UTF8 -EA SilentlyContinue

    # ---- 2. Observateur d evenements Windows ----
    $entryType = switch ($Level) {
        "INFO"    { "Information" }
        "WARNING" { "Warning"     }
        "ERROR"   { "Error"       }
    }
    $eventId = switch ($Level) {
        "INFO"    { 1000 }
        "WARNING" { 2000 }
        "ERROR"   { 3000 }
    }
    try {
        Write-EventLog -LogName $script:EventLogName `
                       -Source  $script:EventSource `
                       -EventId $eventId `
                       -EntryType $entryType `
                       -Message "[$Script] $Msg" -EA SilentlyContinue
    } catch {}

    # ---- 3. Console avec couleurs ----
    $color = switch ($Level) {
        "INFO"    { "Cyan"   }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red"    }
    }
    Write-Host "  [$Level] $Msg" -ForegroundColor $color

    # ---- 4. Syslog-ng via UDP (envoi vers la VM Debian) ----
    # Format Syslog BSD RFC 3164 : <priority>timestamp host program: message
    try {
        $facility = 16   # local0 = facility 16
        $severity = switch ($Level) {
            "INFO"    { 6 }  # informational
            "WARNING" { 4 }  # warning
            "ERROR"   { 3 }  # error
        }
        $priority  = ($facility * 8) + $severity
        $syslogTs  = $now.ToString("MMM dd HH:mm:ss")
        $syslogMsg = "<$priority>$syslogTs $env:COMPUTERNAME BillU-Script: [$Script][$Level] $Msg"

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($syslogMsg)
        $udp   = New-Object System.Net.Sockets.UdpClient
        $udp.Send($bytes, $bytes.Length, $script:SyslogHost, $script:SyslogPort) | Out-Null
        $udp.Close()
    } catch {}
}

Export-ModuleMember -Function Write-BillULog
