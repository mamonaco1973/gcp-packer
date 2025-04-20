#!/bin/bash

# Check if the file "./credentials.json" exists
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

# Extract the project_id using jq
project_id=$(jq -r '.project_id' "./credentials.json")
gcloud auth activate-service-account --key-file="./credentials.json" > /dev/null 2> /dev/null

FLASK_LB_IP=$(gcloud compute addresses describe flask-lb-ip --global --format="value(address)")

if [ -z "$FLASK_LB_IP" ]; then
    echo "ERROR: Failed to retrieve the load balancer IP address. Exiting."
    exit 1
fi

#!/bin/bash

URL="http://$FLASK_LB_IP/candidates"

while true; do
  HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" "$URL")
  
  if [ "$HTTP_CODE" -eq 200 ]; then
     echo "NOTE: Health check endpoint is http://$FLASK_LB_IP/gtg?details=true"
     ./02-packer/scripts/test_candidates.py $FLASK_LB_IP
     exit 0
    break
  else
    echo "WARNING: Waiting for the load balancer to become active."
    sleep 60  
  fi
done
