#!/bin/sh
set -e

#=============================================================================
#
#  Variable declarations
#
#=============================================================================
SVER="20201029"			#-- Updated by Eugene Taylashev
#VERBOSE=1			#-- 1 - be verbose flag

DIR_DOKU=/usr/share/dokuwiki
URL_DOKU=https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz
DIR_TLS=/etc/tls
DIR_TMP=/tmp

#=============================================================================
#
#  Function declarations
#
#=============================================================================
#-----------------------------------------------------------------------------
#  Output debugging/logging message
#------------------------------------------------------------------------------
dlog(){
  MSG="$1"
#  echo "$MSG" >>$FLOG
  [ $VERBOSE -eq 1 ] && echo "$MSG"
}
# function dlog


#-----------------------------------------------------------------------------
#  Output error message
#------------------------------------------------------------------------------
derr(){
  MSG="$1"
#  echo "$MSG" >>$FLOG
  echo "$MSG"
}
# function derr

#-----------------------------------------------------------------------------
#  Output good or bad message based on return status $?
#------------------------------------------------------------------------------
is_good(){
    STATUS=$?
    MSG_GOOD="$1"
    MSG_BAD="$2"
    
    if [ $STATUS -eq 0 ] ; then
        dlog "${MSG_GOOD}"
    else
        derr "${MSG_BAD}"
    fi
}
# function is_good

#-----------------------------------------------------------------------------
#  Output important parametrs of the container 
#------------------------------------------------------------------------------
get_container_details(){
    
    if [ $VERBOSE -eq 1 ] ; then
        echo '[ok] - getting container details:'
        echo '---------------------------------------------------------------------'

        #-- for Linux Alpine
        if [ -f /etc/alpine-release ] ; then
            OS_REL=$(cat /etc/alpine-release)
            echo "Alpine $OS_REL"
            apk -v info | sort
        fi

        uname -a
        ip address
        echo '---------------------------------------------------------------------'
    fi
}
# function get_container_details


#=============================================================================
#
#  MAIN()
#
#=============================================================================
dlog '============================================================================='
dlog "[ok] - starting entrypoint.sh ver $SVER"

get_container_details


#-----------------------------------------------------------------------------
# Work with DokuWiki
#-----------------------------------------------------------------------------
#-- Verify that DokuWiki directory exists
if [ !  -d ${DIR_DOKU} ] ; then

  #-- create the directory
  mkdir -p ${DIR_DOKU}
  is_good "[ok] - created directory ${DIR_DOKU}" \
    "[not ok] - creating directory ${DIR_DOKU}"
else
  dlog "[ok] - directory $DIR_DOKU exists"
fi

#-- Verify that DokuWiki application exists
if [ ! -s ${DIR_DOKU}/doku.php ] ; then

  #-- download the stable version
  wget -q -O /tmp/doku.tgz ${URL_DOKU}
  is_good "[ok] - downloaded DokuWiki" \
  "[not ok] - downloading DokuWiki"

  #-- unpack TAR
  cd ${DIR_DOKU}
  tar -xzf /tmp/doku.tgz --strip-components=1
  is_good "[ok] - unpacked DokuWiki" \
  "[not ok] - unpacking DokuWiki"

else
  dlog "[ok] - application DokiWiki is installed"

fi

#-- Final check for the application or die
if [ ! -s ${DIR_DOKU}/doku.php ] ; then
  derr "[not ok] - application DokuWiki does NOT exist. Aborting..."
  exit 1
fi

#-- chanage permission just in case
chown -R apache:apache ${DIR_DOKU}
is_good "[ok] - verified permission for the app" \
  "[not ok] - verifying permission for the app"


#-----------------------------------------------------------------------------
# Work with Apche HTTPD configuration
#-----------------------------------------------------------------------------

#-- Check configuration URL
if [ "${URL_CONF}" = "none" ]; then

    #==== Prepare default configuration files
    #-- Change Document Root for httpd
    if [ -f /etc/apache2/httpd.conf ] ; then
      sed -i -e "s|DocumentRoot \"/var/www/localhost/htdocs\"|DocumentRoot \"${DIR_DOKU}\"|" \
        /etc/apache2/httpd.conf
      is_good "[ok] - changed DocumentRoot to DokiWiki for HTTP" \
        "[not ok] - changing DockumentRoot to DokuWiki for HTTP"
    fi

    #-- Change Document Root for httpd-ssl
    if [ -f /etc/apache2/conf.d/ssl.conf ] ; then
      sed -i -e "s|DocumentRoot \"/var/www/localhost/htdocs\"|DocumentRoot \"${DIR_DOKU}\"|" \
        /etc/apache2/conf.d/ssl.conf
      is_good "[ok] - changed DocumentRoot to DokiWiki for HTTPS" \
        "[not ok] - changing DockumentRoot to DokuWiki for HTTPS"
    fi

  #-- Create configuration file for DokuWiki
    if [ ! -s /etc/apache2/conf.d/doku.conf ] ; then
      cat <<- EOC > /etc/apache2/conf.d/doku.conf
    <Directory /usr/share/dokuwiki/bin>
        Require all denied
    </Directory>

    <Directory /usr/share/dokuwiki/data>
        Require all denied
    </Directory>

    <Directory /usr/share/dokuwiki/conf>
        Require all denied
    </Directory>

    <Directory /usr/share/dokuwiki/inc>
        Require all denied
    </Directory>

    <Directory /usr/share/dokuwiki/>
        DirectoryIndex doku.php
        Options +FollowSymLinks -Indexes -MultiViews
        Require all granted
