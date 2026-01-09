#!/bin/bash

# Find duplicate Klipper configuration keys across .cfg files
# Excludes backup files, datestamp files, and hidden files

# Auto-detect config directory based on current user
DIR="$HOME/printer_data/config"

# Create temporary file to store key-file mappings
TEMP_FILE=$(mktemp)

# Find all .cfg files and extract [keys]
# Exclude files with 'backup' in name, datestamp patterns, or hidden files
find "$DIR" -type f -name "*.cfg" ! -name ".*" | grep -viE '(backup|[0-9]{4}[-_]?[0-9]{2}[-_]?[0-9]{2})' | while read -r file; do
    # Extract section headers [key] from each file
    # Store relative path from config directory
    relative_path="${file#$DIR/}"
    grep -E '^\[.*\]' "$file" | sed 's/[][]//g' | while read -r key; do
        echo "$key|$relative_path" >> "$TEMP_FILE"
    done
done

# Find duplicate keys and list files containing them
echo "Duplicate configuration keys found:"
echo "===================================="
echo

# Sort and find duplicates
sort "$TEMP_FILE" | awk -F'|' '
{
    keys[$1] = keys[$1] ? keys[$1] "," $2 : $2
}
END {
    for (key in keys) {
        split(keys[key], files, ",")
        if (length(files) > 1) {
            print "[" key "]"
            for (i in files) {
                print "  " files[i]
            }
            print ""
        }
    }
}
'

# Cleanup
rm "$TEMP_FILE"
