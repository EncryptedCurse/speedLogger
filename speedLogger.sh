#!/bin/bash
# Log file name and path.
LOG="speedLogger.log"

PREFIX="\e[1;30m[ speedLogger ]\e[0m"
ERRORPREFIX="\e[1;31m[ speedLogger ]\e[0m"

# Safety check: ensure that speedtest-cli is installed first.
if [ ! -x "$(command -v speedtest-cli)" -o -f speedtest-cli ]; then
    echo -e "$ERRORPREFIX speedtest-cli is not installed (https://github.com/sivel/speedtest-cli)"
    exit 1
fi

# Check if log file exists; if not, create a new one.
if [ ! -f "$LOG" ]; then
    echo -e "$PREFIX log file doesn't exist, creating a new one at $LOG"
    touch $LOG
    echo "date            time          download           upload"         > $LOG
    echo "--------------------------------------------------------------" >> $LOG
fi
# Safety check: ensure that the log file was initialized properly and/or is accessible.
if ! grep -q "date" $LOG; then
    echo -e "$ERRORPREFIX bad log file"
    exit 1
fi

# Date and time formatting.
DATE=$(date +"%m-%d-%Y")
TIME=$(date +"%I:%M %P")

# Run test and extract download/upload speeds.
echo -e "$PREFIX running test..."
# Create a temporary file to redirect speedtest-cli output.
TEMP=$(mktemp)
trap 'killall speedtest-cli 2> /dev/null; exit' SIGINT
speedtest-cli > $TEMP &
# Print the server being used as soon as it appears in the temporary file.
SERVER=$(grep -oP -m 1 "Hosted by \K.*" <(tail -f $TEMP 2> /dev/null))
echo -e "$PREFIX connected to $SERVER"
wait
DOWNLOAD=$(grep "Download:" $TEMP | awk '{ print $2, $3 }')
UPLOAD=$(grep "Upload:" $TEMP | awk '{ print $2, $3 }')

# Safety check: ensure that the test completed successfully before printing.
if grep -q "Download:" $TEMP; then
    rm $TEMP
else
    echo -e "$ERRORPREFIX speedtest failed"
    exit 1
fi
echo -e "$PREFIX download: $DOWNLOAD, upload: $UPLOAD"
# Append results to log file.
echo -e "$PREFIX printing to file..."
printf "%-15s %-13s %-18s %-18s\n" "$DATE" "$TIME" "$DOWNLOAD" "$UPLOAD" >> $LOG
