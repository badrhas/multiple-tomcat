#!/bin/bash

# Verify we are root
if [ "$USER" != "root" ]; then
  echo "You must run this script as root"
  exit 1
fi

# Verify that it is installed
if [ ! -d /var/lib/tomcat7 ]; then
  echo "You must first install tomcat from the apt repository"
  exit 1
fi

# Verify that it is installed
if [ -d /var/lib/tomcat7/instances ]; then
  echo "Multiple instances already setup on this box for Tomcat 7.0"
  exit 1
fi

# Shutdown any running instace
if ! /etc/init.d/tomcat7 stop; then
  echo "Unable to stop the running tomcat instance. Please stop it before running this script."
  exit 1
fi

# Backup the contents of the lib dir
tar cvzf backup-tomcat-lib.tar.gz /var/lib/tomcat7

# Remove everything from the lib dir (this removes symlinks and files first then recursively everything else)
rm /var/lib/tomcat7/* > /dev/null 2>&1
rm -rf /var/lib/tomcat7 > /dev/null 2>&1

# Remove all the symlinks from the share dir and fix the perms
rm /usr/share/tomcat7/* > /dev/null 2>&1
chown -R tomcat7:nogroup /usr/share/tomcat7
chmod -R o-rwx /usr/share/tomcat7

# Clean up defaults for the template script
mv /etc/default/tomcat7 /etc/default/tomcat7-not-used

# Make the layout for the defaults
mkdir -p /etc/default/tomcat7/

# Make the instances layout  
mkdir /var/lib/tomcat7/instances
chown -R tomcat7:nogroup /var/lib/tomcat7/instances
chmod -R o-rwx /var/lib/tomcat7/instances

# Clean up the logs
mkdir /var/log/tomcat7/old
mv /var/log/tomcat7/* /var/log/tomcat7/old > /dev/null 2>&1
mkdir /var/log/tomcat7/instances
chown -R tomcat7:nogroup /var/log/tomcat7/*
chmod -R o-rwx /var/log/tomcat7/*

# Backup the original init.d script just in case
if [ -f /etc/init.d/tomcat7 ]; then
	mv /etc/init.d/tomcat7 /etc/tomcat7/original-init-script
fi

# Remove the old init script and turn off all script links for the run levels
update-rc.d -f tomcat7 remove

echo "Successfully setup the machine for multiple tomcat instances and cleaned up the single instance layout"

