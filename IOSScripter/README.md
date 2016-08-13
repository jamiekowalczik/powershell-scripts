. .\Get-IOSData.ps1
$servers="1.1.1.1","1.1.1.2"
$servers | % { $switches | % { $SSHHostname = $_; Show-Environment; Show-RunningConfig; }
