#!/bin/bash

# Define source and target directories
source_dir="../images/equipment"
#target_dir="../controlpad_test_server/controller/resources/equipment"
target_dir="./temp"

if [ ! -d "$target_dir" ]; then
    echo "Error: output dir doesn't exist"
    exit 1
fi

for file in "$source_dir"/*Arrow*.png; do
    # Get the filename without the path
    filename=$(basename "$file")
    
    # Use ImageMagick to cut off the right half and save in the target directory
    convert "$file" -crop 50%x100%+0+0 "$target_dir/$filename"
done
