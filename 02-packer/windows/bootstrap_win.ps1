<powershell>
try {
    Write-Host "Starting WinRM HTTP setup..." -ForegroundColor Cyan

    # Set admin password and prevent expiration
    net user Administrator "${password}"
    wmic useraccount where "name='Administrator'" set PasswordExpires=FALSE

    # Set execution policy and error behavior
    Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore
    $ErrorActionPreference = "Stop"

    # WinRM config for HTTP
    winrm quickconfig -q
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/client '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'

    # Create a listener on HTTP
    Remove-Item -Path WSMan:\Localhost\Listener\listener* -Recurse -ErrorAction SilentlyContinue
    New-Item -Path WSMan:\LocalHost\Listener -Transport HTTP -Address * -Port 5985 -Force

    # Open firewall port for HTTP
    New-NetFirewallRule -DisplayName "Allow WinRM HTTP" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow

    # Start WinRM
    Stop-Service winrm
    Set-Service winrm -StartupType Automatic
    Start-Service winrm

    Write-Host "WinRM HTTP setup complete." -ForegroundColor Green
}
catch {
    Write-Error "WinRM HTTP setup failed: $_"
    exit 1
}
</powershell>
