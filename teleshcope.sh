#!/bin/bash
							# Made with <3 by jagelit0
#Colors
y='\e[1;33m'
r='\e[1;31m'
g='\e[1;32m'
nc='\e[0m'

#Vars
OPT=$2
MACHINE=$1
usage=$(echo -e "$r" "[!] Usage: ./teleshcope.sh <IP> (Options: -d|--default, -n|--no-ping, -h|--help)" "$nc")

#Banner
Banner(){
        echo -e ""
        echo -e "$y" "                 Looking through the teleshcope..." "$nc"
        echo -e ""
}

#Check
Check(){
if [ $(id -u) != 0 ]; then
	echo -e "$r" "[!] Please, execute the script as sudo [!]" "$nc"
	exit 1
elif
	[ -z "$MACHINE" ] || [ -z "$OPT" ]; then
	echo "$usage"
	exit 1
fi
}

#TTL
whichOS(){
        ttl=$(ping -c 3 "$MACHINE" | grep ttl | cut -d ' ' -f 6 | cut -d '=' -f2 | uniq)
                if [[ "$ttl" -ge 33 && "$ttl" -le 70 ]]; then
                                echo -e "$g" "[*] O.S.:" "$r""Linux" "$nc"
                        elif [[ "$ttl" -ge 71 && "$ttl" -le 130 ]]; then
                                echo -e "$g" "[*] O.S.:" "$r""Windows" "$nc"
                        elif [[ "$ttl" -ge 131 && "$ttl" -le 255 ]]; then
                                echo -e "$g" "[*] O.S.:" "$r""Other" "$nc"
                        elif [ -z "$ttl" ]; then
                                echo -e "$r" "Can't reach the host" "$nc"
				echo -e "$r" "Execute the script with -n|--no-ping" "$nc"
                fi
}

#Scans
doMagic(){
    mkdir teleshcope_scans/
    Banner
    whichOS
    nmap -sT --min-rate 5000 -p- --open "$MACHINE" -oG teleshcope_scans/nmap.tmp &>/dev/null
    ports="$(cat teleshcope_scans/nmap.tmp | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',' > teleshcope_scans/openports.tmp)"
    portsToScan=$(cat teleshcope_scans/openports.tmp)
    nmap -sC -sV -T4 -p"$portsToScan" "$MACHINE" -oN teleshcope_scans/tcp_scan &>/dev/null
    checkPorts=$(cat teleshcope_scans/tcp_scan | grep "open" | awk '{print $1,$3}' | sed  's/\/tcp//' | sed -e 's/^/    -> /' )
    echo -e "$g" "[+] Open ports:" "$nc""$r""\n$checkPorts" "$nc"
    echo -e "$y" "[*] Starting deep scans..." "$nc"
    nmap --script vuln* -sV -v -T5 -p"$portsToScan" "$MACHINE" -oN teleshcope_scans/full_tcp_scan &>/dev/null
    rm teleshcope_scans/*.tmp
    echo -e "$g" "[!] All TCP scans completed, you can check the results!" "$nc"
    echo -e "$y" "[*] Running UDP scan..." "$nc"
    echo -e "$r" "    This may take a while... Be patient." "$nc"
    nmap -sVU --min-rate 5000 -T4 "$MACHINE" -oN teleshcope_scans/udp_scan &>/dev/null
    echo -e "$g" "[+] All scans completed!" "$nc"
}

#nmap_Pn
nmap_Pn(){
    mkdir teleshcope_scans/
    Banner
    nmap -sT -Pn --min-rate 5000 -p- --open "$MACHINE" -oG teleshcope_scans/nmap.tmp &>/dev/null
    ports="$(cat teleshcope_scans/nmap.tmp | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',' > teleshcope_scans/openports.tmp)"
    portsToScan=$(cat scans/openports.tmp)
    nmap -sC -sV -T5 -Pn -p"$portsToScan" "$MACHINE" -oN teleshcope_scans/tcp_scan &>/dev/null
    checkPorts=$(cat teleshcope_scans/tcp_scan | grep "open" | awk '{print $1,$3}' | sed  's/\/tcp//' | sed -e 's/^/     -> /' )
    echo -e "$g" "[+] Open ports:" "$nc""$r""\n$checkPorts" "$nc"
    echo -e "$y" "[*] Starting deep scans..." "$nc"
    nmap --script vuln* -sV -v -Pn -T5 -p"$portsToScan" "$MACHINE" -oN teleshcope_scans/full_tcp_scan &>/dev/null
    rm teleshcope_scans/*.tmp
    echo -e "$g" "[!] All TCP scans completed, you can check the results!" "$nc"
    echo -e "$y" "[*] Running UDP scan..." "$nc"
    echo -e "$r" "    This may take a while... Be patient." "$nc"
    nmap -Pn -sVU --min-rate 5000 -T4 "$MACHINE" -oN teleshcope_scans/udp_scan &>/dev/null
    echo -e "$g" "[+] All scans completed!" "$nc"
}

#Main
Check
while true; do
case "$2" in
        -n | --no-ping ) nmap_Pn; exit 0 ;;
        -d | --default ) doMagic; exit 0 ;;
        -h | --help ) echo -e $usage; exit 0 ;;
        -- ) shift; break ;;
        * )  echo -e "$r"" [!] Unrecognizable option!\n Options: -d|--default, -n|--no-ping, -h|--help" "$nc"; exit 1 ;;
esac
done

echo -e "$g" "[+] The results have been saved in""$nc""$y" "/teleshcope_scans""$nc"

exit 0
