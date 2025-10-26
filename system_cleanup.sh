#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_file="/home/$USER/script.log"

#create log file
touch "${log_file}"

echo ""
echo -e "${BLUE}starting storage management${NC}"
echo ""

#check disk usage
#everything df -h
#ext4 only df -h -t ext4
#specific directory du -sh /home/*

echo -e "${BLUE}checking disk usage...${NC}"
sleep 1
echo ""
echo -e "${GREEN}Total disk usage:${NC}"
df -h -t ext4

echo ""
echo -e "${GREEN}Disk usage per directory:${NC}"
du -h -sh /home/ | awk '{print "    "$0}'
sudo du -h -sh /etc/ | awk '{print "    "$0}'
sudo du -h -sh /bin/ | awk '{print "    "$0}'
sudo du -h -sh /opt/ | awk '{print "    "$0}'
sudo du -h -sh /var/ | awk '{print "    "$0}' 
sudo du -h -sh /snap/ | awk '{print "    "$0}'
sudo du -h -sh /usr/ | awk '{print "    "$0}'
sudo du -h -sh /tmp/ | awk '{print "    "$0}'
sudo echo "$(date): Checked disk usage(cmd: df -h)" | sudo tee -a "$log_file" >/dev/null


echo ""
echo ""
echo -e "${BLUE}Starting cleanup process${NC}"
echo ""

#checking for logs older than 7 days
echo -e "${BLUE}checking for outdated logs...${NC}"
sleep 1
echo ""
if sudo find /var/log -name "*.log" -mtime +7 | grep -q .; then
	echo -e "${GREEN}logs older than 7 days:${NC}"
	sudo find /var/log -name "*.log" -mtime +7 -exec du -h {} \; | sort -hr | awk '{print "    "$0}'
	sudo find /var/log -name "*.gz" -mtime +7 -exec du -h {} \; | sort -hr | awk '{print "    "$0}'
	#deleting logs older than 7 days
	while true; do
		read -p "Delete outdated log files? (older than 7 days) [Y/n] " -r
		echo "" 
		
		if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
			echo -e "${RED}Deleting outdated logs...${NC}"
			#sudo find /var/log -name "*.log" -mtime +7 -delete
			#sudo find /var/log -name "*.gz" -mtime +7 -delete
			sleep 1.5
			break
		elif [[ $REPLY =~ [N/n]$ ]]; then
			echo -e "${RED}You have selected to keep outdated logs${NC}"
			break
		else 
			echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
		fi
	done
else 
	echo -e "${GREEN}No outdated log files${NC}"
fi
echo ""
echo ""

#checking for journal entries older than 7 days
echo -e "${BLUE}checking for outdated journal entries...${NC}"
sleep 1
echo ""

if sudo journalctl --until "7 days ago" --quiet --no-pager | grep -q .; then
	echo -e "${GREEN}You have outdated journal entries${NC}"
	
	#deleting journal entries older than 7 days
	while true; do
		read -p "Delete outdated journal entries? (older than 7 days) [Y/n] " -r
		echo "" 
		
		if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
			echo -e "${RED}Deleting journal entries older than 7 days...${NC}"
			#sudo journalctl --vacuum-time=7d
			sleep 1.5
			break
		elif [[ $REPLY =~ [N/n]$ ]]; then
			echo -e "${RED}You have selected to keep outdated journal entries${NC}"
			break
		else 
			echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
		fi
	done

else 
	echo -e "${GREEN}No outdated journal entries${NC}"
fi
echo ""
echo ""


#tmp files cleanup
echo -e "${BLUE}Checking for temporary files...${NC}"
sleep 1
echo ""
#check if temporary files take up any storage space
if [[ $(sudo du -s /var/tmp | cut -f1) -gt 0 ]] || [[ $(sudo du -s /tmp | cut -f1) -gt 0 ]]; then
	echo -e "${GREEN}temporary files:${NC}"
	sudo du -h -sh /var/tmp | awk '{print "    "$0}'
	sudo du -h -sh /tmp/ | awk '{print "    "$0}'
	echo ""

	#Deleting temporary files
	while true; do
		read -p "Delete temporary files? [Y/n] " -r
		echo "" 
		
		if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
			echo -e "${RED}Deleting temporary files${NC}"
			#sudo find /tmp -type f -delete
			#sudo find /var -type f -delete
			
			sleep 1
			break
		elif [[ $REPLY =~ [N/n]$ ]]; then
			echo -e "${RED}You have selected to keep temporary files${NC}"
			break
		else 
			echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
		fi
	done
else
	echo -e "${RED}You don't have any temporary files${NC}"
fi
echo""
echo""


#cache cleanup
echo -e "${BLUE}Checking for cache...${NC}"
sleep 1
echo ""
if [[ $(sudo du -h -sh /var/cache/apt/archives/ | cut -f1) -gt 0]] || [[ $(sudo du -h -sh ~/.cache -gt 0 | cut -f1) -gt 0]] || [[$(sudo du -h -sh ~/.local/share/Trash | cut -f1) -gt 0]] || [[$(sudo du -h -sh ~/.Thumbnails| cut -f1) -gt 0]]; then

	echo -e "${GREEN}Cache:${NC}"
	sudo du -h -sh /var/cache/apt/archives/ | awk '{print "    "$0}'
	sudo du -h -sh ~/.cache | awk '{print "    "$0}'
	sudo du -h -sh ~/.local/share/Trash | awk '{print "    "$0}'
	sudo du -h -sh ~/.Thumbnails| awk '{print "    "$0}'
	echo ""

	#Deleting cache
	while true; do
		read -p "Delete cache? [Y/n] " -r
		echo "" 
		
		if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
			echo -e "${RED}Deleting cache...${NC}"
			#rm -rf ~/.cache/*
			#sudo apt clean
			#sudo apt autoclean
			#sudo apt autoremove
			#sudo find /var/cache/apt/archives/ -type f -mtime +14 -delete 2>/dev/null
			#rm -rf ~/.local/share/Trash/*
			sleep 1
			break
		elif [[ $REPLY =~ [N/n]$ ]]; then
			echo -e "${RED}You have selected to keep cache${NC}"
			break
		else 
			echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
		fi
	done
else 
	echo -e "${RED}You don't have any cache${NC}"
fi
echo ""
echo ""

#performing system update

echo -e "${BLUE}updating package lists..${NC}"
sudo apt update
echo ""
echo -e "${BLUE}Checking for available updates...${NC}"
echo ""
echo -e "${GREEN}The following packages can be upgraded:${NC}"
sudo apt list --upgradable | awk '{print "    "$0}'
echo ""

while true; do
	read -p "Cleanup done. Upgrade system? [Y/n] " -r
	echo "" 
	
	if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
		echo -e "${RED}updating system...${NC}"
		#sudo apt full-upgrade
		
		while true; do
			read -p "System upgrade done. Reboot system now? [Y/n] " -r
			echo "" 
			
			if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
				echo -e "${RED}Rebooting...${NC}"
				#sudo reboot
				break
			elif [[ $REPLY =~ [N/n]$ ]]; then
				echo -e "${RED}exiting...${NC}"
				sleep 1
				break
			else 
				echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
			fi
		done
		break
	elif [[ $REPLY =~ [N/n]$ ]]; then
		echo -e "${RED}exiting...${NC}"
		sleep 1
		break
	else 
		echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
	fi
done
