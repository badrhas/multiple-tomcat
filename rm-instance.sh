#!/bin/bash

if [ "$USER" != "root" ]; then
  echo "You must run this script as root"
  exit 1
fi

if [ $# != 1 ]; then
  echo "Usage: rm-instance.sh <instancename>"
  exit 1
fi

# Get the working dir
script_dir=$(dirname $0)
cd ${script_dir}
script_dir=$PWD
cd - > /dev/null

# Setup the variables
instancename=$1
instance_dir=/var/lib/tomcat7/instances/${instancename}
log_dir=/var/log/tomcat7/instances/${instancename}

if [ ! -d $instance_dir ]; then
  echo "Invalid instance $host_name ($instance_dir is missing)"
  exit 1
fi

# Remove the instance directory
rm -r $instance_dir

# Remove the default configuration
rm -r /etc/default/tomcat7/${instancename}

# Remove the logs
rm -r $log_dir

# Setup auto start
rm /etc/init.d/tomcat7-${instancename}
update-rc.d tomcat7-${instancename} remove

# Remove symbolic link
rm ~/tomcat-${instancename}
