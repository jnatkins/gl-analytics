#!/bin/sh

## TODO: rewrite this hot mess to use airflow conditionals/scheduling
# Get's current UTC time
H=$(date -u +%H)
STARTTIME=7
ENDTIME=10

# Checks if between 7 and 10 AM UTC (1-4 AM CST)
# 10#$H returns the hour in base 10
if (( STARTTIME <= 10#$H && 10#$H < ENDTIME )); then
    echo python3 transform/domain_processor.py
    python3 transform/domain_processor.py
else
    echo Domain Processor not run: Only run between the hours of $STARTTIME AM UTC and $ENDTIME AM UTC
fi
