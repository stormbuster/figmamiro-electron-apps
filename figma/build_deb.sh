#!/bin/bash
# Remove old contents
rm -rf figma-app/usr/bin/figma-native
mkdir -p figma-app/opt/figma-native

# Copy Electron-unpacked contents
cp -rf ../figma-linux-source/build/installers/linux-unpacked/* figma-app/opt/figma-native/

# Set permissions
chmod 755 figma-app/usr/bin/figma-launcher
chmod -R 755 figma-app/opt/figma-native/
chmod 644 figma-app/usr/share/applications/com.figma.native.desktop
chmod 644 figma-app/usr/share/icons/hicolor/scalable/apps/figma-app.svg
chmod 755 figma-app/DEBIAN/postinst
chmod 644 figma-app/DEBIAN/control

# Update Architecture to amd64
sed -i 's/Architecture: all/Architecture: amd64/' figma-app/DEBIAN/control
# Update Depends for Electron
sed -i 's/Depends: .*/Depends: libnss3, libatk1.0-0, libatk-bridge2.0-0, libcups2, libdrm2, libgtk-3-0, libasound2, libxcomposite1, libxdamage1, libxrandr2, libgbm1/' figma-app/DEBIAN/control

# Build the package
dpkg-deb --build figma-app

echo "Package figma-app.deb built successfully from Electron source."
