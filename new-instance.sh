#!/bin/bash

if [ "$USER" != "root" ]; then
  echo "You must run this script as root"
  exit 1
fi

if [ $# != 4 ]; then
  echo "Usage: new-instance.sh <instancename> <port> <jk-port> <shutdown-port>"
  exit 1
fi

# Get the working dir
script_dir=$(dirname $0)
cd ${script_dir}
script_dir=$PWD
cd -

# Setup the variables
instancename=$1
port=$2
jk_port=$3
shutdown_port=$4
host_name_underscores=${instancename//\./_}
instance_dir=/var/lib/tomcat7/instances/${instancename}
log_dir=/var/log/tomcat7/instances/${instancename}

# Setup the instance directory
if [ -d ${instance_dir} ]; then
  echo "Instance ${host_name} already created."
  exit 1
fi
mkdir -p ${instance_dir}

# Copy the files and token replace
mkdir ${instance_dir}/conf ${instance_dir}/webapps ${instance_dir}/bin ${instance_dir}/temp ${instance_dir}/work
if ! cp /etc/tomcat7/web.xml ${instance_dir}/conf; then
  echo "Unable to create new instance ${instancename} because /etc/tomcat7/web.xml doesn't appear to exist"
  exit 1
fi

# Copy default configuration
cp -R ${script_dir}/tomcat7/* ${instance_dir}/conf/
chown -R tomcat7:nogroup ${instance_dir}/conf/*
chmod -R o-rwx ${instance_dir}/conf/*

# Copy Tomcat Manager to webapps 
#cp -R ${script_dir}/webapps/* ${instance_dir}/webapps/
#chown -R tomcat7:nogroup ${instance_dir}/webapps/*
#chmod -R o-rwx ${instance_dir}/webapps/*

if ! sed "s/@HOST_NAME@/${instancename}/g" ${script_dir}/tomcat7/server.xml | sed "s/@HOST_NAME_UNDERSCORES@/${host_name_underscores}/g" | sed "s/@PORT@/${port}/g" | sed "s/@JK_PORT@/${jk_port}/g"| sed "s/@SHUTDOWN_PORT@/${shutdown_port}/g" > ${instance_dir}/conf/server.xml; then
  echo "Unable to create new instance ${host_name} because ${script_dir}/tomcat7/server.xml doesn't appear to exist"
  exit 1
fi

if ! sed "s/@HOST_NAME@/${instancename}/g" ${script_dir}/init.d/tomcat7 > ${instance_dir}/bin/tomcat7-init-script; then
  echo "Unable to find the custom ${script_dir}/init.d/tomcat7 file. This file must exist."
  exit 1
fi

# Set the permissions to protect the instance
chown -R tomcat7:nogroup ${instance_dir}
chmod -R o-rwx ${instance_dir}
chmod ug+rx ${instance_dir}/bin/tomcat7-init-script

# Setup the logs
mkdir ${log_dir}
chown -R tomcat7:nogroup ${log_dir}
chmod -R o-rwx ${log_dir}
ln -s ${log_dir} ${instance_dir}/logs

# Copy defaults
cp ${script_dir}/default/tomcat7-defaults /etc/default/tomcat7/${instancename}

# Setup auto start
cp ${instance_dir}/bin/tomcat7-init-script /etc/init.d/tomcat7-${instancename}
update-rc.d tomcat7-${instancename} defaults 90

# Set ownership of Tomcat directory
chown -R tomcat7:nogroup /var/lib/tomcat7

# Create symbolic link to lib directory under root's home directory
ln -s /var/lib/tomcat7/instances/${instancename} ~/tomcat-${instancename}
