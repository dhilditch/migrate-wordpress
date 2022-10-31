#this is the migration script
echo "Usage: ./prepare-origin.sh originfolder [-f]"
#echo "Attempting to run: prepare-origin $1"

#locate the wp-config.php file
WPCONFIGFILE=$1wp-config.php
if [ ! -f "$WPCONFIGFILE" ]; then
    WPCONFIGFILE=$1../wp-config.php
fi
if [ ! -f "$WPCONFIGFILE" ]; then
    echo "Could not find origin wp-config.php - please ensure you add / to the end of any directory names"
    exit 0
fi
echo "Using origin config file $WPCONFIGFILE"

#grab the db creds
WPDBNAME=`cat $WPCONFIGFILE | grep DB_NAME | cut -d \' -f 4`
WPDBUSER=`cat $WPCONFIGFILE | grep DB_USER | cut -d \' -f 4`
WPDBPASS=`cat $WPCONFIGFILE | grep DB_PASSWORD | cut -d \' -f 4`

echo "Found origin DB Creds to connect: $WPDBNAME $WPDBUSER $WPDBPASS"

DBVERSION=`mysql --user=$WPDBUSER --password=$WPDBPASS -ANe"SELECT @@VERSION;"`

if [ -z "$DBVERSION" ]; then 
    echo "Could not connect to origin MySQL"
    exit 0
else
    echo "Connected to origin MySQL version $DBVERSION"
fi

if [ ! -f "$1mysqldump.php" ] || [ "$2" = "-f" ]; then 
    echo "Creating a backup and placing it in mysqldump.php in your root web folder so that it cannot be downloaded maliciously."
    rm "$1mysqldump.php" 2> /dev/null
    mysqldump --user=$WPDBUSER --password=$WPDBPASS --no-tablespaces $WPDBNAME > "$1../mysqldump.sql"
    sed 's/\sDEFINER=`[^`]*`@`[^`]*`//g' -i "$1../mysqldump.sql"

else
    echo "$1mysqldump.php already exists - skipping recreating dump file."
    echo "You can remove the origin dump file and re-run the backup by re-running migrate with the 4th parameter of -f"

    echo ""
fi





