1#!/bin/bash

echo "=== Running JMeter Continuously ==="
echo "Each cycle runs 10 requests"
echo "Press Ctrl+C to stop"

# Clean previous results
# rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_2_logs.csv
# rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_2_results.csv

# Clean Docker containers
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

COUNTER=1
while true; do
    echo ""
    echo "=== Cycle $COUNTER - Started at $(date) ==="
    
    # Run JMeter with 10 requests per cycle
    /home/ubuntu/project/jmeter/bin/jmeter.sh -n -t /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_jsr223_exp_1.jmx -l /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_1_logs.csv
    
    # Check results
    if [ -f "/home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_1_logs.csv" ]; then
        REQUESTS=$(wc -l < /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_1_logs.csv)
        RESULTS=$(wc -l < /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_1_results.csv 1>/dev/null || echo 0)
        echo "✅ Cycle $COUNTER: $((REQUESTS-1)) JMeter requests, $((RESULTS-1)) cold/warm results"
    else
        echo "❌ Cycle $COUNTER: No JMeter results"
    fi
    
    echo "Waiting 2 seconds before next cycle..."
    sleep 2
    COUNTER=$((COUNTER + 1))
done
