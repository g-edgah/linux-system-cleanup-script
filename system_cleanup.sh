#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_file="/home/$USER/cleanup_script_log.txt"

#create log file
touch "${log_file}"

#log
echo "$(date): system_cleanup script started" | sudo tee -a "$log_file" > /dev/null

echo ""
echo -e "${BLUE}starting storage management${NC}"
echo ""

#check disk usage
#everything df -h
#ext4 only df -h -t ext4
#specific directory du -sh /home/*

echo -e "${BLUE}Checking disk usage...${NC}"
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

#log
echo "$(date): Checked disk usage" | sudo tee -a "$log_file" > /dev/null


echo ""
echo ""
echo -e "${BLUE}Starting cleanup process${NC}"
echo ""

#checking for logs older than 7 days
echo -e "${BLUE}checking for outdated logs...${NC}"
sleep 1
echo ""

#log
echo "$(date): Checked for outdated logs" | sudo tee -a "$log_file" > /dev/null

if sudo find /var/log \( -name "*.log" -o -name "*.gz" \) -mtime +7 | grep -q .; then
	echo -e "${GREEN}logs older than 7 days:${NC}"
	sudo find /var/log \( -name "*.log" -o -name "*.gz" \) -mtime +7 -exec du -h {} \; | sort -hr | awk '{print "    "$0}'

	#log
	echo "$(date): Outdated logs found" | sudo tee -a "$log_file" > /dev/null

	#deleting logs older than 7 days
	while true; do
		read -p "Delete outdated log files? (older than 7 days) [Y/n] " -r
		echo "" 
		
		if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
			echo -e "${RED}Deleting outdated logs...${NC}"
			#sudo find /var/log -name "*.log" -mtime +28 -delete
			#sudo find /var/log -name "*.gz" -mtime +30 -delete

			log_files=($(sudo find /var/log \( -name "*.log" -o -name "*.gz" \) -mtime +7)
			echo "${log_files}")
			all_log_files=${#log_files[@]}
			#echo "Found $all_log_files log files:"
			removed_logs=0

			for file in "${log_files[@]}"; do
				sudo rm -f "$file"
				removed_logs=$((removed_logs + 1))
				
				percent_logs_removed=$((removed_logs * 100 / all_log_files))

				filled=$((percent_logs_removed / 2))
				empty=$((50 - filled))

				printf "\r${GREEN}▌%-50s▐${NC} %d%%" "$(printf '█%.0s' $(seq 1 $filled))$([[ $empty -gt 0 ]] && printf '░%.0s' $(seq 1 $empty))" "$percent_logs_removed" 

			done

			#log
			echo "$(date): Deleted outdated logs" | sudo tee -a "$log_file" > /dev/null
			sleep 0.3
			echo ""
			echo -e "${RED}Done${NC}"
			break

		elif [[ $REPLY =~ ^[Nn]$ ]]; then
			echo -e "${RED}You have selected to keep outdated logs${NC}"
			
			#log
			echo "$(date): User selected to keep outdated logs" | sudo tee -a "$log_file" > /dev/null
			break
		else 
			echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
		fi
	done
else 
	echo -e "${GREEN}No outdated log files${NC}"
	#log
	echo "$(date): No outdated logs found" | sudo tee -a "$log_file" > /dev/null
fi
echo ""
echo ""

#checking for journal entries older than 7 days
echo -e "${BLUE}checking for outdated journal entries...${NC}"
sleep 1
echo ""

#log
echo "$(date): Checked for outdated journal entries" | sudo tee -a "$log_file" > /dev/null

if sudo journalctl --until "7 days ago" --quiet --no-pager | grep -q .; then
	echo -e "${GREEN}You have outdated journal entries${NC}"

	#log
	echo "$(date): Outdated journal entries found" | sudo tee -a "$log_file" > /dev/null

	#deleting journal entries older than 7 days
	while true; do
		read -p "Delete outdated journal entries? (older than 7 days) [Y/n] " -r
		echo "" 
		
		if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
			echo -e "${RED}Deleting journal entries older than 7 days...${NC}"

			for i in {0..100}; do
				
				if [[ $i -eq 10 ]]; then
					sudo journalctl --vacuum-time=7d &> /dev/null 
				fi

				filled=$((i / 2))
				empty=$((50 - filled))

				printf "\r${GREEN}▌%-50s▐${NC} %d%%" "$(printf '█%.0s' $(seq 1 $filled))$([[ $empty -gt 0 ]] && printf '░%.0s' $(seq 1 $empty))" "$i" 

			done

			#log
			echo "$(date): Deleted outdated journal entries" | sudo tee -a "$log_file" > /dev/null

			sleep 0.3
			echo ""
			echo -e "${RED}Done${NC}"
			break
		elif [[ $REPLY =~ ^[Nn]$ ]]; then
			echo -e "${RED}You have selected to keep outdated journal entries${NC}"
			
			#log
			echo "$(date): User selected to keep outdated journal entries" | sudo tee -a "$log_file" > /dev/null
			break
		else 
			echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
		fi
	done

else 
	echo -e "${GREEN}No outdated journal entries${NC}"

	#log
	echo "$(date): No outdated journal entries found" | sudo tee -a "$log_file" > /dev/null
fi
echo ""
echo ""


#tmp files cleanup
echo -e "${BLUE}Checking for temporary files...${NC}"
sleep 1
echo ""

#log
echo "$(date): Checked for temporary files" | sudo tee -a "$log_file" > /dev/null

#check for temporary files
if sudo find /tmp /var/tmp -type f 2> /dev/null | grep -q .; then
	echo -e "${GREEN}temporary files:${NC}"
	sudo du -h -sh /var/tmp | awk '{print "    "$0}'
	sudo du -h -sh /tmp/ | awk '{print "    "$0}'
	echo ""

	#log
	echo "$(date): Temporary files found" | sudo tee -a "$log_file" > /dev/null
	
	#Deleting temporary files
	while true; do
		read -p "Delete temporary files? [Y/n] " -r
		echo "" 
		
		if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
			echo -e "${RED}Deleting temporary files...${NC}"

			tmp_files=($(sudo find /tmp /var/tmp -type f 2> /dev/null))
			all_tmp_files=${#tmp_files[@]}
			removed_tmp_files=0
		

			for file in "${tmp_files[@]}"; do
				sudo rm -f "$file"
				removed_tmp_files=$((removed_tmp_files + 1))
				
				percent_tmp_removed=$((removed_tmp_files * 100 / all_tmp_files))

				filled=$((percent_tmp_removed / 2))
				empty=$((50 - filled))

				printf "\r${GREEN}▌%-50s▐${NC} %d%%" "$(printf '█%.0s' $(seq 1 $filled))$([[ $empty -gt 0 ]] && printf '░%.0s' $(seq 1 $empty))" "$percent_tmp_removed"

			done

			#log
			echo "$(date): Deleted temporary files" | sudo tee -a "$log_file" > /dev/null

			sleep 0.3
			echo ""
			echo -e "${RED}Done${NC}"

			break
		elif [[ $REPLY =~ ^[Nn]$ ]]; then
			echo -e "${RED}You have selected to keep temporary files${NC}"
			
			#log
			echo "$(date): User selected to keep temporary files" | sudo tee -a "$log_file" > /dev/null

			break
		else 
			echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
		fi
	done
else
	echo -e "${GREEN}You don't have any temporary files${NC}"

	#log
	echo "$(date): No temporary files found" | sudo tee -a "$log_file" > /dev/null
fi
echo""
echo""


#cache cleanup
echo -e "${BLUE}Checking for cache...${NC}"
sleep 1
echo ""

#log
echo "$(date): Checked for cache" | sudo tee -a "$log_file" > /dev/null	

#check for cache
if sudo find ~/.cache ~/.local/share/Trash /var/cache/apt/archives/ -type f | grep -q .; then

	echo -e "${GREEN}Cache:${NC}"
	sudo du -sh /var/cache/apt/archives/ | awk '{print "    "$0}'
	sudo du -sh ~/.cache | awk '{print "    "$0}'
	sudo du -sh ~/.local/share/Trash | awk '{print "    "$0}'
	echo ""

	#log
	echo "$(date): Cache found" | sudo tee -a "$log_file" > /dev/null
	
	#Deleting cache
	while true; do
		read -p "Delete cache? [Y/n] " -r
		echo "" 
		
		if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
			echo -e "${RED}Deleting cache...${NC}"

			cache_files=($(sudo find ~/.cache ~/.local/share/Trash /var/cache/apt/archives/ -type f ))
			all_cache_files=${#cache_files[@]}
			removed_cache=0

			for file in "${cache_files[@]}"; do
				sudo rm -f "$file"
				removed_cache=$((removed_cache + 1))
				
				percent_cache_removed=$((removed_cache * 100 / all_cache_files))

				filled=$((percent_cache_removed / 2))
				empty=$((50 - filled))

				printf "\r${GREEN}▌%-50s▐${NC} %d%%" "$(printf '█%.0s' $(seq 1 $filled))$([[ $empty -gt 0 ]] && printf '░%.0s' $(seq 1 $empty))" "$percent_cache_removed" 

			done

			#log
			echo "$(date): Deleted cache" | sudo tee -a "$log_file" > /dev/null
			
			sleep 0.3
			echo ""
			echo -e "${RED}Done${NC}"
			break

		elif [[ $REPLY =~ ^[Nn]$ ]]; then
			echo -e "${RED}You have selected to keep cache${NC}"
			
			#log
			echo "$(date): User selected to keep cache" | sudo tee -a "$log_file" > /dev/null

			break
			
		else 
			echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
		fi
	done
else 
	echo -e "${RED}You don't have any cache${NC}"

	#log
	echo "$(date): No cache found" | sudo tee -a "$log_file" > /dev/null
fi
echo ""
echo ""

#performing system update

echo -e "${BLUE}updating package lists...${NC}"
echo ""
sudo apt update
echo ""

#log
echo "$(date): Updated package lists" | sudo tee -a "$log_file" > /dev/null

echo -e "${BLUE}Checking for available updates...${NC}"
echo ""
echo -e "${GREEN}The following packages can be upgraded:${NC}"
sudo apt list --upgradable | awk '{print "    "$0}'
echo ""

#log
echo "$(date): queried upgradable packages" | sudo tee -a "$log_file" > /dev/null

while true; do
	read -p "Upgrade system? [Y/n] " -r
	echo "" 
	
	if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
		echo -e "${RED}upgrading system...${NC}"
		sudo apt full-upgrade -y
		echo ""
		echo ""

		#log
		echo "$(date): System upgraded" | sudo tee -a "$log_file" > /dev/null
		
		while true; do
			read -p "System upgrade done. Cleanup outdated packages? [Y/n] " -r
			echo "" 
			
			if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
				echo -e "${RED}Removing outdated packages..${NC}"
				sudo apt autoremove -y
				echo ""
				echo ""

				#log
				echo "$(date): Removed outdated packages" | sudo tee -a "$log_file" > /dev/null
				
				#reboot
				while true; do
					read -p "Outdated packages removed. Reboot system now? [Y/n] " -r
					echo "" 
					
					if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
						echo -e "${RED}Rebooting...${NC}"

						#log
						echo "$(date): System reboot" | sudo tee -a "$log_file" > /dev/null

						sleep 0.5
						sudo systemctl reboot -i
						break
					elif [[ $REPLY =~ ^[Nn]$ ]]; then
						echo -e "${RED}Reboot cancelled. Exiting...${NC}"

						#log
						echo "$(date): User stopped system reboot" | sudo tee -a "$log_file" > /dev/null
						sleep 1

						break
					else 
						echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
					fi
				done
				
				break
			elif [[ $REPLY =~ ^[Nn]$ ]]; then
				echo -e "${RED}Cleanup cancelled. Exiting...${NC}"

				#log
				echo "$(date): User selected to keep outdated packages" | sudo tee -a "$log_file" > /dev/null

				sleep 1
				break
			else 
				echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
			fi
		done
		break
	elif [[ $REPLY =~ ^[Nn]$ ]]; then
		echo -e "${RED}Upgrade cancelled. Exiting...${NC}"
		echo ""

		
		#log
		echo "$(date): User stopped system upgrade" | sudo tee -a "$log_file" > /dev/null

		sleep 1
		break
	else 
		echo -e "${RED}Invalid input $REPLY. Please try again${NC}"
	fi
done

#log
echo "$(date): system_cleanup script execution complete" | sudo tee -a "$log_file" > /dev/null

