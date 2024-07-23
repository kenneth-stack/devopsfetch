#!/bin/bash

# Calculate the date 30 days ago and the current date
start_date=$(date -d '30 days ago' +"%Y-%m-%d %H:%M:%S")
end_date=$(date +"%Y-%m-%d %H:%M:%S")

# Call the devopsfetch script with the calculated dates
/usr/local/bin/devopsfetch -t "$start_date" "$end_date"


