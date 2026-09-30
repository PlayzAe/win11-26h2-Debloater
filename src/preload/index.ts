import { contextBridge, ipcRenderer } from 'electron';
import type { DebloatApi, LogMessage, TweakItem } from '../shared/types';

const call = <T>(channel: string) => (...args: unknown[]) =>
  ipcRenderer.invoke(channel, ...args) as Promise<T>;

function listen<T>(channel: string, listener: (payload: T) => void) {
  const wrapped = (_e: unknown, payload: T) => listener(payload);
  ipcRenderer.on(channel, wrapped);
  return () => {
    ipcRenderer.removeListener(channel, wrapped);
  };
}

const api: DebloatApi = {
  getSystemInfo: call('debloat:getSystemInfo'),
  getApps: call('debloat:getApps'),
  getTweaks: call('debloat:getTweaks'),
  getGaming: call('debloat:getGaming'),
  getServices: call('debloat:getServices'),
  getSessionActions: call('debloat:getSessionActions'),
  applyPreset: call('debloat:applyPreset'),
  removeApp: call('debloat:removeApp'),
  restoreApp: call('debloat:restoreApp'),
  setTweak: call('debloat:setTweak'),
  restoreTweak: call('debloat:restoreTweak'),
  tuneGaming: call('debloat:tuneGaming'),
  setService: call('debloat:setService'),
  restoreService: call('debloat:restoreService'),
  createRestorePoint: call('debloat:createRestorePoint'),
  rollbackSession: call('debloat:rollbackSession'),
  openBackupsDir: call('debloat:openBackupsDir'),
  onLog: (callback) => listen<LogMessage>('debloat:log', callback),
  windowControl: call('debloat:windowControl'),
};

contextBridge.exposeInMainWorld('debloatApi', api);
