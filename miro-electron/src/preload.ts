import { contextBridge } from 'electron';
contextBridge.exposeInMainWorld('miroFix', { version: '1.0.0' });
