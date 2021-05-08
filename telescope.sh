#!/bin/bash
							# Made with <3 by jagelit0
#Colors
y='\e[1;33m'
r='\e[1;31m'
g='\e[1;32m'
nc='\e[0m'

#Vars
opt=$2
ip=$1
usage=$(echo -e "$r" "[!] Usage: ./telescope.sh <IP> (options: -d|--default, -n|--no-ping)" "$nc")

#Check
Check(){
if [ $(id -u) != 0 ]; then
	echo -e "$r" "[!] Please, execute the script as sudo [!]" "$nc"
	exit 1
elif
	[ -z "$ip" ] || [ -z "$opt" ]; then
	echo "$usage"
	exit 1
fi
}

#TTL
whichOS(){
        ttl=$(ping -c 3 "$ip" | grep ttl | cut -d ' ' -f 6 | cut -d '=' -f2 | uniq)
                if [[ "$ttl" -ge 33 && "$ttl" -le 70 ]]; then
                                echo -e "$g" "[*] O.S:" "$r""Linux" "$nc"
                        elif [[ "$ttl" -ge 71 && "$ttl" -le 130 ]]; then
                                echo -e "$g" "[*] O.S:" "$r""Windows" "$nc"
                        elif [[ "$ttl" -ge 131 && "$ttl" -le 255 ]]; then
                                echo -e "$g" "[*] O.S:" "$r""Other" "$nc"
                        elif [ -z "$ttl" ];then
                                echo -e "$r" "Can't reach the host" "$nc"
				echo -e "$r" "Execute the script with -n|--no-ping" "$nc"
                fi
}

#Scans
doMagic(){
mkdir scans && cd scans
echo -e ""
echo -e "$y" "                 Looking through the telescope..." "$nc"
echo -e ""
whichOS
nmap -sT --min-rate 5000 -p- --open "$ip" -oG nmap.tmp &>/dev/null
ports="$(cat nmap.tmp | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',' > openports.tmp)"
portsToScan=$(cat openports.tmp)
nmap -sC -sV -T4 -p"$portsToScan" "$ip" -oN tcp_scan &>/dev/null
checkPorts=$(cat tcp_scan | grep open | cut -d ' ' -f1,5 | sed 's/\/tcp/ /' | sed 's/^/     /' )
echo -e "$g" "[+] Open ports:" "$nc""$r""\n$checkPorts" "$nc"
echo -e "$y" "[*] Starting deep scans..." "$nc"
nmap --script vuln* -sV -v -T4 -p"$portsToScan" "$ip" -oN full_tcp_scan &>/dev/null
rm *.tmp
echo -e "$g" "[!] All TCP scans completed, you can check the results!" "$nc"
echo -e "$y" "[*] Running UDP scan..." "$nc"
echo -e "$r" "    This may take a while... Be patient." "$nc"
nmap -sV -sU -p- --open --min-rate 5000 "$ip" -oN udp_scan &>/dev/null
echo -e "$g" "[+] All scans completed!" "$nc"
}

#nmap_Pn
nmap_Pn(){
mkdir scans && cd scans
echo -e ""
echo -e "$y" "                 Looking through the telescope..." "$nc"
echo -e ""
nmap -sT -Pn --min-rate 5000 -p- --open "$ip" -oG nmap.tmp &>/dev/null
ports="$(cat nmap.tmp | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',' > openports.tmp)"
portsToScan=$(cat openports.tmp)
nmap -sC -sV -T4 -Pn -p"$portsToScan" "$ip" -oN tcp_scan &>/dev/null
checkPorts=$(cat tcp_scan | grep open | cut -d ' ' -f1,5 | sed 's/\/tcp/ /' | sed 's/^/     /' )
echo -e "$g" "[+] Open ports:" "$nc""$r""\n$checkPorts" "$nc"
echo -e "$y" "[*] Starting deep scans..." "$nc"
nmap --script vuln* -sV -v -Pn -T4 -p"$portsToScan" "$ip" -oN full_tcp_scan &>/dev/null
rm *.tmp
echo -e "$g" "[!] All TCP scans completed, you can check the results!" "$nc"
echo -e "$y" "[*] Running UDP scan..." "$nc"
echo -e "$r" "    This may take a while... Be patient." "$nc"
nmap -Pn -sV -sU -n --min-rate 5000 "$ip" -oN udp_scan &>/dev/null
echo -e "$g" "[+] All scans completed!" "$nc"
}

#Main
Check
case "$2" in
	-n|--no-ping)
	nmap_Pn
	;;
	-d|--default)
	doMagic
	;;
esac
echo -e "$g" "[+] The results have been saved in""$nc""$y" "/scans""$nc"

exit 0
