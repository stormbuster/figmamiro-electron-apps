#!/bin/bash
# Copy latest binary
cp build-vala/miro-native-vala miro-app/usr/bin/miro-native

# Set permissions
chmod 755 miro-app/usr/bin/miro-launcher
chmod 755 miro-app/usr/bin/miro-native
chmod 644 miro-app/usr/share/applications/com.miro.native.desktop
chmod 644 miro-app/usr/share/icons/hicolor/scalable/apps/miro-app.svg
chmod 644 miro-app/DEBIAN/control

# Build the package
dpkg-deb --build miro-app

echo "Package miro-app.deb built successfully."
