#!/bin/bash

EXPERIMENT_NUM=1
DURATION=300  # 5 minutes

echo "=== Running Experiment $EXPERIMENT_NUM with ML Controller ==="
echo "Duration: $DURATION seconds"
echo "Using ML predictions from: $(if [ $EXPERIMENT_NUM -eq 1 ]; then echo 'bilstm_att_exp.csv'; elif [ $EXPERIMENT_NUM -eq 2 ]; then echo 'bilstm_exp.csv'; elif [ $EXPERIMENT_NUM -eq 3 ]; then echo 'lstm_exp.csv'; else echo 'multiheaded_bilstm_exp.csv'; fi)"

# Clean previous results
rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_${EXPERIMENT_NUM}_logs.csv
rm -f /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_${EXPERIMENT_NUM}_results.csv

# Clean Docker containers
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo "1. Starting ML Controller (uses predictions to pre-warm containers)..."
sudo timeout ${DURATION}s python3 /home/ubuntu/project/openwhisk/controller.py $EXPERIMENT_NUM experiment_serverless_${EXPERIMENT_NUM} &
CONTROLLER_PID=$!

echo "Controller PID: $CONTROLLER_PID"
echo "Waiting 10 seconds for controller to start pre-warming containers..."
sleep 10

echo "2. Starting JMeter load test..."
COUNTER=1
while [ $COUNTER -le 30 ]; do  # Run for 30 cycles or until controller stops
    # Check if controller is still running
    if ! ps -p $CONTROLLER_PID > /dev/null; then
        echo "Controller finished early, stopping test"
        break
    fi
    
    echo ""
    echo "=== JMeter Cycle $COUNTER ==="
    
    # Run JMeter with 10 requests per cycle
    /home/ubuntu/project/jmeter/bin/jmeter.sh -n -t /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_jsr223_exp_1.jmx -l /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_${EXPERIMENT_NUM}_logs.csv
    
    # Check results
    if [ -f "/home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_${EXPERIMENT_NUM}_logs.csv" ]; then
        REQUESTS=$(wc -l < /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_${EXPERIMENT_NUM}_logs.csv)
        RESULTS=$(wc -l < /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_${EXPERIMENT_NUM}_results.csv 2>/dev/null || echo 0)
        COLD_COUNT=$(grep -c ",cold" /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_${EXPERIMENT_NUM}_results.csv 2>/dev/null || echo 0)
        WARM_COUNT=$(grep -c ",warm" /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_${EXPERIMENT_NUM}_results.csv 2>/dev/null || echo 0)
        
        echo "✅ Cycle $COUNTER: $((REQUESTS-1)) requests, $((RESULTS-1)) results (Cold: $COLD_COUNT, Warm: $WARM_COUNT)"
    else
        echo "❌ Cycle $COUNTER: No JMeter results"
    fi
    
    echo "Waiting 5 seconds before next cycle..."
    sleep 5
    COUNTER=$((COUNTER + 1))
done

# Cleanup
echo "Stopping controller..."
sudo kill $CONTROLLER_PID 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo ""
echo "=== EXPERIMENT COMPLETE ==="
echo "Final results saved to:"
echo "- JMeter logs: /home/ubuntu/project/openwhisk/outputprediction/experiments/logs/experiment_${EXPERIMENT_NUM}_logs.csv"
echo "- Cold/Warm results: /home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_${EXPERIMENT_NUM}_results.csv"

# Show summary
if [ -f "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_${EXPERIMENT_NUM}_results.csv" ]; then
    TOTAL=$(wc -l < "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_${EXPERIMENT_NUM}_results.csv")
    COLD=$(grep -c ",cold" "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_${EXPERIMENT_NUM}_results.csv")
    WARM=$(grep -c ",warm" "/home/ubuntu/project/openwhisk/outputprediction/experiments/experiment_${EXPERIMENT_NUM}_results.csv")
    echo ""
    echo "=== RESULTS SUMMARY ==="
    echo "Total executions: $((TOTAL-1))"
    echo "Cold starts: $COLD"
    echo "Warm starts: $WARM"
    echo "Warm start ratio: $((WARM * 100 / (COLD + WARM)))%"
fi
