# migrate-wordpress
Migrate WordPress efficiently, quickly, effectively, reliably

Download these files to your DESTINATION server.

`git clone https://github.com/dhilditch/migrate-wordpress`

Then change directory to the migrate-wordpress folder:

`cd migrate-wordpress`

Test you can connect with SSH to your origin server:

`ssh user@originip`

Then run the command. **Be sure you are ready to wipe your destination files and database.** This script overwrites the destination-server database mentioned in the wp-config.php file in your destinationfolder.

#Usage
`./migrate.sh user@originip originfolder destinationfolder [-f]`

*-f will bypass the confirmation prompt and force the origin backup to run every time (if you re-run this otherwise, it will re-run rsync and the DB restore but not the DB backup)*

This will connect via SSH to your origin server, read your wp-config creds, backup your DB, rsync all the files to your destination, then restore the DB at your destination.

It is smart enough to exclude server-specific files like db.php, advanced-cache.php and more.

This script took 90 minutes to complete flawless migration of my million product server from Digital Ocean to Hetzner
Run this script from your destination server, make sure you can SSH from your destination server to your origin server first (add your destination server SSH key to your origin authorized_keys file)

#How this migration script works
There are two scripts, this one that you run on your destination server, then prepare-origin.sh which gets remotely executed on your origin server.

prepare-origin.sh reads your remote wp-config.php, and backs up your db to your webroot folder as a .php file so it can't be read by anyone else

Then this migrate.sh performs an rsync, excluding mu-plugins, wp-includes, wp-admin, wp-config.php, db.php, advanced-cache.php, object-cache.php copying all files to your destination

Finally, it restores your database and then flushes your object cache if you have one

Provided you have SSH access to both servers, this is by far the best migration technique I've found. It's fast, it's reliable, it's secure, and it's free.

#Potential issues
 - mu-plugins does not get copied, you may need some of these from your origin
 - wp-config.php does not get copied, you may have some extra customisations in this file you need to copy
 - it's possible that mysqldump may not be able to write to your webroot folder. If this is the case, you can manually copy the mysqldump.php file to your webroot folder.
