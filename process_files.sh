#!/bin/bash

#a big learning from this small script:
#it'll ignore the last line if there's no an additional empty line at the very bottom of a file
#so it's critical to insert an empty line in the bottom of a file so that the last line in your file could be read by this script
input="/path/to/txt/file"
while IFS= read -r line
do
  echo "$line"
done < "$input"