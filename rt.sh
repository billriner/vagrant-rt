#!/bin/bash

#-------------------------------------------------------------------------------
#
# rt.sh - Install RT 5.1
#
#-------------------------------------------------------------------------------

#  Installed required packages
dnf -y install gcc gcc-c++ expat-devel mariadb mariadb-server nginx perl perl-Devel-Peek perl-Encode-devel perl-open perl-CPAN spawn-fcgi wget

# Install CPAN
perl -MCPAN -e shell <<-EOI
	yes
EOI

# Download the RT software
cd /
wget https://download.bestpractical.com/pub/rt/release/rt-5.0.2.tar.gz
tar xzvf rt-5.0.2.tar.gz
cd rt-5.0.2/

# Configure the software
./configure

# Check the dependencies
make testdeps


# Fix the dependencies (may need to do more than once)
make fixdeps <<-EOI
        y
        n
        n
        n
        y
EOI

# Install other dependencies
perl -MCPAN -e 'install HTML::Element'
perl -MCPAN -e 'install HTML::FormatText::WithLinks::AndTables'
dnf -y install perl-LWP-Protocol-https
dnf -y install perl-DBD-mysql

# Start the database
systemctl enable mariadb
systemctl start mariadb

# Run secure installation
mysql_secure_installation <<-EOI

	y
	<db_root_passwd>
	<db_root_passwd>
	y
	y
	y
	y
EOI

# Install RT
cd /rt-5.0.2/
make install
make initialize-database <<-EOI
	<db_root_passwd>
EOI

# Create www-data user
useradd www-data

# Main RT site config file
mv /opt/rt5/local/etc/RT_SiteConfig.pm /opt/rt5/local/etc/RT_SiteConfig.pm.orig
echo >>/opt/rt5/local/etc/RT_SiteConfig.pm <<-EOI
use utf8;

# Any configuration directives you include  here will override
# RT's default configuration file, RT_Config.pm
#
# To include a directive here, just copy the equivalent statement
# from RT_Config.pm and change the value. We've included a single
# sample value below.
#
# If this file includes non-ASCII characters, it must be encoded in
# UTF-8.
#
# This file is actually a perl module, so you can include valid
# perl code, as well.
#
# The converse is also true, if this file isn't valid perl, you're
# going to run into trouble. To check your SiteConfig file, use
# this command:
#
#   perl -c /path/to/your/etc/RT_SiteConfig.pm
#
# You must restart your webserver after making changes to this file.
#

# You may also split settings into separate files under the etc/RT_SiteConfig.d/
# directory.  All files ending in ".pm" will be parsed, in alphabetical order,
# after this file is loaded.

#Set( $rtname, 'example.com');
#Set($rtname, 'vm-infr-helpdesk');
# Tag for RT emails, match previous server
Set($rtname, 'CSB Help Desk');
Set($WebDomain, "helpdesk.csb.vanderbilt.edu");
Set($Organization, "CSB");
Set($WebPort, 443);
# $WebBaseURL should already be computed from $WebDomain and $WebPort

# We don't use aliases and don't care about canonicalizing them back to the primary server URI
# ...however RT is convinced that the gateway interface (FCGI in our case) is asking
# for http:// rather than https:// (bug?) so this has the effect of being a workaround for that
#
Set($CanonicalizeRedirectURLs, 1);

Set($DatabaseName, 'rt4');
Set($DatabaseUser, 'rt_user');
Set($DatabasePassword, '<db_root_passwd>');

# Use the below LDAP source for both authentication, as well as user
# information
Set( $ExternalAuthPriority, ["VUIT_LDAP"] );
Set( $ExternalInfoPriority, ["VUIT_LDAP"] );

