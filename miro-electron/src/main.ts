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
        },
        // elementary OS / native feel: rounded corners & frame
        frame: true, 
    });

    // --- HIDE DEFAULT MENU BAR ---
    mainWindow.setMenuBarVisibility(false);
    // Alternatively, to completely remove it:
    // import { Menu } from 'electron';
    // Menu.setApplicationMenu(null);

    // --- MIRO SPECIFIC USER AGENT ---
    const userAgent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    mainWindow.loadURL('https://miro.com', { userAgent });

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
