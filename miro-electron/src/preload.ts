import { contextBridge, ipcRenderer } from 'electron';

// Permission Primer: Force the OS to prompt by requesting a tiny stream
async function primePermissions() {
    console.log('[Preload] Priming permissions...');
    try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
        console.log('[Preload] Permission stream acquired successfully!');
        // Immediately stop the stream so we don't hog the camera
        stream.getTracks().forEach(track => track.stop());
    } catch (err) {
        console.error('[Preload] Permission priming failed:', err);
    }
}

// Run the primer on load
window.addEventListener('DOMContentLoaded', () => {
    const dragBar = document.createElement('div');
    dragBar.id = 'electron-drag-bar';
    document.body.appendChild(dragBar);
    
    // Attempt to prime permissions after a short delay
    setTimeout(primePermissions, 2000);
});

contextBridge.exposeInMainWorld('electron', {
    // Add any needed APIs here
});
