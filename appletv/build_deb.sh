#!/bin/bash
# Remove old contents
rm -rf appletv-app/usr/bin/appletv-native
mkdir -p appletv-app/opt/appletv-native

# Copy Electron-unpacked contents
cp -rf ../appletv-source/dist/linux-unpacked/* appletv-app/opt/appletv-native/

# Set permissions
chmod 755 appletv-app/usr/bin/appletv-launcher
chmod -R 755 appletv-app/opt/appletv-native/
chmod 644 appletv-app/usr/share/applications/com.appletv.native.desktop
chmod 644 appletv-app/usr/share/icons/hicolor/scalable/apps/appletv-app.png
chmod 755 appletv-app/DEBIAN/postinst
chmod 644 appletv-app/DEBIAN/control

# Build the package
dpkg-deb --build appletv-app

echo "Package appletv-app.deb built successfully from Electron source."
