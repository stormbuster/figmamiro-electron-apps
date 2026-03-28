#!/bin/bash
# Global install script for Figma and Miro native apps

echo "--- Cleaning up existing instances ---"
pkill -f figma-native || true
pkill -f miro-native || true

echo "--- Building and Installing FIGMA ---"
cd figma
# Clean and Setup build dir
rm -rf build-vala
meson setup build-vala --prefix=/usr
meson compile -C build-vala
# Ensure binary is copied
./build_deb.sh
# Purge and re-install
sudo dpkg -P figma-app || true
sudo dpkg -i figma-app.deb
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

echo "--- Enabling Hardware Acceleration & Finalizing System Triggers ---"
echo "Optimizations: GPU Rasterization, Zero Copy, and Accelerated 2D Canvas enabled."
sudo update-desktop-database
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor

echo "--- Done! Both apps are ready to launch ---"
