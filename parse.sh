#!/bin/bash

# File:         beddingfield.sh
# Name:         Noah Beddingfield
# Date:         20241019 (Date last modified)
# Desc:         Automate the task of determining which services are running on which unique IP addresses
# Usage:        ./beddingfield.sh NMAP_all_hosts.txt
# Note:         This script should work on any NMAP scan given. If a file is not found or not given, it throws an error

# Take a file argument to script for reference throughout the rest of the script.
FILE=$1

# Uses an if statement to check if a file is even given when running the script
# If not, it will return an error and exit
if [[ $# -ne 1 ]]; then
    echo "Please provide a file when running the command!"
    exit 1
fi

# Uses an if statement to check if a file, that is given, exists.
# If the file cannot be found or does not exist, then it will return an error and exit
if [[ ! -f "$FILE" ]]; then
    echo "The given file: '$FILE' does not exist."
    exit 1
fi

# Used to declare two arrays to be used inside of the script
declare -A service_count
declare -A ips

# The while loop is used to take the file given and read it line by line
# Storing it inside of a variable called "LINES"
	while IFS= read -r LINES
	do 
	     	# This if statement determines if any of the lines stored in the "LINES" variable
		# Matches the text. If it does then it uses awk to grab the 5th text, which is the IP address in the scan
	       	if [[ "$LINES" =~	"Nmap scan report for" ]]; then
		      ip_address=$(awk '{print $5}' <<< "$LINES")
		  
	      fi

	      # This if statement determines if any of the lines stored in the "LINES" variable
	      # Matches port number/tcp or udp and if it does then it uses awk to grab the port number and service name
	      if [[ $LINES =~ ^[0-9]{1,5}\/(tcp|udp) ]]; then
		      port=$(awk -F "/" '{print $1}' <<< "$LINES")
		      service_name=$(awk '{print $3}' <<< "$LINES")

		      	# This if statement is used to stop the same IP address from being counted multiple times
			# if the service "unknown" was running on multiple ports
			if 
				[[ "$service_name" == "unknown" ]]; then
           				 # Only count this IP once for "unknown"
           				 if [[ -z "${ips["unknown:$ip_address"]}" ]]; then
               					 ((service_count["unknown"]++))
               					 ips["unknown:$ip_address"]=1  # Mark this IP as counted
           				 fi
       			 else
			# Everything else is stored in the declared arrays to be used to print
		      ((service_count["$service_name"]++))
        		ips["$service_name:$ip_address"]="$ip_address"
		fi
	      fi
# Uses the FILE given as the input for the while loop
done < $FILE

# This for statement is used along with various arrays to print the stored information required.
# If there is actually stuff stored, then it runs

for service in "${!service_count[@]}"; do
    count=${service_count["$service"]}
    if [[ $count -gt 0 ]]; then
        echo "Service: $service Count: $count"
        echo "==============================="
        # Print all IPs associated with the service, removing the trailing newline
        for ip in "${!ips[@]}"; do
		if [[ "$ip" =~ ^"$service": ]]; then
                echo "${ip#*:}"  # Print the IP address (remove the prefix)
	fi 
        done
        echo ""  # Add an extra newline for separation
    fi 
done
