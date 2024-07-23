#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -p, --port [PORT]      Display active ports or specific port information"
    echo "  -d, --docker [NAME]    Display Docker information"
    echo "  -n, --nginx [DOMAIN]   Display Nginx information"
    echo "  -u, --users [USER]     Display user information"
    echo "  -t, --time START END   Display activities within a time range"
    echo "                         START and END should be in the format: 'YYYY-MM-DD HH:MM:SS'"
    echo "  -h, --help             Display this help message"
    exit 1
}

display_ports() {
    if [ -z "$1" ]; then
        echo "Active ports and services:"
        (
            echo "Protocol Local Address Foreign Address State PID/Program name"
            ss -tuln | tail -n +2 | awk '{
                split($5, local, ":")
                split($6, foreign, ":")
                proto = $1
                state = $2
                pid_prog = $7
                printf "%s %s %s %s %s\n", proto, local[2], foreign[2], state, pid_prog
            }'
        ) | column -t -s' ' -o' | '
    else
        echo "Information for port $1:"
        ss -tlnp | awk -v port="$1" '$5 ~ ":"port"$" {print}' | column -t -s' ' -o' | '
    fi
}

# Function to display Docker information
display_docker() {
    if [ -z "$1" ]; then
        echo "Docker images:"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}"
        echo -e "\nDocker containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    else
        echo "Information for Docker container $1:"
        docker inspect $1
    fi
}

# Function to display Nginx information
display_nginx() {
    if [ -z "$1" ]; then
        echo "Nginx domains and ports:"
        grep -r server_name /etc/nginx/sites-enabled/ | awk '{print $2}' | sed 's/;//'
        grep -r listen /etc/nginx/sites-enabled/ | awk '{print $2}' | sed 's/;//'
    else
        echo "Nginx configuration for domain $1:"
        grep -r -A 10 "server_name $1" /etc/nginx/sites-enabled/
    fi
}

# Function to display user information
display_users() {
    if [ -z "$1" ]; then
        echo "Users and their last login times:"
        last | awk '!seen[$1]++ {print $1, $3, $4, $5, $6}'
    else
        echo "Information for user $1:"
        id $1
        last $1 | head -n 1
    fi
}

# Function to display time information
display_time_range() {
    local start_time="$1"
    local end_time="$2"
    if [ -z "$end_time" ]; then
        end_time="$(date +"%Y-%m-%d %H:%M:%S")"
    fi
    echo "Activities from $start_time to $end_time:"
    journalctl --since "$start_time" --until "$end_time"
}

# Main logic
case "$1" in
    -p|--port)
        display_ports "$2"
        ;;
    -d|--docker)
        display_docker "$2"
        ;;
    -n|--nginx)
        display_nginx "$2"
        ;;
    -u|--users)
        display_users "$2"
        ;;
    -t|--time)
        if [ -n "$2" ] && [ -n "$3" ]; then
            display_time_range "$2" "$3"
        else
            echo "Error: Both START and END times must be provided for the -t option."
            usage
        fi
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Invalid option: $1"
        usage
        ;;
esac

