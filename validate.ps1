# Check if the file "./credentials.json" exists
if (-Not (Test-Path "./credentials.json")) {
    Write-Error "The file './credentials.json' does not exist."
    exit 1
}

# Extract the project_id using jq
$project_id = Get-Content "./credentials.json" | ConvertFrom-Json | Select-Object -ExpandProperty project_id
& gcloud auth activate-service-account --key-file="./credentials.json" | Out-Null

# Get the load balancer IP address
$FLASK_LB_IP = & gcloud compute addresses describe flask-lb-ip --global --format="value(address)"

if (-Not $FLASK_LB_IP) {
     Write-Error "Failed to retrieve the load balancer IP address. Exiting."
     exit 1
}

# Define the URL for the health check endpoint
$URL = "http://$FLASK_LB_IP/candidates"

# Start the health check loop
while ($true) {
    try {
        # Suppress errors and return $null for failed requests
        $Response = Invoke-WebRequest -Uri $URL -UseBasicParsing -Method Get -ErrorAction SilentlyContinue
        if ($Response -and $Response.StatusCode -eq 200) {
            Write-Output "NOTE: Health check endpoint is http://$FLASK_LB_IP/gtg?details=true"
            .\build\test_candidates.ps1 $FLASK_LB_IP
            exit 0
        } else {
            Write-Warning "Waiting for the load balancer to become active."
        }
    } catch {
        # Suppress any exceptions
         Write-Warning "Waiting for the load balancer to become active."
    }
    Start-Sleep -Seconds 60
}
