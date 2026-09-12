#!/usr/bin/env bash
# -------------------------------------------------------------------------
# @title       Task3_pipes_redirection.sh
# @author      Emmanuel Gregory Opoku Owusu-Afriyie
# @index       4195524
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Demonstrates pipes, redirection, and text processing on logs
# @date        $(date +%Y-%m-%d)
# -------------------------------------------------------------------------

# 1. USAGE GUIDE (This script takes no arguments)
if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$#" -gt 0 ]; then
    echo "Usage: $0"
    echo "  This script requires no arguments."
    echo "  It generates a sample log file, processes it, and outputs a summary."
    exit 1
fi

LOG_FILE="sample_logs.txt"
RESULTS_FILE="results.txt"
ERROR_FILE="errors.log"

# Clear previous error log if it exists
> "$ERROR_FILE"

echo "Generating 50 lines of sample log data..."
# 2. CREATE SAMPLE DATA WITH HEREDOC
# We redirect any potential errors from this step to errors.log
cat << 'EOF' > "$LOG_FILE" 2>> "$ERROR_FILE"
2026-09-11 10:00:01 INFO 192.168.1.10 System startup
2026-09-11 10:01:45 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:02:02 WARN 192.168.1.10 Disk usage above 80%
2026-09-11 10:03:21 INFO 192.168.1.10 User login successful
2026-09-11 10:04:15 INFO 10.0.0.5 File upload initiated
2026-09-11 10:05:00 WARN 192.168.1.50 High memory usage
2026-09-11 10:06:12 INFO 192.168.1.10 Database sync complete
2026-09-11 10:07:33 ERROR 10.0.0.5 Authentication failed
2026-09-11 10:08:14 INFO 192.168.1.23 Session closed
2026-09-11 10:09:55 WARN 192.168.1.10 CPU temperature high
2026-09-11 10:10:01 INFO 192.168.1.50 Background task started
2026-09-11 10:11:22 INFO 10.0.0.5 User profile updated
2026-09-11 10:12:45 ERROR 192.168.1.23 Database connection lost
2026-09-11 10:13:05 INFO 192.168.1.10 Reconnecting to database
2026-09-11 10:14:11 INFO 192.168.1.10 Database reconnected
2026-09-11 10:15:30 WARN 10.0.0.5 Slow query detected
2026-09-11 10:16:44 INFO 192.168.1.50 Cache cleared
2026-09-11 10:17:10 ERROR 192.168.1.10 Segfault in worker thread
2026-09-11 10:18:20 INFO 192.168.1.23 Worker thread restarted
2026-09-11 10:19:05 INFO 10.0.0.5 API request received
2026-09-11 10:20:15 INFO 192.168.1.10 API response 200 OK
2026-09-11 10:21:33 WARN 192.168.1.23 Network latency spike
2026-09-11 10:22:41 INFO 192.168.1.50 User login successful
2026-09-11 10:23:10 INFO 10.0.0.5 Downloading report
2026-09-11 10:24:55 ERROR 192.168.1.50 File not found
2026-09-11 10:25:22 INFO 192.168.1.10 Retry download
2026-09-11 10:26:40 INFO 192.168.1.10 Download complete
2026-09-11 10:27:15 WARN 10.0.0.5 Disk space running low
2026-09-11 10:28:05 INFO 192.168.1.23 Cleaning up temp files
2026-09-11 10:29:11 INFO 192.168.1.23 Cleanup finished
2026-09-11 10:30:45 ERROR 192.168.1.10 Kernel panic
2026-09-11 10:31:02 INFO 10.0.0.5 System rebooting
2026-09-11 10:32:15 INFO 192.168.1.10 System startup
2026-09-11 10:33:40 INFO 192.168.1.50 Service initialized
2026-09-11 10:34:55 WARN 192.168.1.23 Configuration missing
2026-09-11 10:35:10 INFO 192.168.1.23 Loading default config
2026-09-11 10:36:22 INFO 10.0.0.5 Processing queue
2026-09-11 10:37:41 ERROR 192.168.1.50 Queue timeout
2026-09-11 10:38:05 INFO 192.168.1.10 Restarting queue
2026-09-11 10:39:15 INFO 192.168.1.10 Queue healthy
2026-09-11 10:40:33 WARN 10.0.0.5 Unauthorized access attempt
2026-09-11 10:41:50 INFO 192.168.1.23 IP blocked
2026-09-11 10:42:11 INFO 192.168.1.50 Sending alert email
2026-09-11 10:43:25 INFO 192.168.1.50 Email sent successfully
2026-09-11 10:44:40 ERROR 10.0.0.5 Payment gateway offline
2026-09-11 10:45:05 INFO 192.168.1.10 Switching to fallback gateway
2026-09-11 10:46:15 INFO 192.168.1.10 Payment processed
2026-09-11 10:47:30 WARN 192.168.1.23 SSL certificate expiring soon
2026-09-11 10:48:45 INFO 10.0.0.5 Certificate renewal triggered
2026-09-11 10:49:59 INFO 192.168.1.50 Certificate updated
EOF

if [ $? -ne 0 ]; then
    echo "Error: Failed to generate log file." >&2
    exit 1
fi
echo "Success: Created $LOG_FILE."

echo "Processing logs and saving report to '$RESULTS_FILE'..."
# 3. PROCESS LOGS WITH PIPES
# We group all output in { } so we can easily redirect success to results.txt and failures to errors.log
{
    echo "=== LOG ANALYSIS REPORT ==="
    echo ""

    # Query 1: Total number of log lines
    echo "1. Total Number of Log Lines:"
    wc -l < "$LOG_FILE"
    echo ""

    # Query 2: Count of lines per log level (Extract column 4, sort, count)
    echo "2. Lines per Log Level:"
    awk '{print $4}' "$LOG_FILE" | sort | uniq -c | sort -nr
    echo ""

    # Query 3: Top 3 most frequent IP addresses (Extract column 5, sort, count, grab top 3)
    echo "3. Top 3 Most Frequent IP Addresses:"
    awk '{print $5}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 3
    echo ""

    # Query 4: All ERROR lines only
    echo "4. All ERROR Lines:"
    grep "ERROR" "$LOG_FILE"
    
} > "$RESULTS_FILE" 2>> "$ERROR_FILE"

# Check if the grouped pipeline block executed successfully
if [ $? -ne 0 ]; then
    echo "Error: Pipeline processing failed. Check '$ERROR_FILE' for details." >&2
    exit 1
fi

echo "Success: Data processed."
echo "Summary has been saved to '$RESULTS_FILE'."
echo "Any hidden errors were sent to '$ERROR_FILE'."

exit 0
