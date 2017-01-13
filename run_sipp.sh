#!/bin/bash
if [ -z "$ARGS" ]; then
    echo "ERROR: \"ARGS\" env var not set!"
    exit 1
fi

# wait for networking to setup
sleep 7

#To-Do: Enable background process with statistics
#sipp -bg -trace_stat -fd 1s -trace_rtt -rtt_freq 200 -trace_logs -trace_err $ARGS
#New SIPp with command-line variable
sipp -bg $ARGS
#tail -f /dev/null
