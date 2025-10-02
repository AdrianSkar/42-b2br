#!/bin/bash 
# Capture and extract approach + use <<< to pass vars to awk instead of
# constantly calling and piping (eg: "echo $var | awk '{print $1}'")

# Supress error messages as instructed on subject
exec 2>/dev/null

# architecture
arch=$(uname -a)

# CPUs (physical and virtual)
lscpu_out=$(lscpu)
cpu_p=$(awk '/^Socket\(s\):/ {print $2}' <<< "$lscpu_out")
cpu_v=$(awk '/^CPU\(s\):/ {print $2}' <<< "$lscpu_out)")

# RAM
free_out=$(free -m)
ram_used=$(awk '/^Mem:/ {print $3}' <<< "$free_out")
ram_total=$(awk '/^Mem:/ {print $2}' <<< "$free_out")
ram_per=$(awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100}' <<< "$free_out")

# Disk
df_out=$(df -h --total)
disk_used=$(awk '/^total/ {printf "%.1f\n", $3}' <<< "$df_out")
disk_total=$(awk '/^total/ {print $2}' <<< "$df_out")
disk_per=$(awk '/^total/ {print $5}' <<< "$df_out")

# CPU load (takes cpu idle and subtracts it from 100; value from vmstat 2nd as
# 1st is average since boot)
load=$(vmstat 1 2 | tail -n 1)
load_per=$(awk '{print 100 - $15}' <<< "$load")

# Last boot (-b flag to who shows last boot time)
boot=$(uptime -s)
# or
# boot=$(who -b | awk '{print $3, $4}')

# LVM use (lvs lists logical volumes; if it fails, lvm is not in use))
lvm_use=$(/sbin/lvs --noheadings > /dev/null && echo "yes" || echo "no")

# TCP connections (`ss` has built-in filters for TCP connections and state)
tcp_cons=$(ss -t state established -H | wc -l)

# Number of users logged in (who -q shows number of users)
users=$(who | wc -l)

# ipv4 and MAC (exclude loopback 127.0.0.1 because does not actually identify 
# the machine); extract public IP using `route` (source at 7th column)
ipv4=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
mac=$(ip link show | awk '/link\/ether/ {print $2; exit}')

# Sudo (number of sudo commands run)
sudo=$(journalctl _COMM=sudo | awk '/COMMAND=/ {lines++} END {print lines}')
# or
# sudo = cat /var/log/sudo/sudo.log | grep "COMMAND=" | wc -l


# Message broadcast
wall "  #Architecture: $arch
		#pCPU: $cpu_p
		#vCPU: $cpu_v
		#Memory usage: $ram_used/${ram_total}MB ($ram_per%)
		#Disk usage: $disk_used/${disk_total}B ($disk_per)
		#CPU load: $load_per%
		#Last boot: $boot
		#LVM use: $lvm_use
		#TCP connections: $tcp_cons established
		#User log: $users
		#Network: IP $ipv4 ($mac)
		#Sudo: $sudo
		"
