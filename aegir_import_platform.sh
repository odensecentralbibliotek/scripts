 #!/bin/bash  
SCRIPTTEXT="script <user@server> <remote platform>"
LOCALSTI="/var/aegir/platforms/"
REMOTESTI="/data/disk/o2/static"

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
SERVERIP=$1
PLATFORM=$2
DRUSH_PLATFORM_NAME=$(/usr/bin/php -r "define('test','$2'); echo str_replace('-','',str_replace('.','',test));")

echo "Henter platform $2";
#Sync the files and folders
sudo ionice -c 3 rsync -avzPH --exclude='*.dk' $SERVERIP:$REMOTESTI/$PLATFORM $LOCALSTI

#Setup rigths
sudo chown aegir:www-data $LOCALSTI$PLATFORM -R

#Goto platform folder
cd $LOCALSTI/$PLATFORM

#create the platform
sudo -H -u aegir bash -c "drush --root='$LOCALSTI$PLATFORM' provision-save '@platform_$DRUSH_PLATFORM_NAME' --context_type='platform'"
sudo -H -u aegir bash -c "drush @hostmaster hosting-import @platform_$DRUSH_PLATFORM_NAME"

echo "Platform created at $LOCALSTI$PLATFORM and is ready to import sites."

