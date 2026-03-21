#!/bin/bash
# Clean install script for Figma Native App

# 0. Kill any running instances
pkill -9 figma-native 2>/dev/null
pkill -9 figma-app 2>/dev/null

# 1. Remove the existing package completely
sudo dpkg -P figma-app 2>/dev/null

# 2. Rebuild the package
./build_deb.sh

# 3. Install the package
sudo dpkg -i ./figma-app.deb

# 4. Success message
echo "Clean install complete! Figma is now ready to launch."
