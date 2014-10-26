#!/bin/bash
#
# This file has been tested as shell provisioner on vagrant box :
# chef/centos-6.5     (virtualbox, 1.0.0)
#
PATH_TO_ORA_INST_FILES=/vagrant/ora_inst_files
cd ${PATH_TO_ORA_INST_FILES}
 
for file_to_unzip in `ls *.zip`
do
  unzip -o ${file_to_unzip}
done

su - oracle

cat ${HOME}/.bash_profile

${PATH_TO_ORA_INST_FILES}/database/runInstaller -silent \
 -responseFile /vagrant/ora_11_2_db_install.rsp
 