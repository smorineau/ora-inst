#!/bin/bash
#
# This file has been tested as shell provisioner on vagrant box :
# chef/centos-6.5     (virtualbox, 1.0.0)
#
PATH_TO_ORA_INST_FILES=/vagrant/ora_inst_files
cd ${PATH_TO_ORA_INST_FILES}
unzip -o linux_11gR2_database_1of2.zip
unzip -o linux.x64_11gR2_database_2of2.zip