try {
    Write-Host "Starting WinRM HTTP setup..." -ForegroundColor Cyan

    # Set Administrator password and prevent expiration
    net user Administrator "${password}" | Out-Null
    wmic useraccount where "name='Administrator'" set PasswordExpires=FALSE | Out-Null

    # Set execution policy and strict error handling
    Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore
    $ErrorActionPreference = "Stop"

    # Configure WinRM service
    winrm quickconfig -q
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/client '@{AllowUnencrypted="true"}'

    # Remove any old listeners and create a new one on HTTP/5985
    Remove-Item -Path WSMan:\Localhost\Listener\* -Recurse -ErrorAction SilentlyContinue
    New-Item -Path WSMan:\LocalHost\Listener -Transport HTTP -Address * -Port 5985 -Force

    # Open firewall for WinRM on all profiles
    New-NetFirewallRule -DisplayName "Allow WinRM HTTP" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 5985 `
        -Action Allow `
        -Profile Any

    # Ensure WinRM service is running
    Stop-Service winrm
    Set-Service winrm -StartupType Automatic
    Start-Service winrm

    # Final: Apply aggressive trust and binding to avoid GCP overrides
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
    winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Hostname="*";Port="5985"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/client '@{AllowUnencrypted="true"}'

    # Log listener binding for confirmation
    Write-Host "Netstat output for port 5985:"
    netstat -an | findstr :5985

    Write-Host "WinRM HTTP setup complete." -ForegroundColor Green
}
catch {
    Write-Error "WinRM HTTP setup failed: $($_.Exception.Message)"
    exit 1
}
