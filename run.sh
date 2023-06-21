#!/bin/bash

# MySQL database details
DB_USER="admin"
DB_PASSWORD="pass"
DB_NAME="db-mu"

# Backup file names
BACKUP_FILE="db.sql"
BACKUP_FILE_BAK="db.sql.bak"

# Backup command
MYSQL_DUMP_COMMAND="mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_FILE"

# Verify command
MYSQL_CHECK_COMMAND="mysqlcheck -u$DB_USER -p$DB_PASSWORD --check $DB_NAME"

# Git repository details
#GIT_REPO_PATH="/path/to/your/repo"
GIT_COMMIT_MESSAGE="Database auto backup"

# Function to check if the database backup is corrupt
function is_database_corrupt() {
    eval $MYSQL_CHECK_COMMAND 2>&1 | grep -q "is marked as crashed"
}

# Move existing backup file to backup file with .bak extension
if [ -e "$BACKUP_FILE" ]; then
    echo "Backup file already exists. Moving it to $BACKUP_FILE_BAK"
    mv "$BACKUP_FILE" "$BACKUP_FILE_BAK"
fi

# Retry backup until the database backup is not corrupt
while true; do
    # Execute the backup command
    eval $MYSQL_DUMP_COMMAND

    # Check if the backup was successful
    if [ $? -eq 0 ]; then
        echo "Database backup successful. Backup saved as $BACKUP_FILE"
        break
    else
        echo "Error: Database backup failed."

        # Check if the backup file is corrupt
        if is_database_corrupt; then
            echo "Error: Backup file is corrupt. Retrying backup..."
            sleep 5
        else
            echo "Error: Database is corrupt. Please check your MySQL installation."
            break
        fi
    fi
done

# Check if the backup is successful before committing to git
if [ -e "$BACKUP_FILE" ]; then
    # Move the backup file to the Git repository
    #cp "$BACKUP_FILE" "$GIT_REPO_PATH"

    # Navigate to the Git repository directory
    #cd "$GIT_REPO_PATH" || exit

    # Commit and push the backup file
    git add "$BACKUP_FILE"
    git commit -m "$GIT_COMMIT_MESSAGE"
    git push origin master

    echo "Backup file committed and pushed to GitHub repository."
else
    echo "Error: Backup file not found. Cannot commit and push to GitHub."
fi
