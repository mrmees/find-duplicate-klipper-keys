#!/bin/bash

# Find duplicate Klipper configuration keys across .cfg files
# Excludes backup files, datestamp files, and hidden files
# Shows which definition is active based on Klipper's load order

# Auto-detect config directory based on current user
DIR="$HOME/printer_data/config"

# Create temporary files
TEMP_FILE=$(mktemp)
LOAD_ORDER_FILE=$(mktemp)

# Function to recursively parse includes and build load order
parse_includes() {
    local file="$1"
    local processed_files="$2"
    
    # Skip if file doesn't exist or was already processed (circular include protection)
    if [[ ! -f "$file" ]] || [[ "$processed_files" == *"|$file|"* ]]; then
        return
    fi
    
    # Mark this file as processed
    processed_files="${processed_files}|${file}|"
    
    # Read the file line by line
    while IFS= read -r line; do
        # Check for [include ...] directives
        if [[ "$line" =~ ^\[include[[:space:]]+(.+)\] ]]; then
            local include_pattern="${BASH_REMATCH[1]}"
            
            # Remove any trailing comments
            include_pattern=$(echo "$include_pattern" | sed 's/#.*//' | xargs)
            
            # Handle wildcards
            if [[ "$include_pattern" == *"*"* ]]; then
                # Expand wildcards, sort alphabetically
                local base_dir=$(dirname "$file")
                local expanded_files=$(cd "$base_dir" && eval "ls -1 $include_pattern 2>/dev/null" | sort)
                
                while IFS= read -r included_file; do
                    [[ -z "$included_file" ]] && continue
                    local full_path="$base_dir/$included_file"
                    
                    # Skip backup, datestamp, and hidden files
                    local basename=$(basename "$full_path")
                    if [[ "$basename" =~ ^\..*$ ]] || \
                       [[ "$basename" =~ backup ]] || \
                       [[ "$basename" =~ [0-9]{4}[-_]?[0-9]{2}[-_]?[0-9]{2} ]]; then
                        continue
                    fi
                    
                    # Recursively parse the included file
                    parse_includes "$full_path" "$processed_files"
                done <<< "$expanded_files"
            else
                # Single file include
                local base_dir=$(dirname "$file")
                local full_path="$base_dir/$include_pattern"
                
                # Convert to absolute path
                full_path=$(cd "$base_dir" && cd "$(dirname "$include_pattern")" 2>/dev/null && pwd)/$(basename "$include_pattern")
                
                # Skip backup, datestamp, and hidden files
                local basename=$(basename "$full_path")
                if [[ "$basename" =~ ^\..*$ ]] || \
                   [[ "$basename" =~ backup ]] || \
                   [[ "$basename" =~ [0-9]{4}[-_]?[0-9]{2}[-_]?[0-9]{2} ]]; then
                    continue
                fi
                
                # Recursively parse the included file
                parse_includes "$full_path" "$processed_files"
            fi
        fi
    done < "$file"
    
    # After processing all includes, add this file to load order
    echo "$file" >> "$LOAD_ORDER_FILE"
}

# Start parsing from printer.cfg
PRINTER_CFG="$DIR/printer.cfg"

if [[ ! -f "$PRINTER_CFG" ]]; then
    echo "Error: printer.cfg not found at $PRINTER_CFG"
    exit 1
fi

# Build the load order
parse_includes "$PRINTER_CFG" ""

# Create a numbered load order map
declare -A load_order_map
load_order=1
while IFS= read -r file; do
    load_order_map["$file"]=$load_order
    ((load_order++))
done < "$LOAD_ORDER_FILE"

# Now scan all files in load order and extract keys
while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        relative_path="${file#$DIR/}"
        grep -E '^\[.*\]' "$file" | sed 's/[][]//g' | while read -r key; do
            echo "$key|$relative_path|${load_order_map[$file]}" >> "$TEMP_FILE"
        done
    fi
done < "$LOAD_ORDER_FILE"

# Find duplicate keys and show which one is active
echo "Duplicate configuration keys found:"
echo "===================================="
echo

# Sort and find duplicates, marking the active one
sort -t'|' -k1,1 -k3,3n "$TEMP_FILE" | awk -F'|' '
{
    key = $1
    file = $2
    order = $3
    
    if (key in keys) {
        keys[key] = keys[key] "," file ":" order
    } else {
        keys[key] = file ":" order
    }
}
END {
    for (key in keys) {
        split(keys[key], entries, ",")
        if (length(entries) > 1) {
            # Find the highest order number (last loaded)
            max_order = 0
            for (i in entries) {
                split(entries[i], parts, ":")
                if (parts[2] > max_order) {
                    max_order = parts[2]
                }
            }
            
            print "[" key "]"
            for (i in entries) {
                split(entries[i], parts, ":")
                file = parts[1]
                order = parts[2]
                if (order == max_order) {
                    print "  " file " ← ACTIVE"
                } else {
                    print "  " file
                }
            }
            print ""
        }
    }
}
'

# Cleanup
rm "$TEMP_FILE" "$LOAD_ORDER_FILE"
