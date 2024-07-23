## DevOpsFetch: Server Information Retrieval and Monitoring

## Objective

DevOpsFetch is a comprehensive tool designed for DevOps professionals to monitor and retrieve critical system information. It collects data on active ports, user logins, Nginx configurations, Docker images, and container statuses. This tool continuously monitors and logs activities through a systemd service.


## Devopsfetch Script Breakdown

## Usage

The `usage` function in the `devopsfetch` script provides information on how to use the script with different options. Below is the code for the `usage` function:

```bash
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
```

## Display Ports Function

The `display_ports` function in the `devopsfetch` script retrieves and displays information about active ports and services. Below is the code for the `display_ports` function:

```bash
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
```

## Display Docker Function

The `display_docker` function in the `devopsfetch` script retrieves and displays information about Docker images and containers. Below is the code for the `display_docker` function:

```bash
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
```

## Display Nginx Function

The `display_nginx` function in the `devopsfetch` script retrieves and displays information about Nginx domains and configurations. Below is the code for the `display_nginx` function:

```bash
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
```

## Display Users Function

The `display_users` function in the `devopsfetch` script retrieves and displays information about users and their last login times. Below is the code for the `display_users` function:

```bash
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
```

## Display Time Range Function

The `display_time_range` function in the `devopsfetch` script retrieves and displays system activities within a specified time range. Below is the code for the `display_time_range` function:

```bash
display_time_range() {
    local start_time="$1"
    local end_time="$2"
    if [ -z "$end_time" ]; then
        end_time="$(date +"%Y-%m-%d %H:%M:%S")"
    fi
    echo "Activities from $start_time to $end_time:"
    journalctl --since "$start_time" --until "$end_time"
}
```

## Main Script Logic

The devopsfetch script processes user commands, executing relevant functions based on the provided arguments. The script supports various options for displaying system information related to ports, Docker, Nginx, users, and activities over a time range. 

```bash
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
```

## Installation Script

The installation script `install_devopsfetch.sh` sets up the `DevOpsFetch` tool by performing several key tasks: installing dependencies, copying scripts, configuring the systemd service, and setting up log rotation. Below is a breakdown of the script:

```bash
#!/bin/bash

# Define paths and filenames
MAIN_SCRIPT="/usr/local/bin/devopsfetch"
WRAPPER_SCRIPT="/usr/local/bin/devopsfetch-wrapper"
SERVICE_FILE="/etc/systemd/system/devopsfetch.service"
LOG_FILE="/var/log/devopsfetch.log"
LOG_ROTATE_CONF="/etc/logrotate.d/devopsfetch"

# Function to install required dependencies
install_dependencies() {
    echo "Updating package list..."
    sudo apt update

    echo "Installing dependencies..."
    sudo apt install -y net-tools docker.io nginx logrotate
}

# Function to install and set up the main script
install_main_script() {
    echo "Copying the main script to $MAIN_SCRIPT..."
    sudo cp devopsfetch.sh $MAIN_SCRIPT
    sudo chmod +x $MAIN_SCRIPT
}

# Function to install and set up the wrapper script
install_wrapper_script() {
    echo "Copying the wrapper script to $WRAPPER_SCRIPT..."
    sudo cp devopsfetch-wrapper.sh $WRAPPER_SCRIPT
    sudo chmod +x $WRAPPER_SCRIPT
}

# Function to install and configure the systemd service
install_service() {
    echo "Copying the systemd service file to $SERVICE_FILE..."
    sudo cp devopsfetch.service $SERVICE_FILE

    echo "Reloading systemd and enabling the service..."
    sudo systemctl daemon-reload
    sudo systemctl enable devopsfetch.service
    sudo systemctl start devopsfetch.service
}

# Function to set up log rotation
setup_log_rotation() {
    echo "Setting up log rotation for $LOG_FILE..."

    echo "/var/log/devopsfetch.log {
        daily
        rotate 7
        compress
        delaycompress
        missingok
        notifempty
        create 0640 root root
        sharedscripts
        postrotate
            systemctl reload devopsfetch > /dev/null 2>/dev/null || true
        endscript
    }" | sudo tee $LOG_ROTATE_CONF > /dev/null
}

# Main installation process
main() {
    install_dependencies
    install_main_script
    install_wrapper_script
    install_service
    setup_log_rotation

    echo "DevOpsFetch has been installed and the service has been started."
}

# Run the main function
main
```

### Systemd Service Configuration

To configure `DevOpsFetch` as a systemd service, create a service file with the following content:

```ini
[Unit]
Description=DevOpsFetch Monitoring Service
After=network.target

[Service]
ExecStart=/usr/local/bin/devopsfetch-wrapper
Restart=always
RestartSec=60
StandardOutput=append:/var/log/devopsfetch.log
StandardError=append:/var/log/devopsfetch.log

[Install]
WantedBy=multi-user.target
```

### Querying Activities Over the Past 30 Days

To query activities for the past 30 days using `DevOpsFetch`, you can use the following script. This script calculates the date 30 days ago and the current date, then calls the `devopsfetch` script with these dates:

```bash
#!/bin/bash

# Calculate the date 30 days ago and the current date
start_date=$(date -d '30 days ago' +"%Y-%m-%d %H:%M:%S")
end_date=$(date +"%Y-%m-%d %H:%M:%S")

# Call the devopsfetch script with the calculated dates
/usr/local/bin/devopsfetch -t "$start_date" "$end_date"
```

## Run the Installation Script:

```bash
bash install_devopsfetch.sh
```

## Verify Installation
```bash
sudo systemctl status devopsfetch
```

## Usage
Command-Line Options
You can use devopsfetch with the following options:

- Display Active Ports:

```bash
devopsfetch -p
```

- Display Docker Information:

```bash
devopsfetch -d
```

- Display Nginx Information:

```bash
devopsfetch -n
```

- Display User Information:

```bash
devopsfetch -u
```

- Display Activities Over Time:

```bash
devopsfetch -t START END
```

- Display Help:

```bash
devopsfetch -h
```

## Log File

- Logs generated by devopsfetch can be found at:

```bash
/var/log/devopsfetch.log
```