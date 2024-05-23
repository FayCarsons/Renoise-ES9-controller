#!/bin/zsh

INPUT_DIR=lua
OUTPUT_DIR=ES9.xrnx

# If .xrnx exists, delete it
if [ -f ./$OUTPUT_DIR ]; then
  rm $OUTPUT_DIR
  echo "Deleted old tool, building new. . ."
fi

# If input dir can't be found then exit
if [ ! -d $INPUT_DIR ]; then
  echo "Can't find lua folder"
  exit 1
fi

# Enter input directory and zip its contents into an .xrnx file
# Echo message if successful, and 'else' to echo error message on failure
if cd ./$INPUT_DIR && zip -vr ../$OUTPUT_DIR *; then  
  echo "Created .xrnx file!"
else
  echo "Failed to create .xrnx file!"
  exit 1
fi

