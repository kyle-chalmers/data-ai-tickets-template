# === Fixed Slack User Functions ===

# Get list of users (with error handling)
slack_users() {
    local response=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
         "https://slack.com/api/users.list")
    
    # Check if request was successful
    if echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('ok') else 1)" 2>/dev/null; then
        echo "$response" | python3 -m json.tool
    else
        echo "Error: $response"
    fi
}

# Get user profile by email
slack_user_by_email() {
    local email="$1"
    local response=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
         "https://slack.com/api/users.lookupByEmail?email=$email")
    
    if echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('ok') else 1)" 2>/dev/null; then
        echo "$response" | python3 -m json.tool
    else
        echo "Error looking up user: $response"
    fi
}

# Simple user search (works with basic permissions)
slack_find_user_simple() {
    local search_name="$1"
    echo "Searching for users with '$search_name' in their name..."
    echo "Note: This requires elevated permissions. Try slack_user_by_email instead if you know their email."
}

# Send DM by email (more reliable)
slack_dm_by_email() {
    local email="$1"
    local message="$2"
    
    echo "Looking up user: $email"
    local user_response=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
         "https://slack.com/api/users.lookupByEmail?email=$email")
    
    # Check if lookup was successful
    if echo "$user_response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('ok') else 1)" 2>/dev/null; then
        local user_id=$(echo "$user_response" | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])")
        echo "Found user ID: $user_id"
        
        # Open DM channel
        local dm_response=$(curl -s -X POST \
             -H "Authorization: Bearer $SLACK_TOKEN" \
             -H "Content-Type: application/json" \
             -d "{\"users\":\"$user_id\"}" \
             "https://slack.com/api/conversations.open")
        
        local channel_id=$(echo "$dm_response" | python3 -c "import sys, json; print(json.load(sys.stdin)['channel']['id'])")
        echo "DM Channel ID: $channel_id"
        
        # Send message
        curl -X POST \
             -H "Authorization: Bearer $SLACK_TOKEN" \
             -H "Content-Type: application/json" \
             -d "{\"channel\":\"$channel_id\",\"text\":\"$message\"}" \
             "https://slack.com/api/chat.postMessage"
    else
        echo "Failed to find user: $user_response"
    fi
}


slack_create_group() {
    local user_ids="$1"
    curl -X POST \
         -H "Authorization: Bearer $SLACK_TOKEN" \
         -H "Content-Type: application/json" \
         -d "{\"users\":\"$user_ids\"}" \
         "https://slack.com/api/conversations.open" | python3 -m json.tool
}

slack_group_by_emails() {
    local email1="$1"
    local email2="$2"
    local email3="$3"
    
    echo "Looking up users..."
    
    local user1=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
         "https://slack.com/api/users.lookupByEmail?email=$email1" | \
         python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null)
    
    local user2=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
         "https://slack.com/api/users.lookupByEmail?email=$email2" | \
         python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null)
    
    local user3=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
         "https://slack.com/api/users.lookupByEmail?email=$email3" | \
         python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null)
    
    echo "User IDs: $user1, $user2, $user3"
    
    local user_list="$user1,$user2,$user3"
    slack_create_group "$user_list"
}


slack_group_by_emails_dynamic() {
    local emails=("$@")
    local user_ids=()
    
    echo "Looking up ${#emails[@]} users..."
    
    for email in "${emails[@]}"; do
        echo "Looking up: $email"
        local user_response=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
             "https://slack.com/api/users.lookupByEmail?email=$email")
        
        if echo "$user_response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('ok') else 1)" 2>/dev/null; then
            local user_id=$(echo "$user_response" | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])")
            user_ids+=("$user_id")
            echo "Found: $email -> $user_id"
        else
            echo "Failed to find: $email"
        fi
    done
    
    if [ ${#user_ids[@]} -gt 1 ]; then
        local user_list=$(IFS=,; echo "${user_ids[*]}")
        echo "Creating group with user IDs: $user_list"
        
        curl -X POST \
             -H "Authorization: Bearer $SLACK_TOKEN" \
             -H "Content-Type: application/json" \
             -d "{\"users\":\"$user_list\"}" \
             "https://slack.com/api/conversations.open" | python3 -m json.tool
    else
        echo "Need at least 2 users to create a group"
    fi
}

slack_send_to_group() {
    local channel_id="$1"
    local message="$2"
    
    curl -X POST \
         -H "Authorization: Bearer $SLACK_TOKEN" \
         -H "Content-Type: application/json" \
         -d "{\"channel\":\"$channel_id\",\"text\":\"$message\"}" \
         "https://slack.com/api/chat.postMessage"
}

slack_delete_message() {
    local input="$1"
    local channel_id=""
    local message_timestamp=""
    
    # Check if input is a Slack URL
    if [[ "$input" == *"slack.com/archives"* ]]; then
        # Extract channel ID and timestamp from URL
        # URL format: https://teamhappymoney.slack.com/archives/C098HB0AQHF/p1754085169578969
        channel_id=$(echo "$input" | grep -o '/archives/[^/]*' | cut -d'/' -f3)
        local p_timestamp=$(echo "$input" | grep -o 'p[0-9]*' | sed 's/p//')
        
        # Convert p-timestamp to Slack timestamp format (add decimal point)
        if [[ ${#p_timestamp} -gt 10 ]]; then
            message_timestamp="${p_timestamp:0:10}.${p_timestamp:10}"
        else
            message_timestamp="$p_timestamp"
        fi
        
        echo "Extracted from URL:"
        echo "  Channel: $channel_id"
        echo "  Timestamp: $message_timestamp"
    else
        # Assume direct inputs (channel_id, timestamp)
        channel_id="$1"
        message_timestamp="$2"
        echo "Using direct inputs:"
        echo "  Channel: $channel_id" 
        echo "  Timestamp: $message_timestamp"
    fi
    
    if [[ -z "$channel_id" || -z "$message_timestamp" ]]; then
        echo "Error: Could not extract channel ID and timestamp"
        echo "Usage: slack_delete_message <slack_url>"
        echo "   or: slack_delete_message <channel_id> <timestamp>"
        return 1
    fi
    
    echo "Deleting message..."
    curl -X POST \
         -H "Authorization: Bearer $SLACK_TOKEN" \
         -H "Content-Type: application/json" \
         -d "{\"channel\":\"$channel_id\",\"ts\":\"$message_timestamp\"}" \
         "https://slack.com/api/chat.delete"
}

