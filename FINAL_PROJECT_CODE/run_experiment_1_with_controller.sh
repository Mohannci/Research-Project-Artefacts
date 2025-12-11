

#!/bin/bash

echo "=== EXPERIMENT 1: BiLSTM ==="
echo "Using ML predictions from: bilstm_exp.csv"
echo ""

# Clean previous results
rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_1_logs.csv
rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_1_results.csv

# Clean ALL Docker containers (FIXED: removed line breaks)
echo "Cleaning up Docker containers..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo "1. Starting ML Controller for BiLSTM..."
sudo timeout 300s python3 /home/ubuntu/project/openwhisk/controller.py 1 experiment_serverless_1 &
CONTROLLER_PID=$!

echo "Controller PID: $CONTROLLER_PID"
echo "Waiting 10 seconds for controller to start pre-warming containers..."
sleep 10

echo "2. Starting JMeter load test..."
/home/ubuntu/project/jmeter/bin/jmeter.sh -n -t /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_1_with_controller.jmx -l /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_1_logs.csv

echo "3. Waiting for controller to finish..."
wait $CONTROLLER_PID 2>/dev/null

# Cleanup (FIXED: removed line breaks)
echo "Final Docker cleanup..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo ""
echo "=== EXPERIMENT 1 COMPLETE ==="

# Show results (FIXED: uncommented and added error handling)
if [ -f "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_1_results.csv" ]; then
    TOTAL=$(wc -l < "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_1_results.csv")
    COLD=$(grep -c ",cold" "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_1_results.csv")
    WARM=$(grep -c ",warm" "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_1_results.csv")
    
    if [ $((COLD + WARM)) -gt 0 ]; then
        WARM_PERCENT=$((WARM * 100 / (COLD + WARM)))
        #echo "Results: $((TOTAL-1)) total, $COLD cold, $WARM warm ($WARM_PERCENT% warm)"
    else
        echo "Results: $((TOTAL-1)) total (no cold/warm data)"
    fi
else
    echo "No results file found"
fi