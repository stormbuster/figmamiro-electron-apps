#!/bin/bash
# Global install script for Figma and Miro native apps

echo "--- Cleaning up existing instances ---"
pkill -f figma-native || true
pkill -f miro-native || true

echo "--- Building and Installing FIGMA (Electron Fork) ---"
cd figma-linux-source
# Build Electron app (only the unpacked directory needed for our .deb)
npm run build && npm run builder -- --dir
cd ../figma
# Build .deb package using the new Electron bundle
./build_deb.sh
# Purge and re-install
sudo dpkg -P figma-app || true
sudo dpkg --force-all -i figma-app.deb
cd ..

echo "--- Building and Installing MIRO ---"
cd miro
# Clean and Setup build dir
rm -rf build-vala
meson setup build-vala --prefix=/usr
meson compile -C build-vala
# Ensure binary is copied
./build_deb.sh
# Purge and re-install
sudo dpkg -P miro-app || true
sudo dpkg -i miro-app.deb
cd ..

echo "--- Building and Installing Apple TV ---"
cd appletv-source
npm install
npm run build
cd ../appletv
./build_deb.sh
sudo dpkg -P appletv-app || true
sudo dpkg --force-all -i appletv-app.deb
cd ..

echo "--- Enabling Hardware Acceleration & Finalizing System Triggers ---"
echo "Optimizations: GPU Rasterization, Zero Copy, and Accelerated 2D Canvas enabled."
sudo update-desktop-database
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor

echo "--- Done! All apps are ready to launch ---"
