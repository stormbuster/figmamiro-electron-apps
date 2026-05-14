import { app, BrowserWindow, BrowserView, session, globalShortcut } from 'electron';
import * as path from 'path';

// --- PERFORMANCE OPTIMIZATIONS ---
app.commandLine.appendSwitch('enable-gpu-rasterization');
app.commandLine.appendSwitch('enable-oop-rasterization');
app.commandLine.appendSwitch('enable-zero-copy');
app.commandLine.appendSwitch('enable-gpu-compositing');
app.commandLine.appendSwitch('enable-accelerated-2d-canvas');
app.commandLine.appendSwitch('ignore-gpu-blacklist');
app.commandLine.appendSwitch('use-gl', 'desktop');

let mainWindow: BrowserWindow | null = null;
let miroView: BrowserView | null = null;

const HEADER_HEIGHT = 32;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1280,
        height: 800,
        title: 'Miro',
        icon: path.join(__dirname, '../resources/icon.svg'),
        backgroundColor: '#ffffff',
        frame: process.platform === 'linux',
        titleBarStyle: 'hidden',
        trafficLightPosition: { x: 12, y: 10 },
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            sandbox: true,
        },
    });

    // --- SETUP BROWSERVIEW FOR MIRO ---
    miroView = new BrowserView({
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            sandbox: true,
            devTools: true,
            backgroundThrottling: false,
        },
    });

    mainWindow.setBrowserView(miroView);
    
    // Position the view below our custom title bar area
    const updateViewBounds = () => {
        if (mainWindow && miroView) {
            const { width, height } = mainWindow.getContentBounds();
            miroView.setBounds({ 
                x: 0, 
                y: HEADER_HEIGHT, 
                width: width, 
                height: height - HEADER_HEIGHT 
            });
        }
    };

    updateViewBounds();
    miroView.setAutoResize({ width: true, height: true });

    // --- LOAD MIRO ---
    const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    miroView.webContents.loadURL('https://miro.com', { userAgent });

    // --- MAIN WINDOW CONTENT (DRAG REGION) ---
    // We load a simple HTML string into the background window to make the top area draggable
    mainWindow.loadURL(`data:text/html,
        <style>
            body { 
                margin: 0; 
                overflow: hidden; 
                background: white; 
                -webkit-app-region: drag; 
                height: ${HEADER_HEIGHT}px;
                display: flex;
                align-items: center;
                justify-content: center;
            }
        </style>
        <body></body>
    `);

    // --- PERMISSION HANDLING ---
    const setupPermissions = (sess: Electron.Session) => {
        sess.setPermissionRequestHandler((webContents, permission, callback) => {
            const allowedPermissions = ['media', 'geolocation', 'notifications', 'pointerLock', 'fullscreen'];
            callback(allowedPermissions.includes(permission));
        });
        sess.setPermissionCheckHandler((webContents, permission, origin) => {
            return ['media', 'geolocation', 'notifications'].includes(permission);
        });
    };

    setupPermissions(session.defaultSession);
    if (miroView.webContents.session) {
        setupPermissions(miroView.webContents.session);
    }

    // --- WINDOW MANAGEMENT ---
    mainWindow.on('maximize', () => {
        mainWindow?.setFullScreen(true);
    });

    mainWindow.on('leave-full-screen', () => {
        mainWindow?.unmaximize();
    });

    // --- GLOBAL SHORTCUTS ---
    globalShortcut.register('F11', () => {
        mainWindow?.setFullScreen(!mainWindow.isFullScreen());
    });

    globalShortcut.register('CommandOrControl+Q', () => {
        app.quit();
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
        miroView = null;
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

app.on('will-quit', () => {
    globalShortcut.unregisterAll();
});
