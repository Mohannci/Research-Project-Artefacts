# #!/bin/bash

# echo "=== EXPERIMENT 3: LSTM ==="
# echo "Using ML predictions from: lstm_exp.csv"
# echo ""

# # Clean previous results
# rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_3_logs.csv
# rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_3_results.csv

# # Clean Docker containers
# docker stop 0e73a649d00d
# 37970084daf8
# 4bd314064a23
# 261fde30a6bf
# 551035c52265 2>/dev/null || true
# docker rm 0e73a649d00d
# 37970084daf8
# 4bd314064a23
# 261fde30a6bf
# 551035c52265 2>/dev/null || true

# echo "1. Starting ML Controller for LSTM..."
# sudo timeout 300s python3 /home/ubuntu/project/openwhisk/controller.py 3 experiment_serverless_3 &
# CONTROLLER_PID=$!

# echo "Controller PID: $CONTROLLER_PID"
# echo "Waiting 10 seconds for controller to start pre-warming containers..."
# sleep 10

# echo "2. Starting JMeter load test..."
# /home/ubuntu/project/jmeter/bin/jmeter.sh -n -t /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_3_with_controller.jmx -l /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_3_logs.csv

# echo "3. Waiting for controller to finish..."
# wait $CONTROLLER_PID 2>/dev/null

# # Cleanup
# docker stop 0e73a649d00d
# 37970084daf8
# 4bd314064a23
# 261fde30a6bf
# 551035c52265 2>/dev/null || true
# docker rm 0e73a649d00d
# 37970084daf8
# 4bd314064a23
# 261fde30a6bf
# 551035c52265 2>/dev/null || true

# echo ""
# echo "=== EXPERIMENT 3 COMPLETE ==="

# # Show results
# if [ -f "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_3_results.csv" ]; then
#     TOTAL=$(wc -l < "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_3_results.csv")
#     COLD=$(grep -c ",cold" "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_3_results.csv")
#     WARM=$(grep -c ",warm" "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_3_results.csv")
#   # echo "Results: $((TOTAL-1)) total, $COLD cold, $WARM warm ($((WARM * 100 / (COLD + WARM)))% warm)"
# else
#     echo "No results file found"
# fi



#!/bin/bash

echo "=== EXPERIMENT 2: LSTM ==="
echo "Using ML predictions from: lstm_exp.csv"
echo ""

# Clean previous results
rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_2_logs.csv
rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_2_results.csv

# Clean ALL Docker containers (FIXED: removed line breaks)
echo "Cleaning up Docker containers..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo "1. Starting ML Controller for LSTM..."
sudo timeout 300s python3 /home/ubuntu/project/openwhisk/controller.py 2 experiment_serverless_2 &
CONTROLLER_PID=$!

echo "Controller PID: $CONTROLLER_PID"
echo "Waiting 10 seconds for controller to start pre-warming containers..."
sleep 10

echo "2. Starting JMeter load test..."
/home/ubuntu/project/jmeter/bin/jmeter.sh -n -t /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_2_with_controller.jmx -l /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_2_logs.csv

echo "3. Waiting for controller to finish..."
wait $CONTROLLER_PID 2>/dev/null

# Cleanup (FIXED: removed line breaks)
echo "Final Docker cleanup..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo ""
echo "=== EXPERIMENT 2 COMPLETE ==="

# Show results (FIXED: uncommented and added error handling)
if [ -f "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_2_results.csv" ]; then
    TOTAL=$(wc -l < "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_2_results.csv")
    COLD=$(grep -c ",cold" "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_2_results.csv")
    WARM=$(grep -c ",warm" "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_2_results.csv")
    
    if [ $((COLD + WARM)) -gt 0 ]; then
        WARM_PERCENT=$((WARM * 100 / (COLD + WARM)))
        #echo "Results: $((TOTAL-1)) total, $COLD cold, $WARM warm ($WARM_PERCENT% warm)"
    else
        echo "Results: $((TOTAL-1)) total (no cold/warm data)"
    fi
else
    echo "No results file found"
fi