# https://docs.bestpractical.com/rt/5.0.2/RT/Authen/ExternalAuth.html
# https://docs.bestpractical.com/rt/5.0.2/RT/Authen/ExternalAuth/LDAP.html
Set($ExternalSettings, {
        # VUIT LDAP SERVICE
        'VUIT_LDAP'       =>  {
            'type'                      =>  'ldap',
            'server'                    =>  'ldaps://ldap.vunetid.vanderbilt.edu',
            'user'                      =>  'uid=aaiusevw,ou=special users,dc=vanderbilt,dc=edu',
            'pass'                      =>  'XXXXX',
            'base'                      =>  'ou=people,dc=vanderbilt,dc=edu',
            'filter'                    =>  '(uidNumber=*)',
            # to-do: define 'group', 'group_*' settings to limit to just ACCRE rather than any valid VUnetID

            # RT attributes that can uniquely ID user, must be defined in 'attr_map'
            # Note email from eLDAP is going to be @vanderbilt.edu addresses but most staff RT accounts use @accre.vanderbilt.edu addresses
            'attr_match_list' => [
                'Name',
                #'EmailAddress',
            ],

            # mapping between RT attribute names and LDAP attribute names
            'attr_map' => {
                'Name'         => 'uid',
                'EmailAddress' => 'mail',
                'RealName'     => 'cn',
            },
        },
    } );

# I think this will allow login of users(and bots) without LDAP credentials to login with internal RT credentials
# I think this is equivalent to the RT4 setting WebFallbackToInternalAuth that we used on the old server
#Set($WebFallbackToRTLogin, 1);

# MFH increased 2020-July-20 RT# 59396 to reduce occurrence of "message body is not shown because it is too large"
Set($MaxInlineBody, 100000);

# Don't hide closed tickets when searching
Set($OnlySearchActiveTicketsInSimpleSearch, 0);

#Ticket Priority
Set($EnablePriorityAsString, 0);
#show numeric ticket priorities in UI

# Enable full text search optimized with indexing
Set( %FullTextSearch,
        Enable     => 1,
        Indexed    => 1,
        Table      => 'AttachmentsIndex',
   );

# You must install Plugins on your own, this is only an example
# of the correct syntax to use when activating them:
#     Plugin( "RT::Authen::ExternalAuth" );

#Logging
Set($LogToSyslog , 'info');
Set($LogToScreen , 'info');

Set($LogToFile , 'debug'); #debug is very noisy
Set($LogDir , '/var/log/rt'); #log to rt directory
Set($LogToFileNamed , "rt.log"); #log to rt.log
1;
EOI

# Configure and start the webserver
echo >> /etc/nginx/nginx.conf <<-EIO

	server {
		listen 80;
		server_name helpdesk.csb.vanderbilt.edu
		#server_name 10.0.64.54;

		access_log  /var/log/nginx/access.log;

		location / {
			fastcgi_param  QUERY_STRING       $query_string;
			fastcgi_param  REQUEST_METHOD     $request_method;
			fastcgi_param  CONTENT_TYPE       $content_type;
			fastcgi_param  CONTENT_LENGTH     $content_length;

			fastcgi_param  SCRIPT_NAME        "";
			fastcgi_param  PATH_INFO          $uri;
			fastcgi_param  REQUEST_URI        $request_uri;
			fastcgi_param  DOCUMENT_URI       $document_uri;
			fastcgi_param  DOCUMENT_ROOT      $document_root;
			fastcgi_param  SERVER_PROTOCOL    $server_protocol;

			fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
			fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

			fastcgi_param  REMOTE_ADDR        $remote_addr;
			fastcgi_param  REMOTE_PORT        $remote_port;
			fastcgi_param  SERVER_ADDR        $server_addr;
			fastcgi_param  SERVER_PORT        $server_port;
			fastcgi_param  SERVER_NAME        $server_name;
			fastcgi_pass 10.0.64.54:9000;
		}
	}
EOI

systemctl enable nginx
systemctl start nginx

# Spawn the RT process 
spawn-fcgi -n -d /opt/rt5 -u www-data -g www-data -p 9000 -- /opt/rt5/sbin/rt-server.fcgi ; echo exit code $?
