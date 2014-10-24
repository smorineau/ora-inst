#!/bin/bash
#
# This file has been tested as shell provisioner on vagrant box :
# chef/centos-6.5     (virtualbox, 1.0.0)
#
function isinstalled {
  if yum list installed "$1" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}
#
function AddIfNotExists {
  if grep -Fxq "$1" "$2"
  then
      :
  else
      echo "$1" >> "$2"
  fi
}
#
echo "********* Starting Pre-installation Tasks *********"
#
echo ""
echo "==> Checking Hardware Requirements"
echo "CPU"
uname -m
echo "Memory and Swap"
grep MemTotal /proc/meminfo
grep SwapTotal /proc/meminfo
echo "Disk space"
echo "tmp space"
df -h /tmp
echo "overall"
df -h
#
echo ""
echo "==> Checking Software Requirements"
echo " * Operating System Requirements"
cat /proc/version
echo " * Kernel Requirements"
uname -r
echo " * Package Requirements"
#if isinstalled $package; then echo "installed"; else echo "not installed"; fi
PACKAGES="binutils
compat-libcap1
compat-libstdc++-33.x86_64
compat-libstdc++-33.i686
gcc
gcc-c++
glibc.x86_64
glibc.i686
glibc-devel.x86_64
glibc-devel.i686
ksh
libgcc.x86_64
libgcc.i686
libstdc++.x86_64
libstdc++.i686
libstdc++-devel.x86_64
libstdc++-devel.i686
libaio.x86_64
libaio.i686
libaio-devel.x86_64
libaio-devel.i686
make
sysstat
unzip"

for package in ${PACKAGES}
do
    echo "** "${package}
    if isinstalled ${package}
    then
        echo "Installed"
    else
        echo "Not installed, installing..."
        yum -y install ${package}
    fi
done
# rpm -q binutils \
# compat-libcap1 \
# compat-libstdc++-33 \
# gcc \
# gcc-c++ \
# glibc \
# glibc-devel \
# ksh \
# libgcc \
# libstdc++ \
# libstdc++-devel \
# libaio \
# libaio-devel \
# make \
# sysstat
#
#yum -y install glibc-devel
#
echo ""
echo "==> Creating the Database User Accounts and Groups"
echo "Creating user groups..."
groupadd -g 501 oinstall
groupadd -g 502 dba
echo "Creating oracle software owner user"
/usr/sbin/useradd -c 'Oracle software owner' -d /home/oracle \
                  -g oinstall -G dba -m -u 501 -s /bin/bash oracle
# !CAUTION! below command creates a passwordless user!
# An actual password is to be setup manually
passwd -f -u oracle
#
echo ""
echo "==> Configuring the Kernel Parameter Settings"
echo "Setting kernel.sem=250 32000 100 128"
/sbin/sysctl -w "kernel.sem=250 32000 100 128"
echo "Setting net.ipv4.ip_local_port_range=9000 65500"
/sbin/sysctl -w "net.ipv4.ip_local_port_range=9000 65500"
if [ $(/sbin/sysctl -n fs.aio-max-nr) -lt 1048576 ]
then
    echo "Setting fs.aio-max-nr=1048576"
    /sbin/sysctl -w fs.aio-max-nr=1048576
fi
if [ $(/sbin/sysctl -n fs.file-max) -lt 681574 ]
then
    echo "Setting fs.file-max=681574"
    /sbin/sysctl -w fs.file-max=681574
fi
if [ $(/sbin/sysctl -n kernel.shmall) -lt 2097152 ]
then
    echo "Setting kernel.shmall=2097152"
    /sbin/sysctl -w kernel.shmall=2097152
fi
if [ $(/sbin/sysctl -n kernel.shmmax) -lt 4294967295 ]
then
    echo "Setting kernel.shmmax=4294967295"
    /sbin/sysctl -w kernel.shmmax=4294967295
fi
if [ $(/sbin/sysctl -n kernel.shmmni) -lt 4096 ]
then
    echo "Setting kernel.shmmni=4096"
    /sbin/sysctl -w kernel.shmmni=4096
fi
if [ $(/sbin/sysctl -n net.core.rmem_default) -lt 4194304 ]
then
    echo "Setting net.core.rmem_default=4194304"
    /sbin/sysctl -w net.core.rmem_default=4194304
fi
if [ $(/sbin/sysctl -n net.core.rmem_max) -lt 4194304 ]
then
    echo "Setting net.core.rmem_max=4194304"
    /sbin/sysctl -w net.core.rmem_max=4194304
fi
if [ $(/sbin/sysctl -n net.core.wmem_default) -lt 262144 ]
then
    echo "Setting net.core.wmem_default=262144"
    /sbin/sysctl -w net.core.wmem_default=262144
fi
if [ $(/sbin/sysctl -n net.core.wmem_max) -lt 1048576 ]
then
    echo "Setting net.core.wmem_max=1048576"
    /sbin/sysctl -w net.core.wmem_max=1048576
fi
#
echo ""
echo "==> Setting Shell Limits for the Oracle User"
echo "Appending in /etc/security/limits.conf ..."
echo "oracle          soft    nproc           2047"  >> /etc/security/limits.conf
echo "oracle          hard    nproc           16384" >> /etc/security/limits.conf
echo "oracle          soft    nofile          1024"  >> /etc/security/limits.conf
echo "oracle          hard    nofile          65536" >> /etc/security/limits.conf

FILE_TO_CHECK="/etc/pam.d/login"
STRING_TO_ADD="session required /lib64/security/pam_limits.so"
AddIfNotExists "${STRING_TO_ADD}" "${FILE_TO_CHECK}"
STRING_TO_ADD="session required pam_limits.so"
AddIfNotExists "${STRING_TO_ADD}" "${FILE_TO_CHECK}"
FILE_TO_CHECK="/etc/profile"
STRING_TO_ADD="if [ \$USER = \"oracle\" ]; then
    if [ \$SHELL = \"/bin/ksh\" ]; then
        ulimit -p 16384
        ulimit -n 65536
    else
        ulimit -u 16384 -n 65536
    fi
fi"
echo "${STRING_TO_ADD}" >> "${FILE_TO_CHECK}"
#
echo ""
echo "==> Creating Required Directories"
ORACLE_ROOT=/u01/app/
mkdir -p ${ORACLE_ROOT}
chown -R oracle:oinstall ${ORACLE_ROOT}
chmod -R 775 ${ORACLE_ROOT}
echo "* Oracle Base Directory"
ORACLE_BASE=${ORACLE_ROOT}/oracle
mkdir -p ${ORACLE_BASE}
chown -R oracle:oinstall ${ORACLE_BASE}
chmod -R 775 ${ORACLE_BASE}
echo "* Oracle Inventory Directory"
ORACLE_INVENTORY=${ORACLE_ROOT}/oraInventory
mkdir -p ${ORACLE_INVENTORY}
chown -R oracle:oinstall ${ORACLE_INVENTORY}
chmod -R 775 ${ORACLE_INVENTORY}
echo "* Oracle Home Directory"
ORACLE_HOME=${ORACLE_BASE}/product/11.2.0/dbhome_1
mkdir -p ${ORACLE_HOME}
chown -R oracle:oinstall ${ORACLE_HOME}
chmod -R 775 ${ORACLE_HOME}
#
echo ""
echo "==> Configuring Oracle Software Owner Environment"
