#!/bin/bash

# Settings
WEBHOOK_URL="WEBHOOK HERE" # Insert the webhook link here
LOGFILE_NAME="path/to/server.log.txt" # Log File Path
MAX_PLAYERS=128 # Max Players Number
LAST_LINES=5 # Number of lines sent to webhook at first run

# Webhook verify
if [ -z "$WEBHOOK_URL" ]; then
    echo "Error: The WEBHOOK_URL is not configured."
    exit 1
fi

# Check if the log file exists
if [ ! -f "$LOGFILE_NAME" ]; then
    echo "Error: Log file '$LOGFILE_NAME' not found."
    exit 1
fi

echo "Processing the log file '$LOGFILE_NAME'..."

# Check connected players
declare -A CONNECTED_PLAYERS  # Associative array to store connected players
CURRENT_PLAYERS=0             # Count of connected players
RECENT_MESSAGES=()            # Array to store the messages of the last processed lines
PROCESSED_LINES=()            # Array to track already processed lines

# Function to send messages to Discord
send_to_discord() {
    local MESSAGE="$1"
    curl -s -H "Content-Type: application/json" \
         -d "{\"content\": \"$MESSAGE\"}" \
         "$WEBHOOK_URL" > /dev/null
}

# Function to process a line
process_line() {
    local LINE="$1"

    # Ignores lines that contain "[Chat]" or "[MP] State: running"
    if echo "$LINE" | grep -qE "\[Chat\]|\[MP\] State: running"; then
        return
    fi

    # Prevents processing the same line more than once
    if [[ " ${PROCESSED_LINES[*]} " =~ " $LINE " ]]; then
        return
    fi
    PROCESSED_LINES+=("$LINE")

    # Extracts the player's name
    PLAYER_NAME=$(echo "$LINE" | sed -n 's/.*\[MP\] \(.*\) \(connected\|disconnected\).*/\1/p')

    # Ignores the player "Steam"
    if [ "$PLAYER_NAME" = "Steam" ]; then
        return
    fi

    # Checks if the line contains "connected"
    if echo "$LINE" | grep -q "\[MP\] .* connected"; then
        if [ -z "${CONNECTED_PLAYERS[$PLAYER_NAME]}" ]; then
            CONNECTED_PLAYERS["$PLAYER_NAME"]=1
            CURRENT_PLAYERS=$((CURRENT_PLAYERS + 1))
            STATUS="🚚 $PLAYER_NAME connected ($CURRENT_PLAYERS/$MAX_PLAYERS)"
            RECENT_MESSAGES+=("$STATUS")
        fi

    # Checks if the line contains "disconnected"
    elif echo "$LINE" | grep -q "\[MP\] .* disconnected"; then
        if [ -n "${CONNECTED_PLAYERS[$PLAYER_NAME]}" ]; then
            unset CONNECTED_PLAYERS["$PLAYER_NAME"]
            CURRENT_PLAYERS=$((CURRENT_PLAYERS - 1))
            if [ "$CURRENT_PLAYERS" -lt 0 ]; then
                CURRENT_PLAYERS=0
            fi
            STATUS="🟠 $PLAYER_NAME disconnected ($CURRENT_PLAYERS/$MAX_PLAYERS)"
            RECENT_MESSAGES+=("$STATUS")
        fi
    fi
}

# Processes the entire log to calculate the initial state
echo "Processing the entire log to calculate the initial state..."
while IFS= read -r LINE; do
    process_line "$LINE"
done < "$LOGFILE_NAME"

# Sends only the last N messages to Discord
echo "Sending the last $LAST_LINES messages to Discord..."
for ((i = ${#RECENT_MESSAGES[@]} - LAST_LINES; i < ${#RECENT_MESSAGES[@]}; i++)); do
    if [ $i -ge 0 ]; then
        send_to_discord "${RECENT_MESSAGES[$i]}"
    fi
done

# Real-time monitoring
echo "Monitoring the log file in real-time..."
tail -f "$LOGFILE_NAME" | while read -r LINE; do
    process_line "$LINE"

    # Sends only the newly processed messages to Discord
    if [ ${#RECENT_MESSAGES[@]} -gt 0 ]; then
        send_to_discord "${RECENT_MESSAGES[-1]}"
        RECENT_MESSAGES=()
    fi
done
