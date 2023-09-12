#!/bin/bash

# path to talisman report is in $1

# Read in talisman json
TALISMAN_JSON=$(cat "$1")
# Get the summary object
TALISMAN_SUMMARY_OBJ=$(echo "$TALISMAN_JSON" | jq '.summary')
# Get the types object
TALISMAN_TYPES_OBJ=$(echo "$TALISMAN_SUMMARY_OBJ" | jq '.types')
# Get the filecontent value
TALISMAN_FILECONTENT=$(echo "$TALISMAN_TYPES_OBJ" | jq '.filecontent')
echo "Found $TALISMAN_FILECONTENT file content issues"


ERROR_MESSAGES=()  # Declare an empty array

while IFS= read -r line; do
    # Split the line into filename and message
    filename="${line%% : *}"
    message="${line#* : }"

    # Store them as a string in the format "filename|message"
    ERROR_MESSAGES+=("$filename|$message")
done < <(echo "$TALISMAN_JSON" | jq -c '.results[] | .filename as $filename | .failure_list[], .warning_list[], .ignore_list[] | $filename + " : " + .message' -r)

# Print the array content
last_filename=""
for entry in "${ERROR_MESSAGES[@]}"; do
    # Split the entry back into filename and message
    IFS='|' read -r filename message <<< "$entry"

    # Extract filename from path
    filename=$(basename "$filename")

    # Skip if message is empty
    if [ -z "$message" ]; then
        continue
    fi

    # Check if message contains non-UTF-8 characters
    if ! (echo "$message" | iconv -f utf-8 -t utf-8 >/dev/null 2>&1); then
        message="ENCODED_TEXT"
    fi

    # Only print the filename if it's different from the last one that was printed
    if [ "$filename" != "$last_filename" ]; then
        echo ""
        echo "****************************************************************************************************"
        echo "$filename"
        last_filename="$filename"
    fi

    echo "Message: $message"
done
