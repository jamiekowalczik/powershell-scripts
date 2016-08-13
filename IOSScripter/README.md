. .\Get-IOSData.ps1
$switches="1.1.1.1","1.1.1.2"
$switches | % { $SSHHostname = $_; Show-Environment; Show-RunningConfig; }
