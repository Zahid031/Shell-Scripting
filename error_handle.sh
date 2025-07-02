#!/bin/bash

echo "Starting script..."

# Step 1: Change to the 'test' directory
cd test
if [ $? -ne 0 ]; then
    echo "Failed to enter 'test' directory"
    exit 1
fi

# Step 2: Run your command
echo "Running real command..."
ls -l  # replace with your actual command

# Step 3: Check if command was successful
if [ $? -ne 0 ]; then
    echo "Command failed"
    exit 1
fi

# Step 4: If everything is fine
echo "Test passed successfully!"

