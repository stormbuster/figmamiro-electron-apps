import { app, BrowserWindow, session, globalShortcut, systemPreferences } from 'electron';
import * as path from 'path';

let mainWindow: BrowserWindow | null = null;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1280,
        height: 800,
        title: 'Miro Pro',
        icon: path.join(__dirname, '../resources/electron.icns'),
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            sandbox: false,
            preload: path.join(__dirname, 'preload.js'),
        },
        titleBarStyle: 'hidden',
        trafficLightPosition: { x: 12, y: 12 },
        backgroundColor: '#1A1A1A',
    });

    const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    mainWindow.loadURL('https://miro.com', { userAgent });

    mainWindow.webContents.on('did-finish-load', () => {
        mainWindow?.webContents.insertCSS(`
            html { background-color: #1A1A1A !important; }
            body {
                position: absolute !important;
                top: 38px !important; bottom: 0 !important; left: 0 !important; right: 0 !important;
                margin: 0 !important; height: auto !important;
            }
            video { object-fit: cover !important; }
            #electron-drag-bar {
                position: fixed; top: 0; left: 0; width: 100%; height: 38px;
                background: #1A1A1A; z-index: 2147483647; -webkit-app-region: drag; pointer-events: none;
            }
        `);
    });

    globalShortcut.register('CommandOrControl+Q', () => { app.quit(); });
    mainWindow.on('closed', () => { mainWindow = null; });
}

app.whenReady().then(async () => {
    console.log('[App] Ready. Using Preload Primer for permissions.');
    
    session.defaultSession.setPermissionRequestHandler((webContents, permission, callback) => {
        console.log(`[PermissionRequest] Main Process approving: ${permission}`);
        callback(true);
    });
    
    session.defaultSession.setPermissionCheckHandler(() => true);

    createWindow();
});

app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });
app.on('will-quit', () => { globalShortcut.unregisterAll(); });
