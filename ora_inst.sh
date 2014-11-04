#!/bin/bash
#
# This file has been tested as shell provisioner on vagrant box :
# chef/centos-6.5     (virtualbox, 1.0.0)
#
WORKING_DIR=`cd $(dirname $0) && pwd -P && cd - > /dev/null`
export WORKING_DIR
echo WORKING_DIR : ${WORKING_DIR}

echo "*********************************************************"
echo " ===> Installation files deployment "
echo "*********************************************************"
PATH_TO_ORA_INST_FILES=/vagrant/ora_inst_files
#cd ${PATH_TO_ORA_INST_FILES}

if [[ -d ${PATH_TO_ORA_INST_FILES}/database ]]
then
  echo "Installation files already deployed."
  echo "Proceeding..."
else
  for file_to_unzip in `ls *.zip`
  do
    unzip -o ${file_to_unzip}
  done
fi

echo "*********************************************************"
echo " ===> Oracle Software Installation "
echo "*********************************************************"

# Installing DB (the runInstaller must be run as oracle owner user)
date
echo "Invoking Oracle Installer..."
su oracle -c "${PATH_TO_ORA_INST_FILES}/database/runInstaller -silent -noconfig -responseFile /vagrant/ora_11_2_db_install.rsp"

while [[ ${?} == 0 ]]
do
   sleep 10s
   ps -u oracle >/dev/null	# Check if oracle owned process has terminated.
done
date

# Setting env variables
ORACLE_ROOT=/u01/app
ORACLE_BASE=${ORACLE_ROOT}/oracle
export ORACLE_BASE
ORACLE_INVENTORY=${ORACLE_ROOT}/oraInventory
export ORACLE_INVENTORY
ORACLE_HOME=${ORACLE_BASE}/product/11.2.0/dbhome_1
export ORACLE_HOME

echo "Running additional scripts Oracle (orainstRoot.sh and root.sh)..."
${ORACLE_INVENTORY}/orainstRoot.sh
${ORACLE_HOME}/root.sh

echo "Completed"