#!/bin/bash

#-------------------------------------------------------------------------------
#
# rt.sh - Install RT 5.0
#
#-------------------------------------------------------------------------------

# RT version
RT_VER=5.0.3

# Disable SELinux
sed -i 's/=enforcing/=disabled/' /etc/selinux/config

# Enable the PowerTools repo (ol8_codeready_builder for OL 8)
dnf config-manager --set-enabled ol8_codeready_builder

# Install epel
dnf -y install epel-release

#  Installed required packages
dnf -y install gcc gcc-c++ expat-devel mariadb mariadb-server nginx perl perl-Devel-Peek perl-Encode-devel perl-open perl-CPAN spawn-fcgi wget w3m

dnf -y install expat gd graphviz openssl expat-devel gd-devel mlocate \
  openssl-devel perl-YAML wget screen \
  mod_fcgid perl-libwww-perl perl-Plack perl-GD \
  perl-GnuPG-Interface perl-GraphViz perl-Crypt-SMIME  \
  perl-String-ShellQuote perl-Crypt-X509 perl-LWP-Protocol-https graphviz-devel

# Install CPAN
perl -MCPAN -e shell <<-EOI
	yes
EOI

# Install cpanm and configure RT to use it to resolve dependancies
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
cpanm --self-upgrade --sudo
export RT_FIX_DEPS_CMD=`which cpanm`

# Download the RT software
cd /root
if [ ! -f "rt-$RT_VER.tar.gz" ]; then
  wget https://download.bestpractical.com/pub/rt/release/rt-5.0.3.tar.gz
  tar xvf rt-$RT_VER.tar.gz
fi
cd rt-$RT_VER

# Configure the software
./configure

# Fix the dependencies
make fixdeps <<-EOI
        y
        n
        n
        n
        y
EOI

# Install other dependencies
cpanm --force Date::Extract
cpanm --force GnuPG::Interface
dnf -y install perl-LWP-Protocol-https perl-DBD-mysql
dnf -y install "perl(DBD::mysql)" "perl(LWP::Protocol::https)"
perl -MCPAN -e shell <<-EOI
	install HTML::Element
	install HTML::FormatText
	install HTML::TreeBuilder
	install HTML::FormatText::WithLinks
	install HTML::FormatText::WithLinks::AndTables
EOI

# Check the dependencies
make testdeps

# Start the database
systemctl enable mariadb
systemctl start mariadb

# Run secure installation
mysql_secure_installation <<EOI

y
sbdb
sbdb
y
y
y
y
EOI

# Install RT
cd /root/rt-$RT_VER
make install

# Main RT site config file
mv /opt/rt5/etc/RT_SiteConfig.pm /opt/rt5/etc/RT_SiteConfig.pm.orig
cat > /opt/rt5/etc/RT_SiteConfig.pm <<'EOI'
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

Set($rtname, 'CSB Help Desk');
Set($WebDomain, "support.csb.vanderbilt.edu");
Set($Organization, "CSB");
Set($WebPort, 443);
# $WebBaseURL should already be computed from $WebDomain and $WebPort

# We don't use aliases and don't care about canonicalizing them back to the primary server URI
# ...however RT is convinced that the gateway interface (FCGI in our case) is asking
# for http:// rather than https:// (bug?) so this has the effect of being a workaround for that
#
Set($CanonicalizeRedirectURLs, 1);

Set($DatabaseName, 'rt5');
Set($DatabaseUser, 'rt_user');
Set($DatabasePassword, 'sbdb');

# Use the below LDAP source for both authentication, as well as user
# information
Set( $ExternalAuthPriority, ["VUDS"] );
Set( $ExternalInfoPriority, ["VUDS"] );

