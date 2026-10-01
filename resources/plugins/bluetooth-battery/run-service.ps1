# Watchdog for the LiteMonitor Bluetooth battery HTTP service.
# English-only comments (avoid UTF-8 BOM-less corruption).
# Idempotent: only starts the server when the port is FREE, so running
# multiple copies (e.g. this + the Startup shortcut) is harmless.

$dir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$svc  = Join-Path $dir 'BluetoothBattery.ps1'
$ps   = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$port = 18923

# Singleton guard: only ONE watchdog per session. Both the old Startup .lnk
# (desktop copy) and any new launcher may fire at logon; this prevents two
# resident loops from running at once.
$mtx = New-Object System.Threading.Mutex($false, 'LiteMonitorBtBatteryWatchdog')
if (-not $mtx.WaitOne(0)) {
    Write-Host 'Watchdog already running; exiting.'
    exit 0
}

function Test-Port($p) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $c.Connect('127.0.0.1', $p)
        $c.Close()
        return $true
    } catch {
        return $false
    }
}

while ($true) {
    try {
        if (-not (Test-Port $port)) {
            try {
                Start-Process -FilePath $ps -WindowStyle Hidden -ArgumentList "-NoProfile -MTA -ExecutionPolicy Bypass -File `"$svc`" -Serve -Port $port"
            } catch { }
        }
    } catch { }
    Start-Sleep -Seconds 15
}