#        Require ip 10.1.1.0/24


        <IfModule mod_rewrite.c>

                # Uncomment to implement server-side URL rewriting
                # (cf. <http://www.dokuwiki.org/config:userewrite>).
                        # Do *not* mix that with multisite!
                RewriteEngine on
                RewriteBase /dokuwiki
                RewriteRule ^lib                      - [L]
                RewriteRule ^doku.php                 - [L]
                RewriteRule ^feed.php                 - [L]
                RewriteRule ^install.php              - [L]                
                RewriteRule ^_media/(.*)              lib/exe/fetch.php?media=$1  [QSA,L]
                RewriteRule ^_detail/(.*)             lib/exe/detail.php?media=$1 [QSA,L]
                RewriteRule ^_export/([^/]+)/(.*)     doku.php?do=export_$1&id=$2 [QSA,L]
                RewriteRule ^$                        doku.php  [L]
                RewriteRule (.*)                      doku.php?id=$1  [QSA,L]
        </IfModule>
    </Directory>
EOC
      is_good "[ok] - created dokuwiki configuration file" \
        "[not ok] - creating dokuwiki configuration file"
    else
      dlog "[ok] - dokuwiki configuration file exists"
    fi
    #== End of default configuration

else 
    #==== Get external configuration files
    #-- Get configuration file
    wget -q --no-check-certificate -O ${DIR_TMP}/conf.7z ${URL_CONF}
    is_good "[ok] - downloaded specified apache configuration" \
        "[not ok] - downloading specified apache configuration"

    #-- Unpack configuration file with 7zip
    7z e -o${DIR_TMP} -p${SKEY} ${DIR_TMP}/conf.7z
    is_good "[ok] - unpacked specified apache configuration" \
        "[not ok] - unpacking specified apache configuration"

    if [ $VERBOSE -eq 1 ] ; then
      echo "List of special configuration files:"
      ls -l ${DIR_TMP}/
    fi

    #-- move httpd.conf
    if [ -s ${DIR_TMP}/httpd.conf ] ; then
        mv -f ${DIR_TMP}/httpd.conf /etc/apache2/httpd.conf
        is_good "[ok] - moved httpd.conf" \
            "[not ok] - moving httpd.conf"
    fi

    #-- move ssmtp.conf
    if [ -s ${DIR_TMP}/ssmtp.conf ] ; then
        mv -f ${DIR_TMP}/ssmtp.conf /etc/ssmtp/
        is_good "[ok] - moved ssmtp.conf" \
            "[not ok] - moving ssmtp.conf"
    fi

    #-- move other apache config files
    if compgen -G "${DIR_TMP}/*.conf" > /dev/null ; then
        mv -f ${DIR_TMP}/*.conf /etc/apache2/conf.d/
        is_good "[ok] - moved other configuration files" \
            "[not ok] - moving other configuration files"
    fi

    #-- check directory for certificates & keys
    if [ ! -d ${DIR_TLS} ] ; then
        mkdir -p ${DIR_TLS}
        is_good "[ok] - created directory ${DIR_TLS}" \
            "[not ok] - creating directory ${DIR_TLS}"
        chmod 755 ${DIR_TLS}
    fi

    #-- Copy keys, certificates and PEM if any
    mv ${DIR_TMP}/*.key ${DIR_TLS}/
    mv ${DIR_TMP}/*.crt ${DIR_TLS}/
    mv ${DIR_TMP}/*.pem ${DIR_TLS}/

    #-- Delete the archive
    rm -f ${DIR_TMP}/conf.7z

    #== End of external configuration
fi

#-- Redirect logs to stdout/stderr
ln -sf /dev/stdout /var/log/apache2/access.log && ln -sf /dev/stderr /var/log/apache2/error.log
is_good "[ok] - redirected HTTP logs for Docker" \
    "[not ok] - redirecting HTTP logs for Docker"
ln -sf /dev/stdout /var/log/apache2/ssl_access.log && ln -sf /dev/stderr /var/log/apache2/ssl_error.log
is_good "[ok] - redirected HTTPS logs for Docker" \
    "[not ok] - redirecting HTTPS logs for Docker"

#-- Apache gets grumpy about PID files pre-existing
rm -f /run/apache2/httpd.pid

#-- Check configuration
httpd -t -f /etc/apache2/httpd.conf
is_good "[ok] - Apache HTTPD configuration is good" \
    "[not ok] - Apache HTTPD configuration is NOT good"

dlog "[ok] - strating Apache HTTPD: "
exec httpd -E /dev/stderr -f /etc/apache2/httpd.conf -DFOREGROUND "$@"
derr "[not ok] - finish of entrypoint.sh"

