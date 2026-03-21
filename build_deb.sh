#!/bin/bash
# Copy latest binary
cp build-vala/figma-native-vala figma-app/usr/bin/figma-native

# Set permissions
chmod 755 figma-app/usr/bin/figma-launcher
chmod 755 figma-app/usr/bin/figma-native
chmod 644 figma-app/usr/share/applications/figma-app.desktop
chmod 644 figma-app/usr/share/icons/hicolor/scalable/apps/figma-app.svg
chmod 644 figma-app/DEBIAN/control

# Build the package
dpkg-deb --build figma-app

echo "Package figma-app.deb built successfully."
