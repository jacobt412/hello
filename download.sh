
#!/bin/bash

#Function to output message to StdErr
echo_stderr ()
{
    echo "$@" >&2
}


cleanup()
{
    echo "Cleaning up temporary files..."
    rm -rf /u01/app/jdk/jdk-8u221-linux-x64.tar.gz
    rm -rf /u01/app/wls/fmw_12.2.1.3.0_wls_Disk1_1of1.zip
    rm -rf $WLS_JAR
    echo "Cleanup completed."
}

create_oraInstlocTemplate()
{
    echo "creating Install Location Template..."

    cat <<EOF >/u01/app/wls/silent-template/oraInst.loc.template
inventory_loc=[INSTALL_PATH]
inst_group=[GROUP]
EOF
}

create_oraResponseTemplate()
{

    echo "creating Response Template..."

    cat <<EOF >/u01/app/wls/silent-template/response.template
[ENGINE]

#DO NOT CHANGE THIS.
Response File Version=1.0.0.0.0

[GENERIC]

#Set this to true if you wish to skip software updates
DECLINE_AUTO_UPDATES=true

#My Oracle Support User Name
MOS_USERNAME=

#My Oracle Support Password
MOS_PASSWORD=<SECURE VALUE>

#If the Software updates are already downloaded and available on your local system, then specify the path to the directory where these patches are available and set SPECIFY_DOWNLOAD_LOCATION to true
AUTO_UPDATES_LOCATION=

#Proxy Server Name to connect to My Oracle Support
SOFTWARE_UPDATES_PROXY_SERVER=

#Proxy Server Port
SOFTWARE_UPDATES_PROXY_PORT=

#Proxy Server Username
SOFTWARE_UPDATES_PROXY_USER=

#Proxy Server Password
SOFTWARE_UPDATES_PROXY_PASSWORD=<SECURE VALUE>

#The oracle home location. This can be an existing Oracle Home or a new Oracle Home
ORACLE_HOME=[INSTALL_PATH]/Oracle/Middleware/Oracle_Home

#Set this variable value to the Installation Type selected. e.g. WebLogic Server, Coherence, Complete with Examples.
INSTALL_TYPE=WebLogic Server

#Provide the My Oracle Support Username. If you wish to ignore Oracle Configuration Manager configuration provide empty string for user name.
MYORACLESUPPORT_USERNAME=

#Provide the My Oracle Support Password
MYORACLESUPPORT_PASSWORD=<SECURE VALUE>

#Set this to true if you wish to decline the security updates. Setting this to true and providing empty string for My Oracle Support username will ignore the Oracle Configuration Manager configuration
DECLINE_SECURITY_UPDATES=true

#Set this to true if My Oracle Support Password is specified
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false

#Provide the Proxy Host
PROXY_HOST=

#Provide the Proxy Port
PROXY_PORT=

#Provide the Proxy Username
PROXY_USER=

#Provide the Proxy Password
PROXY_PWD=<SECURE VALUE>

#Type String (URL format) Indicates the OCM Repeater URL which should be of the format [scheme[Http/Https]]://[repeater host]:[repeater port]
COLLECTOR_SUPPORTHUB_URL=


EOF
}

function create_oraUninstallResponseTemplate()
{
    echo "creating Uninstall Response Template..."

    cat <<EOF >/u01/app/wls/silent-template/uninstall-response.template
[ENGINE]

#DO NOT CHANGE THIS.
Response File Version=1.0.0.0.0

[GENERIC]

#This will be blank when there is nothing to be de-installed in distribution level
SELECTED_DISTRIBUTION=WebLogic Server~[WLSVER]

#The oracle home location. This can be an existing Oracle Home or a new Oracle Home
ORACLE_HOME=[INSTALL_PATH]/Oracle/Middleware/Oracle_Home/

EOF
}


