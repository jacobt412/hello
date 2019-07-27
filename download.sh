!/bin/bash
echo "Inside customscript.sh"

echo "Adding a new user"
useradd oracle

#su - oracle
echo "Get new user home directory"
eval echo "~oracle" 

ora_user_home = $(getent passwd oracle|cut -d\: -f 6);

mkdir -p $ora_user_home/installables
cd $ora_user_home/installables

echo "inside installable dir"

pwd

ls -ltr

curl -s https://raw.githubusercontent.com/typekpb/oradown/master/oradown.sh  | bash -s -- --cookie=accept-weblogicserver-server --username=$1 --password=$2 http://download.oracle.com/otn/nt/middleware/12c/12213/fmw_12.2.1.3.0_wls_Disk1_1of1.zip

ls -ltr
