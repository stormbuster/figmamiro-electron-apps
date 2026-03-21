#!/bin/bash
# Clean install script for Figma Native App

# 1. Remove the existing package completely (including configs)
sudo dpkg -P figma-app 2>/dev/null

# 2. Ensure the latest package is built
./build_deb.sh

# 3. Install the package
sudo dpkg -i ./figma-app.deb

# 4. Success message
echo "Clean install complete! Figma is now ready to launch."
