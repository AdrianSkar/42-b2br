# `born2beroot`

![42 School](https://img.shields.io/badge/42-Madrid-000000?style=flat&logo=42&logoColor=white)
![Score](https://img.shields.io/badge/Score-110%2F100-success)
![Debian](https://img.shields.io/badge/OS-Debian-A81D33?logo=debian&logoColor=white)
![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)

Linux system administration project: Virtual machine setup with LVM, security hardening, and automated monitoring | 42 School project

---

- [📔 Project overview](#-project-overview)
- [📚 Concept guide](#-concept-guide)
- [🔧 Implementation](#-implementation)
- [💡 Potential improvements](#-potential-improvements)
- [📝 Notes](#-notes)
- [🛠️ Setup and usage](#️-setup-and-usage)
- [⚖️ License](#️-license)
  
## 📔 Project overview

The goal of this project is to set up a virtual machine server with strict security and configuration requirements. It provides hands-on experience with system administration, virtualization, security policies, and Linux fundamentals.

- **Objective**: Configure a secure virtual machine running Debian with specific partitioning, security policies, and monitoring capabilities.
- **Operating system**: Debian (latest stable version)
- **Virtualization**: VirtualBox (Type 2 hypervisor)
- **Key components**: LVM partitioning, SSH configuration, UFW firewall, sudo policies, password policies, monitoring script
- **Returns**: 
	- ✔️ Fully configured and hardened Debian server
	- ✔️ Automated monitoring script broadcasting system information
	- ✔️ Comprehensive understanding of Linux system administration

### Learning objectives
- Master Linux system administration fundamentals
- Understand and implement security best practices
- Work with Logical Volume Manager (LVM) for flexible disk management
- Configure secure remote access via SSH
- Implement system monitoring and automation

## 📚 Concept guide

### Core concepts

1. **Virtualization**: Creating virtual versions of computing resources. Uses a hypervisor to run multiple virtual machines (VMs) on a single physical machine.
   - **Type 1 (bare-metal)**: Runs directly on hardware (VMware ESXi, Hyper-V)
   - **Type 2 (hosted)**: Runs on top of an OS (VirtualBox, VMware Workstation)

2. **Logical Volume Manager (LVM)**: Flexible disk management system allowing dynamic resizing of partitions, snapshots, and easier disk management compared to traditional partitioning.

3. **SSH (Secure Shell)**: Encrypted network protocol for secure remote access and command execution. Key-based authentication provides stronger security than passwords.

4. **Firewall (UFW)**: Uncomplicated Firewall - user-friendly interface for managing iptables firewall rules. Controls incoming and outgoing network traffic.

5. **Sudo policies**: Configuration controlling superuser access and command execution logging. Essential for security and audit trails.

6. **AppArmor**: Mandatory Access Control (MAC) system that restricts programs' capabilities with per-program profiles.

7. **Password policies**: Security measures including complexity requirements, expiration dates, and account lockout mechanisms to prevent unauthorized access.

8. **Cron**: Time-based job scheduler for running scripts and commands at specific intervals or times.

## 🔧 Implementation

### System architecture

#### Partition structure (bonus config)
```plaintext
NAME                    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
sda                       8:0    0 30.8G  0 disk
├─sda1                    8:1    0  476M  0 part  /boot
├─sda2                    8:2    0    1K  0 part
└─sda5                    8:5    0 30.3G  0 part
  └─sda5_crypt          254:0    0 30.3G  0 crypt
    ├─LVMGroup-root     254:1    0  9.3G  0 lvm   /
    ├─LVMGroup-swap     254:2    0  2.1G  0 lvm   [SWAP]
    ├─LVMGroup-home     254:3    0  4.7G  0 lvm   /home
    ├─LVMGroup-var      254:4    0  2.8G  0 lvm   /var
    ├─LVMGroup-srv      254:5    0  2.8G  0 lvm   /srv
    ├─LVMGroup-tmp      254:6    0  2.8G  0 lvm   /tmp
    └─LVMGroup-var--log 254:7    0  3.7G  0 lvm   /var/log
```

#### Security configuration

| Component | Configuration | Purpose |
|-----------|--------------|---------|
| **SSH** | Custom port, Root login disabled | Secure remote access |
| **UFW/Firewalld** | Default deny policy, Minimal open ports | Network protection |
| **Sudo** | Limited attempts, TTY mode required, Full command logging, Restricted paths | Privilege escalation control |
| **Passwords** | Expiration policies, Minimum age, Advance warning, Length and complexity requirements | Account security |
| **AppArmor/SELinux** | Enabled on boot with enforcing mode | Mandatory Access Control |

### Monitoring script

The monitoring script (`monitoring.sh`) collects and broadcasts system information at regular intervals. Key implementation features:

- **Efficient data capture**: Single execution of commands stored in variables to ensure consistent data
- **Optimized parsing**: Uses `awk` for direct data extraction instead of multiple pipe chains
- **Error suppression**: Redirects stderr to `/dev/null` for clean output
- **Wall broadcast**: Uses `wall` command to display information to all logged-in users

#### Monitoring metrics

| Metric | Command/Method | Description |
|--------|---------------|-------------|
| Architecture | `uname -a` | OS architecture and kernel version |
| Physical CPUs | `lscpu` → Socket count | Number of physical processor cores |
| Virtual CPUs | `lscpu` → CPU count | Number of virtual processor cores |
| Memory usage | `free -m` | Currently available RAM and usage percentage |
| Disk usage | `df -h --total` | Currently available disk space and usage percentage |
| CPU load | `vmstat 1 2` | Current processor usage as percentage |
| Last boot | `uptime -s` or `who -b` | Date and time of last reboot |
| LVM status | `lvs` check | Whether LVM is active (yes/no) |
| TCP connections | `ss -t state established` | Number of active TCP connections |
| User logins | `who` count | Number of users currently logged in |
| Network | `ip route` + `ip link` | Server IPv4 address and MAC address |
| Sudo commands | `journalctl _COMM=sudo` | Number of commands executed with sudo |

#### Script output example
```plaintext
Broadcast message from root@debian (tty1) (Thu Oct 02 15:45:00 2025):

#Architecture: Linux debian 6.1.0-25-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.106-3 x86_64 GNU/Linux
#CPU physical: 1
#vCPU: 2
#Memory Usage: 158/1987MB (7.85%)
#Disk Usage: 1.2/8.9Gb (13%)
#CPU load: 2.4%
#Last boot: 2024-10-02 09:30
#LVM use: yes
#TCP Connections: 1 ESTABLISHED
#User log: 1
#Network: IP 10.0.3.15 (08:00:27:51:9a:a5)
#Sudo: 15 cmd
```

### Key implementation decisions

**Data capture approach**: The script captures output from system commands once and stores them in variables, then uses `awk` with here-strings (`<<<`) to extract specific fields. This approach:
- Ensures data consistency across metrics (e.g., memory statistics are from the same moment)
- Reduces system overhead by minimizing command executions
- Avoids issues with commands that show changing data on each execution

**Efficient text processing**: Direct `awk` pattern matching instead of `grep | awk` chains provides:
- Better performance with fewer process spawns
- Cleaner, more maintainable code
- More precise field extraction

## 💡 Potential improvements

- **Advanced monitoring**: Integration with modern tools like Prometheus and Grafana for real-time metrics visualization, historical data analysis, and alerting capabilities.

## 📝 Notes

### Design decisions

- **Debian over Rocky Linux**: Chosen for its stability, extensive package repository, strong community support, and familiarity with Debian-based distributions. Debian's APT package manager and widespread adoption make it ideal for learning system administration.

- **LVM for partitioning**: Provides flexibility for future disk management needs, enables snapshots for backups, and allows dynamic volume resizing without downtime.

- **Monitoring script optimization**: Many online guides suggest running commands multiple times within the script, which can lead to inconsistent data (e.g., different memory values from multiple `free` executions). This implementation captures output once and parses it multiple times for accuracy.

### Common pitfalls avoided

- **Command repetition**: Avoided executing system commands multiple times, which ensures data consistency and reduces overhead
- **Overuse of grep**: Used `awk` built-in pattern matching instead of chaining `grep | awk` for cleaner and more efficient text processing
- **IP address detection**: Excludes loopback address (127.0.0.1) by using `ip route get` to find the actual network interface IP

## 🛠️ Setup and usage

1. **Create the virtual machine**
   ```bash
   # VirtualBox settings
   - Name: Born2BeRoot
   - Type: Linux
   - Version: Debian (64-bit)
   - Memory: 2048 MB
   - Disk: 30.8 GB (VDI, dynamically allocated)
   ```

2. **Install Debian with encrypted LVM**
   - Follow bonus partition structure
   - Set up encrypted volumes
   - Configure LVM groups and logical volumes

3. **Configure security policies**
   ```bash
   # Install and configure sudo
   apt install sudo
   visudo  # Configure sudo policies
   
   # Set up password policies
   # Edit /etc/login.defs and /etc/security/pwquality.conf
   
   # Configure SSH
   # Edit /etc/ssh/sshd_config (custom port, PermitRootLogin no)
   
   # Set up UFW firewall
   apt install ufw
   ufw allow <custom_port>
   ufw enable
   ```

4. **Deploy monitoring script**
   ```bash
   # Copy script to /usr/local/bin/
   sudo cp monitoring.sh /usr/local/bin/monitoring.sh
   sudo chmod 755 /usr/local/bin/monitoring.sh
   
   # Configure cron for periodic execution
   sudo crontab -e
   # Add appropriate cron schedule
   ```

## ⚖️ License

This project is licensed under the [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](LICENSE).

You're free to study, modify, and share this code for educational purposes, but commercial use is prohibited.

---

