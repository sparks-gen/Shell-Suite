# I'll need to set the notify topic for this machine first. So notify will need
# its own setup function. Maybe each seperate command should have its own setup 
# function, and then the global install.sh function that calls the relevant 
# ones.

# Problem here is that notify also needs to retrieve the topic somehow.

notify () {
    local topic message priority
    message="${1:?Usage: notify <message> [priority]}"
    priority="${2:-default}"

    topic="$(_current_value NOTIFY_TOPIC)"
    if [[ -z "$topic" ]]; then
        echo "notify: NOTIFY_TOPIC isn't set for this machine yet. Run change_machine_settings first." >&2
        return 1
    fi

    curl -s \
    -H "Title: $(hostname -s 2>/dev/null || hostname)" \
    -H "Priority: ${priority}" \
    -d "${message}" \
    "https://ntfy.sh/${topic}" > /dev/null
}

notify_setup () {
    # Set topic
}