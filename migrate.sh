# WordPress Site Migration Script 
# GPL 3 License
# Copy/re-use as desired, just give me some credit somewhere
# Created by Dave Hilditch, www.wpintense.com, created because I'm fed up with all the other paid migration tools totally failing to work on bigger sites and/or taking forever to complete
# This script took 90 minutes to complete flawless migration of my million product server from Digital Ocean to Hetzner
# Run this script from your destination server, make sure you can SSH from your destination server to your origin server first (add your destination server SSH key to your origin authorized_keys file)
# Usage: ./migrate.sh user@originip originfolder destinationfolder [-f] 
# -f will bypass the confirmation prompt and force the origin backup to run every time (if you re-run this otherwise, it will re-run rsync and the DB restore but not the DB backup)
#
# How this works: There are two scripts, this one that you run on your destination server, then prepare-origin.sh which gets remotely executed on your origin server.
# prepare-origin.sh reads your remote wp-config.php, and backs up your db to your webroot folder as a .php file so it can't be read by anyone else
# Then this migrate.sh performs an rsync, excluding mu-plugins, wp-includes, wp-admin, wp-config.php, db.php, advanced-cache.php, object-cache.php copying all files to your destination
# Finally, it restores your database and then flushes your object cache if you have one
# Provided you have SSH access to both servers, this is by far the best migration technique I've found. It's fast, it's reliable, it's secure, and it's free.
# Potential issues:
#  - mu-plugins does not get copied, you may need some of these from your origin
#  - wp-config.php does not get copied, you may have some extra customisations in this file you need to copy
#  - it's possible that mysqldump may not be able to write to your webroot folder. If this is the case, you can manually copy the mysqldump.php file to your webroot folder.

#todo: Add pause before running and overwriting local files and local database - continuing will wipe the local files and database - bypass if -f specified
echo "Attempting to run: migrate $1 $2 $3 $4"

if ! ssh "$1" 'bash -s' < prepare-origin.sh $2 $4
then
    echo "Could not connect to origin server. Aborting."

    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        #todo: Add create ssh key prompt
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
echo "rsync -chavzP --stats  $1:$2 $3 --exclude 'wp-admin' --exclude 'wp-includes' --exclude 'wp-config.php' --exclude 'wp-content/db.php' --exclude 'wp-content/advanced-cache.php' --exclude 'wp-content/debug.log' --exclude 'wp-content/object-cache.php' --exclude 'wp-content/mu-plugins' --exclude 'wp-content/updraft' --exclude 'wp-content/w3tc-config' --exclude 'wp-content/cache'  --exclude 'robots.txt'"

rsync -chavzP --stats  $1:$2 $3 --exclude 'wp-admin' --exclude 'wp-includes' --exclude 'wp-config.php' --exclude 'wp-content/db.php' --exclude 'wp-content/advanced-cache.php' --exclude 'wp-content/debug.log' --exclude 'wp-content/object-cache.php' --exclude 'wp-content/mu-plugins' --exclude 'wp-content/updraft' --exclude 'wp-content/w3tc-config' --exclude 'wp-content/cache'  --exclude 'robots.txt'
rsync -chavzP --stats  "$1:$2../mysqldump.sql" "$3../"

echo "Rsync Complete"
echo ""
echo "Restoring database"

mysql --user=$WPDBUSER --password=$WPDBPASS $WPDBNAME < "$3../mysqldump.sql"

echo ""
echo "DB restore complete"
echo ""
echo "Before updating your DNS to point at your new server, you should test first by editing your local HOSTS file to point your website URL at your new server IP for your PC. This will let you test safely."
echo "You can re-run this script with the -f parameter to refresh your migration at any time. This will create a fresh DB backup and resync the origin files to your destination server."

# flush redis cache upon completion
redis-cli FLUSHALL