installWLS()
{
    # Using silent file templates create silent installation required files
    
    echo "Creating silent files for installation from silent file templates..."

    sed 's@\[INSTALL_PATH\]@'"$INSTALL_PATH"'@' ${SILENT_FILES_DIR}/uninstall-response.template > ${SILENT_FILES_DIR}/uninstall-response
    sed -i 's@\[WLSVER\]@'"$WLS_VER"'@' ${SILENT_FILES_DIR}/uninstall-response
    sed 's@\[INSTALL_PATH\]@'"$INSTALL_PATH"'@' ${SILENT_FILES_DIR}/response.template > ${SILENT_FILES_DIR}/response
    sed 's@\[INSTALL_PATH\]@'"$INSTALL_PATH"'@' ${SILENT_FILES_DIR}/oraInst.loc.template > ${SILENT_FILES_DIR}/oraInst.loc
    sed -i 's@\[GROUP\]@'"$USER_GROUP"'@' ${SILENT_FILES_DIR}/oraInst.loc

    echo "Created files required for silent installation at $SILENT_FILES_DIR"

    export UNINSTALL_SCRIPT=$INSTALL_PATH/Oracle/Middleware/Oracle_Home/oui/bin/deinstall.sh
    if [ -f "$UNINSTALL_SCRIPT" ]
    then
            currentVer=`. $INSTALL_PATH/Oracle/Middleware/Oracle_Home/wlserver/server/bin/setWLSEnv.sh 1>&2 ; java weblogic.version |head -2`
            echo "#########################################################################################################"
            echo "Uninstalling already installed version :"$currentVer
            runuser -l oracle -c "$UNINSTALL_SCRIPT -silent -responseFile ${SILENT_FILES_DIR}/uninstall-response"
            sudo rm -rf $INSTALL_PATH/*
            echo "#########################################################################################################"
    fi

    echo "---------------- Installing WLS ${WLS_JAR} ----------------"
    echo $JAVA_HOME/bin/java -d64 -jar  ${WLS_JAR} -silent -invPtrLoc ${SILENT_FILES_DIR}/oraInst.loc -responseFile ${SILENT_FILES_DIR}/response -novalidation
    runuser -l oracle -c "$JAVA_HOME/bin/java -d64 -jar  ${WLS_JAR} -silent -invPtrLoc ${SILENT_FILES_DIR}/oraInst.loc -responseFile ${SILENT_FILES_DIR}/response -novalidation"

    # Check for successful installation and version requested
    if [[ $? == 0 ]];
    then
      echo "Weblogic Server Installation is successful"
    else

      echo_stderr "Installation is not successful"
      exit 1
    fi
    echo "#########################################################################################################"                                          

}


#main

export otnusername=$1
export otnpassword=$2
export WLS_VER="12.2.1.3.0"

#add oracle group and user

echo "Adding oracle user and group..."
groupname="oracle"
username="oracle"

USER_GROUP=${groupname}

sudo groupadd $groupname
sudo useradd -g $groupname $username

#create custom directory for setting up wls and jdk
sudo mkdir -p /u01/app/jdk
sudo mkdir -p /u01/app/wls
sudo rm -rf /u01/app/jdk/*
sudo rm -rf /u01/app/wls/*

#Download Weblogic install jar from OTN
echo "Downloading weblogic install kit from OTN..."
curl -s https://raw.githubusercontent.com/typekpb/oradown/master/oradown.sh  | bash -s -- --cookie=accept-weblogicserver-server --username="${otnusername}" --password="${otnpassword}" http://download.oracle.com/otn/nt/middleware/12c/12213/fmw_12.2.1.3.0_wls_Disk1_1of1.zip

#download jdk from OTN
echo "Downloading jdk from OTN..."
curl -s https://raw.githubusercontent.com/typekpb/oradown/master/oradown.sh  | bash -s -- --cookie=accept-weblogicserver-server --username="${otnusername}" --password="${otnpassword}" https://download.oracle.com/otn/java/jdk/8u221-b11/230deb18db3e4014bb8e3e8324f81b43/jdk-8u221-linux-x64.tar.gz

sudo chown -R $username:$groupname /u01/app

sudo mv fmw_12.2.1.3.0_wls_Disk1_1of1.zip /u01/app/wls/fmw_12.2.1.3.0_wls_Disk1_1of1.zip
sudo mv jdk-8u221-linux-x64.tar.gz /u01/app/jdk/jdk-8u221-linux-x64.tar.gz

echo "extracting and setting up jdk..."
sudo tar -zxvf /u01/app/jdk/jdk-8u221-linux-x64.tar.gz --directory /u01/app/jdk/
sudo chown -R $username:$groupname /u01/app/jdk

export JAVA_HOME=/u01/app/jdk/jdk1.8.0_221
export PATH=$JAVA_HOME/bin:$PATH

java -version

if [ $? == 0 ];
then
    echo "JAVA HOME set succesfully."
else
    echo_stderr "Failed to set JAVA_HOME. Please check logs and re-run the setup"
    exit 1
fi

echo "Installing zip unzip wget vnc-server"
sudo yum install -y zip unzip wget vnc-server

echo "unzipping fmw_12.2.1.3.0_wls_Disk1_1of1.zip..."
sudo unzip -o /u01/app/wls/fmw_12.2.1.3.0_wls_Disk1_1of1.zip -d /u01/app/wls/

export SILENT_FILES_DIR=/u01/app/wls/silent-template
sudo mkdir -p $SILENT_FILES_DIR
sudo rm -rf /u01/app/wls/silent-template/*
sudo chown -R $username:$groupname /u01/app/wls

export INSTALL_PATH=/u01/app/wls/install
export WLS_JAR="/u01/app/wls/fmw_12.2.1.3.0_wls.jar"

mkdir -p /u01/app/wls/install
sudo chown -R $username:$groupname /u01/app/wls/install

create_oraInstlocTemplate
create_oraResponseTemplate
create_oraUninstallResponseTemplate

installWLS

cleanup
