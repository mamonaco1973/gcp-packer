Write-Host "NOTE: Validating that required commands are found in the PATH." -ForegroundColor Green

# List of required commands
$commands = @("gcloud", "packer", "terraform")

# Flag to track if all commands are found
$allFound = $true

# Iterate through each command and check if it's available
foreach ($cmd in $commands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: $cmd is not found in the current PATH." -ForegroundColor Red
        $allFound = $false
    } else {
        Write-Host "NOTE: $cmd is found in the current PATH." -ForegroundColor Green
    }
}

# Final status
if ($allFound) {
    Write-Host "NOTE: All required commands are available." -ForegroundColor Green
} else {
    Write-Host "ERROR: One or more commands are missing." -ForegroundColor Red
    exit 1
}

Write-Host "NOTE: Validating credentials.json and testing the gcloud command" -ForegroundColor Green

# Check if the file "./credentials.json" exists
if (-not (Test-Path "./credentials.json")) {
    Write-Host "ERROR: The file './credentials.json' does not exist." -ForegroundColor Red
    exit 1
}

# Run the gcloud authentication command
gcloud auth activate-service-account --key-file="./credentials.json"
