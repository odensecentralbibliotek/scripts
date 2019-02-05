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

echo "INFO: Finder nyeste backup fil.\n"
NEWST_BACKUP_FILE=($(ssh yusuf@10.0.0.115  ls -t "/data/disk/o2/backups/$SITE*" | head -1 | xargs -n1 basename))

#Sync db backup to platform
sudo ionice -c 3 rsync -avzpH --include="$NEWST_BACKUP_FILE" --exclude="*" $SERVERIP:$REMOTEBACKUPDIR $LOCALBACKUPSTI
sudo chown dev:www-data $LOCALBACKUPSTI -R

#Get the backup file name.
cd $LOCALBACKUPSTI
BACKUPFILE="$(ls -t $SITE* | head -1)"

#Goto platform folder
cd $LOCALSTI/$PLATFORM

#delete old sites 
echo "INFO: Deleting old site if present..(this takes a while on large sites)\n"
sudo -H -u aegir bash -c "drush @hostmaster hosting-task @dev.$SITE disable"
sudo -H -u aegir bash -c "drush @hostmaster hosting-task @dev.$SITE delete"

#create the site/sites
sudo -H -u aegir bash -c "drush provision-save '@dev.$SITE' --context_type='site' --uri='dev.$SITE' --platform='@platform_$DRUSH_PLATFORM_NAME' --server='@server_master' --db_server='@server_localhost' --profile='$INSTALL_PROFILE' --client_name='admin'"

#deploy
echo "INFO: Deploying the new site!\n"
sudo chown aegir:www-data $LOCALSTI/$PLATFORM/sites -R
sudo -H -u aegir bash -c "drush @dev.$SITE provision-deploy $LOCALBACKUPSTI$BACKUPFILE"
sudo -H -u aegir bash -c "drush @hostmaster hosting-task @platform_$DRUSH_PLATFORM_NAME verify"
sudo -H -u aegir bash -c "drush @hostmaster hosting-task @dev.$SITE enable"
#add to host file
#echo "127.0.0.1 dev.$SITE" | sudo tee -a /etc/hosts

#Delete the backup and we are done :)
cd LOCALBACKUPSTI
rm *
echo "aegir site is ready at http://dev.$SITE"