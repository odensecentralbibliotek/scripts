#!/bin/bash  
SCRIPTTEXT="script <user@server> <remote platform> <remote site> <install profile>"
LOCALSTI="/var/aegir/platforms/"
LOCALBACKUPSTI="/var/aegir/platforms/backups/"
REMOTESTI="/data/disk/o2/static"
REMOTEBACKUPDIR="/data/disk/o2/backups/"

if [ $# -eq 0 ]
  then
    echo $SCRIPTTEXT
    exit 1
fi
if [ -z "$1" ]
  then
    echo $SCRIPTTEXT
    exit 1
fi
if [ -z "$2" ]
  then
    echo $SCRIPTTEXT
    exit 1
fi
if [ -z "$3" ]
  then
    echo $SCRIPTTEXT
    exit 1
fi
if [ -z "$4" ]
  then
    $4="standard"
fi

SERVERIP=$1
PLATFORM=$2
SITE=$3
INSTALL_PROFILE=$4
DRUSH_PLATFORM_NAME=$(/usr/bin/php -r "define('test','$2'); echo str_replace('-','',str_replace('.','',test));")

#Sync db backup to platform
sudo ionice -c 3 rsync -avzpH --include="$SITE*" --exclude="*" $SERVERIP:$REMOTEBACKUPDIR $LOCALBACKUPSTI
sudo chown dev:www-data $LOCALBACKUPSTI -R

#Get the backup file name.
cd $LOCALBACKUPSTI
BACKUPFILE="$(ls -t $SITE* | head -1)"

#Goto platform folder
cd $LOCALSTI/$PLATFORM

#create the site/sites
sudo -H -u aegir bash -c "drush provision-save '@dev.$SITE' --context_type='site' --uri='dev.$SITE' --platform='@platform_$DRUSH_PLATFORM_NAME' --server='@server_master' --db_server='@server_localhost' --profile='$INSTALL_PROFILE' --client_name='admin'"

#deploy
sudo chown aegir:www-data $LOCALSTI/$PLATFORM/sites -R
sudo -H -u aegir bash -c "drush @dev.$SITE provision-deploy $LOCALBACKUPSTI$BACKUPFILE"
sudo -H -u aegir bash -c "drush @hostmaster hosting-task @platform_$DRUSH_PLATFORM_NAME verify"
sudo -H -u aegir bash -c "drush @hostmaster hosting-task @dev.$SITE enable"
#add to host file
sudo echo "127.0.0.1  dev.$SITE" >> /etc/hosts

#done ?
echo "aegir site is ready at http://dev.$SITE"