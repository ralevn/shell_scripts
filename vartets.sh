#!/usr/bin/env bash

# Set the positional parameters managed by 'set' to be the same as the arguments passed to the script
set -- "$@"

# Iterate over the positional parameters using a for loop with enumeration
for ((i = 1; i <= $#; i++)); do
    echo "Argument $i: ${!i}"
done

