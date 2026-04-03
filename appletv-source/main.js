const { app, BrowserWindow, session } = require('electron');

let mainWindow;

// Disable HW acceleration to force software L3 DRM path (fixes Haswell/Linux "fade to black" issue)
app.disableHardwareAcceleration();

app.commandLine.appendSwitch('enable-widevine-cdm');
app.commandLine.appendSwitch('no-sandbox');
app.commandLine.appendSwitch('disable-gpu-sandbox');
app.commandLine.appendSwitch('disable-accelerated-video-decode');
app.commandLine.appendSwitch('disable-gpu-rasterization');
app.commandLine.appendSwitch('disable-oop-rasterization');
app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 720,
    fullscreen: true,
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      plugins: true,
      sandbox: false
    }
  });

  // Windows User Agent is often required by Apple TV for a more stable Widevine negotiation
  mainWindow.webContents.setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36");
  mainWindow.loadURL('https://tv.apple.com/');

  // Hide scrollbars for a cleaner native look
  mainWindow.webContents.on('did-finish-load', () => {
    mainWindow.webContents.insertCSS('::-webkit-scrollbar { display: none !important; }');
  });

  // Handle F11 for fullscreen toggle
  mainWindow.webContents.on('before-input-event', (event, input) => {
    if (input.key === 'F11' && input.type === 'keyDown') {
      mainWindow.setFullScreen(!mainWindow.isFullScreen());
      event.preventDefault();
    }
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.setAppUserModelId('com.appletv.native');

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});
