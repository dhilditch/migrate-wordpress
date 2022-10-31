#this is the migration script
echo "Usage: ./migrate.sh user@originip originfolder destinationfolder [-f]"
echo "Attempting to run: migrate $1 $2 $3 $4"

#FORCE=NO
#if [ $# -eq 4 ] ; then
#    FORCE="$4"
#fi

if ! ssh "$1" 'bash -s' < prepare-origin.sh $2 $4
then
    echo "Could not connect to origin server. Aborting."

    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        ssh-keygen -f ~/.ssh/id_rsa.pub
    fi
    echo ""
    echo "Public Key for this user which needs to be added to your origin ~/.ssh/authorized_keys file:"
    echo ""
    cat ~/.ssh/id_rsa.pub
    exit 0
fi

#locate the wp-config.php file
WPCONFIGFILE=$3wp-config.php
if [ ! -f "$WPCONFIGFILE" ]; then
    WPCONFIGFILE=$3../wp-config.php
fi
if [ ! -f "$WPCONFIGFILE" ]; then
    echo "Could not find wp-config.php - please ensure you add / to the end of any directory names"
    exit 0
fi
echo "Using config file $WPCONFIGFILE"

#grab the db creds
WPDBNAME=`cat $WPCONFIGFILE | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat $WPCONFIGFILE | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat $WPCONFIGFILE | grep DB_PASSWORD | cut -d \' -f 4`

echo "Found DB Creds to connect: $WPDBNAME $WPDBUSER $WPDBPASS"

DBVERSION=`mysql --user=$WPDBUSER --password=$WPDBPASS -ANe"SELECT @@VERSION;"`

if [ -z "$DBVERSION" ]; then 
    echo "Could not connect to MySQL"
    exit 0
else
    echo "Connected to MySQL version $DBVERSION"
fi

echo "Starting rsync to remote server"
echo "rsync -chavzP --stats  $1:$2 $3 --exclude 'wp-admin' --exclude 'wp-includes' --exclude 'wp-config.php' --exclude 'wp-includes' --exclude 'wp-content/db.php' --exclude 'wp-content/advanced-cache.php' --exclude 'wp-content/debug.log' --exclude 'wp-content/object-cache.php' --exclude 'wp-content/mu-plugins' --exclude 'wp-content/updraft' --exclude 'wp-content/w3tc-config' --exclude 'wp-content/cache'  --exclude 'wp-content/robots.txt'"

rsync -chavzP --stats  $1:$2 $3 --exclude 'wp-admin' --exclude 'wp-includes' --exclude 'wp-config.php' --exclude 'wp-includes' --exclude 'wp-content/db.php' --exclude 'wp-content/advanced-cache.php' --exclude 'wp-content/debug.log' --exclude 'wp-content/object-cache.php' --exclude 'wp-content/mu-plugins' --exclude 'wp-content/updraft' --exclude 'wp-content/w3tc-config' --exclude 'wp-content/cache'  --exclude 'wp-content/robots.txt'

echo "Rsync Complete"
echo ""
echo "Restoring database"

mysql --user=$WPDBUSER --password=$WPDBPASS $WPDBNAME < $3mysqldump.php 

echo ""
echo "DB restore complete"
echo ""
echo "Before updating your DNS to point at your new server, you should test first by editing your local HOSTS file to point your website URL at your new server IP for your PC. This will let you test safely."
echo "You can re-run this script with the -f parameter to refresh your migration at any time. This will create a fresh DB backup and resync the origin files to your destination server."



