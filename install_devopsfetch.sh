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
    sudo apt install -y net-tools docker.io nginx
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
