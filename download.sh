
#!/bin/sh
echo "Inside customscript.sh"

get_ora_home() {
  local user_home; 
  user_home="$(getent passwd "$1")" || return
  echo $result | cut -d : -f 6
}

echo "Adding a new user"
useradd -m oracle

#su - oracle
echo "Get new user home directory"
#eval echo "~oracle" 

ora_user_home = "$(get_ora_home oracle)"

echo "oracle home is '$ora_user_home'"

mkdir -p $ora_user_home/installables
cd $ora_user_home/installables

echo "======inside installable dir======"

pwd

ls -ltr

curl -s https://raw.githubusercontent.com/typekpb/oradown/master/oradown.sh  | bash -s -- --cookie=accept-weblogicserver-server --username=$1 --password=$2 http://download.oracle.com/otn/nt/middleware/12c/12213/fmw_12.2.1.3.0_wls_Disk1_1of1.zip

ls -ltr

