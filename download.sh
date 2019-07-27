!/bin/bash
echo "Inside customscript.sh"

echo "Adding a new user"
useradd oracle

su - oracle
echo "Get new user home directory"

eval echo "~$different_user" 

pwd

ls -ltr

curl -s https://raw.githubusercontent.com/typekpb/oradown/master/oradown.sh  | bash -s -- --cookie=accept-weblogicserver-server --username=$1 --password=$2 http://download.oracle.com/otn/nt/middleware/12c/12213/fmw_12.2.1.3.0_wls_Disk1_1of1.zip

ls -ltr