# https://docs.bestpractical.com/rt/5.0.3/RT/Authen/ExternalAuth/LDAP.html
Set($ExternalSettings, {
    # AN EXAMPLE LDAP SERVICE
    'VUDS'       =>  {
        'type'            =>  'ldap',

        'server'          =>  'ldaps://vuds.vanderbilt.edu',
        'user'            =>  'CN=aaiusesb,OU=Users,OU=Accounts,DC=vuds,DC=vanderbilt,DC=edu',
        'pass'            =>  'aRQ1t3C5UrDviV',

        'base'                      =>  'dc=vuds,dc=vanderbilt,dc=edu',
        'filter'                    =>  '(uid=*)',
        'd_filter'                  =>  '',

        'group'                     =>  '',
        'group_attr'                =>  '',

        'tls'                       =>  { verify => "require", cafile => "/path/to/ca.pem" },

        'net_ldap_args'             => [    version =>  3   ],

        'attr_match_list' => [
            'Name',
            'EmailAddress',
        ],
        'attr_map' => {
            'Name' => 'uid',
            'EmailAddress' => 'mail',
            'Organization' => 'department',
            'RealName' => 'displayName',
            'WorkPhone' => 'telephoneNumber'
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

# Set the RT user password
mkdir /var/log/rt
chown -R www-data.www-data /var/log/rt/
make initialize-database <<EOI
sbdb
EOI

# Create www-data user
useradd www-data

# Configure and start the webserver
#mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
#cat > /etc/nginx/nginx.conf <<EOI
#server {
#        listen 80;
#        server_name support.csb.vanderbilt.edu;
#        access_log  /var/log/nginx/access.log;
#
#        location / {
#                fastcgi_param  QUERY_STRING       $query_string;
#                fastcgi_param  REQUEST_METHOD     $request_method;
#                fastcgi_param  CONTENT_TYPE       $content_type;
#                fastcgi_param  CONTENT_LENGTH     $content_length;
#
#                fastcgi_param  SCRIPT_NAME        "";
#                fastcgi_param  PATH_INFO          $uri;
#                fastcgi_param  REQUEST_URI        $request_uri;
#                fastcgi_param  DOCUMENT_URI       $document_uri;
#                fastcgi_param  DOCUMENT_ROOT      $document_root;
#                fastcgi_param  SERVER_PROTOCOL    $server_protocol;
#
#                fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
#                fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
#
#                fastcgi_param  REMOTE_ADDR        $remote_addr;
#                fastcgi_param  REMOTE_PORT        $remote_port;
#                fastcgi_param  SERVER_ADDR        $server_addr;
#                fastcgi_param  SERVER_PORT        $server_port;
#                fastcgi_param  SERVER_NAME        $server_name;
#                fastcgi_pass 10.2.188.31:9000;
#        }
#}
#EOI

# Add the www-data user to the apache group
usermod -a -G apache www-data

# Enable and start the web server
systemctl enable nginx
systemctl start nginx

# Spawn the RT process 
spawn-fcgi -n -d /opt/rt5 -u www-data -g www-data -p 9123 -- /opt/rt5/sbin/rt-server.fcgi ; echo exit code $? &

# Set up the RT cron jobs
(crontab -l ; echo "0 0 * * * root /opt/rt5/sbin/rt-clean-sessions") | crontab -
(crontab -l ; echo "0 0 * * * root /opt/rt5/sbin/rt-email-digest -m daily") | crontab -
(crontab -l ; echo "0 0 * * 0 root /opt/rt5/sbin/rt-email-digest -m weekly") | crontab -
(crontab -l ; echo "0 * * * * root /opt/rt5/sbin/rt-email-dashboards") | crontab -

# Configure the RT email gateway

cat >> /etc/aliases <<EOI

# RT aliases
admin-todo: "|rt-mailgate --queue admin-todo --action correspond --url https://structbio.vanderbilt.edu/rt" 
admin-todo-comment: "|rt-mailgate --queue admin-todo --action comment --url https://structbio.vanderbilt.edu/rt" 
nmr-help: "|rt-mailgate --queue nmr --action correspond --url https://structbio.vanderbilt.edu/rt" 
nmr-comment: "|rt-mailgate --queue nmr --action comment --url https://structbio.vanderbilt.edu/rt" 
#support: "|rt-mailgate --queue support --action correspond --url https://structbio.vanderbilt.edu/rt" 
support: "|newSpamCatcher.pl"
support-comment: "|rt-mailgate --queue support --action comment --url https://structbio.vanderbilt.edu/rt" 
mlpcn: "|rt-mailgate --queue mlpcn --action correspond --url https://structbio.vanderbilt.edu/rt" 
mlpcn-comment: "|rt-mailgate --queue mlpcn --action comment --url https://structbio.vanderbilt.edu/rt" 
resource: "|rt-mailgate --queue resource --action correspond --url https://structbio.vanderbilt.edu/rt" 
resource-comment: "|rt-mailgate --queue resource --action comment --url https://structbio.vanderbilt.edu/rt" 
xtal-help: "|rt-mailgate --queue xtal --action correspond --url https://structbio.vanderbilt.edu/rt" 
xtal-comment: "|rt-mailgate --queue xtal --action comment --url https://structbio.vanderbilt.edu/rt" 
vcndd: "|rt-mailgate --queue vcndd --action correspond --url https://structbio.vanderbilt.edu/rt" 
vcndd-comment: "|rt-mailgate --queue vcndd --action comment --url https://structbio.vanderbilt.edu/rt" 
EOI

# Update the location database
updatedb
