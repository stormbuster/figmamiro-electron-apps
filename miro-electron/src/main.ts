import { app, BrowserWindow, session, globalShortcut } from 'electron';
import * as path from 'path';

// --- PERFORMANCE OPTIMIZATIONS (As per PRD) ---
app.commandLine.appendSwitch('enable-gpu-rasterization');
app.commandLine.appendSwitch('enable-oop-rasterization');
app.commandLine.appendSwitch('enable-zero-copy');
app.commandLine.appendSwitch('enable-gpu-compositing');
app.commandLine.appendSwitch('enable-accelerated-2d-canvas');
app.commandLine.appendSwitch('ignore-gpu-blacklist');
app.commandLine.appendSwitch('use-gl', 'desktop');

let mainWindow: BrowserWindow | null = null;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1280,
        height: 800,
        title: 'Miro',
        icon: path.join(__dirname, '../resources/icon.svg'),
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            sandbox: true,
            devTools: true,
            backgroundThrottling: false,
            preload: path.join(__dirname, 'preload.js'),
        },
        // elementary OS / native feel: rounded corners & frame
        frame: process.platform === 'linux',
        titleBarStyle: 'hidden',
        trafficLightPosition: { x: 12, y: 12 },
        backgroundColor: '#ffffff',
    });

    // --- HIDE DEFAULT MENU BAR ---
    mainWindow.setMenuBarVisibility(false);
    // Alternatively, to completely remove it:
    // import { Menu } from 'electron';
    // Menu.setApplicationMenu(null);

    // --- MIRO SPECIFIC USER AGENT ---
    const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    mainWindow.loadURL('https://miro.com', { userAgent });

    // --- RENDERER LOGGING ---
    mainWindow.webContents.on('console-message', (event, level, message, line, sourceId) => {
        console.log(`[Renderer] ${message}`);
    });

    // --- WHITE HEADER & DRAG REGION ---
    mainWindow.webContents.on('did-finish-load', () => {
        mainWindow?.webContents.insertCSS(`
            html {
                background-color: white !important;
                overflow: hidden !important;
            }
            body {
                position: absolute !important;
                top: 38px !important;
                bottom: 0 !important;
                left: 0 !important;
                right: 0 !important;
                margin: 0 !important;
                height: auto !important;
            }
            /* Inverted corner masks to create the 'nested' rounded look */
            body::before, body::after {
                content: '';
                position: fixed;
                top: 38px;
                width: 12px;
                height: 12px;
                background: white;
                z-index: 2147483647;
                pointer-events: none;
            }
            body::before {
                left: 0;
                background: radial-gradient(circle at 100% 100%, transparent 12px, white 12px);
            }
            body::after {
                right: 0;
                background: radial-gradient(circle at 0% 100%, transparent 12px, white 12px);
            }
            video {
                object-fit: cover !important;
            }
            #electron-drag-bar {
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 38px;
                background: white;
                z-index: 2147483647;
                -webkit-app-region: drag;
                pointer-events: none; /* Allow traffic lights to be clickable */
            }
            #electron-drag-bar * {
                pointer-events: auto;
            }
        `);
        
        mainWindow?.webContents.executeJavaScript(`
            if (!document.getElementById('electron-drag-bar')) {
                const dragBar = document.createElement('div');
                dragBar.id = 'electron-drag-bar';
                document.body.parentElement.appendChild(dragBar);
            }
        `);
    });

    // --- VIDEO ASPECT RATIO FIX (FORCE 1080P MJPEG + CSS COVER) ---
    const injectVideoFix = () => {
        mainWindow?.webContents.executeJavaScript(`
            (function() {
                const LOG_PREFIX = '[MiroVideoFix]';
                console.log(LOG_PREFIX, 'Hardware Lock Injected');
                
                if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
                    const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
                    navigator.mediaDevices.getUserMedia = async (constraints) => {
                        if (constraints && constraints.video && !constraints.video._isMiroFix) {
                            console.log(LOG_PREFIX, 'Intercepting getUserMedia for Hardware Lock');
                            
                            const miroVideoConstraints = typeof constraints.video === 'object' ? constraints.video : {};
                            const hardwareConstraints = {
                                ...constraints,
                                video: {
                                    ...miroVideoConstraints,
                                    width: { exact: 1920 },
                                    height: { exact: 1080 },
                                    frameRate: { exact: 60 },
                                    aspectRatio: { exact: 1.7777777778 },
                                    _isMiroFix: true
                                }
                            };

                            // Remove Miro's conflicting constraints
                            const v = hardwareConstraints.video;
                            if (v.width) { delete v.width.ideal; delete v.width.max; }
                            if (v.height) { delete v.height.ideal; delete v.height.max; }

                            try {
                                console.log(LOG_PREFIX, 'Requesting 1080p 60fps 16:9 lock...');
                                const stream = await originalGetUserMedia(hardwareConstraints);
                                return stream;
                            } catch (e) {
                                console.error(LOG_PREFIX, 'Hardware lock failed, falling back:', e);
                                return originalGetUserMedia(constraints);
                            }
                        }
                        return originalGetUserMedia(constraints);
                    };
                }

                console.log(LOG_PREFIX, 'Hardware Lock Overrides active.');
            })();
        `);
    };

    mainWindow.webContents.on('did-navigate', injectVideoFix);
    mainWindow.webContents.on('did-frame-finish-load', injectVideoFix);

    // --- STRIP CSP TO ALLOW OVERRIDES ---
    session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
        if (details.responseHeaders) {
            delete details.responseHeaders['content-security-policy'];
            delete details.responseHeaders['Content-Security-Policy'];
        }
        callback({ responseHeaders: details.responseHeaders });
    });

    // --- STRIP CSP TO ALLOW OVERRIDES ---

    // --- PERMISSION HANDLING (Camera, Mic, Geolocation) ---
    session.defaultSession.setPermissionRequestHandler((webContents, permission, callback) => {
        const allowedPermissions = ['media', 'geolocation', 'notifications', 'pointerLock', 'fullscreen'];
        if (allowedPermissions.includes(permission)) {
            callback(true);
        } else {
            callback(false);
        }
    });

    // Support for specific user media (Camera/Mic)
    session.defaultSession.setPermissionCheckHandler((webContents, permission, origin) => {
        return ['media', 'geolocation', 'notifications'].includes(permission);
    });

    // --- WINDOW MANAGEMENT (Maximize to Fullscreen Logic) ---
    mainWindow.on('maximize', () => {
        if (mainWindow) {
            mainWindow.setFullScreen(true);
            mainWindow.setMenuBarVisibility(false);
        }
    });

    mainWindow.on('leave-full-screen', () => {
        if (mainWindow) {
            mainWindow.setMenuBarVisibility(true);
            mainWindow.unmaximize();
        }
    });

    // --- GLOBAL SHORTCUTS ---
    globalShortcut.register('F11', () => {
        if (mainWindow) {
            mainWindow.setFullScreen(!mainWindow.isFullScreen());
        }
    });

    globalShortcut.register('CommandOrControl+Q', () => {
        app.quit();
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

app.whenReady().then(() => {
    createWindow();

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

// Clean up shortcuts on quit
app.on('will-quit', () => {
    globalShortcut.unregisterAll();
});
