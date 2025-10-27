#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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

			log_files=($(sudo find /var/log \( -name "*.log" -o -name "*.gz" \) -mtime +7))
			all_log_files=${#log_files[@]}
			removed_logs=0

			for file in "${log_files[@]}"; do
				#sudo rm -f "$file"
				removed_logs=$((removed_logs + 1))
				
				local percent_logs_removed=$((removed_logs * 100 / all_log_files))

				filled=$((percent_log_removed / 2))
				empty=$((50 - filled))

				printf "\r${GREEN}[%-50s]${NC} %d%%" "$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))" "$i" 

			done
			sleep 0.3
			echo ""
			echo -e "${RED}Done${NC}"
			break

		elif [[ $REPLY =~ ^[Nn]$ ]]; then
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

			for i in {0..100}; do
				
				if [[ $i -eq 10 ]]; then
					sudo journalctl --vacuum-time=7d 
				fi

				filled=$((i / 2))
				empty=$((50 - filled))

				printf "\r${GREEN}[%-50s]${NC} %d%%" "$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))" "$i" 
			done
			sleep 0.3
			echo ""
			echo -e "${RED}Done${NC}"
			break
		elif [[ $REPLY =~ ^[Nn]$ ]]; then
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

			tmp_files=($(sudo find /tmp /var/tmp -type f))
			all_tmp_files=${#tmp_files[@]}
			removed_tmp_files=0

			for file in "${tmp_files[@]}"; do
				#sudo rm -f "$file"
				removed_tmp_files=$((removed_tmp_files + 1))
				
				local percent__tmp_removed=$((removed_tmp_files * 100 / all_tmp_files))
				
				#if [[$i -eq 20]]; then
					#sudo find /tmp -type f -delete
				#elif [[$i -eq 40]]; then
					#sudo find /var/tmp -type f -delete
				#fi

				filled=$((percent_tmp_removed / 2))
				empty=$((50 - filled))

				printf "\r${GREEN}[%-50s]${NC} %d%%" "$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))" "$i" 

			done
			sleep 0.3
			echo ""
			echo -e "${RED}Done${NC}"
			break
		elif [[ $REPLY =~ ^[Nn]$ ]]; then
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
if [[ $(sudo du -s /var/cache/apt/archives/ | cut -f1) -gt 0 ]] || [[ $(sudo du -s ~/.cache | cut -f1) -gt 0 ]] || [[ $(sudo du -s ~/.local/share/Trash | cut -f1) -gt 0 ]] || [[ $(sudo du -s ~/.Thumbnails| cut -f1) -gt 0 ]]; then

	echo -e "${GREEN}Cache:${NC}"
	sudo du -sh /var/cache/apt/archives/ | awk '{print "    "$0}'
	sudo du -sh ~/.cache | awk '{print "    "$0}'
	sudo du -sh ~/.local/share/Trash | awk '{print "    "$0}'
	echo ""

	#Deleting cache
	while true; do
		read -p "Delete cache? [Y/n] " -r
		echo "" 
		
		if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
			echo -e "${RED}Deleting cache...${NC}"

			cache_files=($(sudo find ~/.cache ~/.local/share/Trash /var/cache/apt/archives/ -type f ))
			all_cache_files=${#cache_files[@]}
			removed_cache=0

			for file in "${tmp_files[@]}"; do
				#sudo rm -f "$file"
				removed_cache=$((removed_cache + 1))
				
				local percent_cache_removed=$((removed_cache * 100 / all_cache_files))
				
				#if [[percent_cache_removed -eq 20]]; then
					#sudo apt clean
				#elif [[percent_cache_removed  -eq 40]]; then
					#sudo apt autoclean
				#elif [[percent_cache_removed  -eq 60]]; then
					#sudo apt autoremove
				#fi

				filled=$((percent_cache_removed / 2))
				empty=$((50 - filled))

				printf "\r${GREEN}[%-50s]${NC} %d%%" "$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))" "$i" 

			done
			sleep 0.3
			echo ""
			echo -e "${RED}Done${NC}"
			break

		elif [[ $REPLY =~ ^[Nn]$ ]]; then
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

echo -e "${BLUE}updating package lists...${NC}"
echo ""
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
			elif [[ $REPLY =~ ^[Nn]$ ]]; then
				echo -e "${RED}exiting...${NC}"
				sleep 1
				break
			else 
				echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
			fi
		done
		break
	elif [[ $REPLY =~ ^[Nn]$ ]]; then
		echo -e "${RED}exiting...${NC}"
		sleep 1
		break
	else 
		echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
	fi
done
