#!/bin/zsh

# Directory containing the Renoise tool assets
tool_dir="lua"

# Output .xrnx file name
output_file="ES9.xrnx"

if [ -f ./ES9.xrnx ]; then
  rm ES9.xrnx
  echo "Deleted old tool, building new. . ."
fi

# Create a zip file from the contents of the tool directory and rename it to .xrnx
zip -r "$output_file" "$tool_dir"

echo "Created ${output_file} from ${tool_dir}"
