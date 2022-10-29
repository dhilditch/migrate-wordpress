# migrate-wordpress
Migrate WordPress efficiently, quickly, effectively, reliably

Download these files to your DESTINATION folder, make sure the migrate.sh file is executable and then run the following command:

Usage: ./migrate.sh user@originip originfolder destinationfolder [-f]

This will connect via SSH to your origin server, read your wp-config creds, backup your DB, rsync all the files to your destination, then restore the DB at your destination.

It is smart enough to exclude server-specific files like db.php, advanced-cache.php and more.
