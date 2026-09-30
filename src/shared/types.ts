export interface SystemInfo {
  osCaption: string;
  buildNumber: string;
  cpuName: string;
  cpuCores: number;
  cpuLogicalCores: number;
  totalRamGb: number;
  driveType: string;
  isAdmin: boolean;
}

export interface AppItem {
  id: string;
  name: string;
  risk: 'Safe' | 'Moderate' | 'High' | 'Critical';
  descriptionSimple: string;
  descriptionTech: string;
  installed?: boolean;
}

export interface TweakItem {
  id: string;
  name: string;
  category: string;
  risk: string;
  descriptionSimple: string;
  descriptionTech: string;
  hive: string;
  path: string;
  valueName: string;
  type: string;
  value: any;
  originalValue: any;
}

export interface GamingOptimization {
  id: string;
  name: string;
  risk: string;
  descriptionSimple: string;
  descriptionTech: string;
}

export interface ServiceItem {
  name: string;
  displayName: string;
  action: 'Disable' | 'Protect';
  recommendedStartType: string;
  descriptionSimple: string;
}

export interface SessionAction {
  timestamp: string;
  actionType: string;
  targetId: string;
  description: string;
}

export interface LogMessage {
  timestamp: string;
  line: string;
  level: 'INFO' | 'WARN' | 'ERROR' | 'SUCCESS' | 'UNDO';
}

export interface DebloatApi {
  getSystemInfo: () => Promise<SystemInfo>;
  getApps: () => Promise<AppItem[]>;
  getTweaks: () => Promise<TweakItem[]>;
  getGaming: () => Promise<GamingOptimization[]>;
  getServices: () => Promise<ServiceItem[]>;
  getSessionActions: () => Promise<SessionAction[]>;
  applyPreset: (presetId: 'gaming' | 'privacy' | 'full', dryRun: boolean) => Promise<{ success: boolean; message: string }>;
  removeApp: (appId: string, dryRun: boolean) => Promise<{ success: boolean; message: string }>;
  restoreApp: (appId: string, dryRun: boolean) => Promise<{ success: boolean; message: string }>;
  setTweak: (tweak: TweakItem, dryRun: boolean) => Promise<{ success: boolean; message: string }>;
  restoreTweak: (tweak: TweakItem, dryRun: boolean) => Promise<{ success: boolean; message: string }>;
  tuneGaming: (optId: string, dryRun: boolean) => Promise<{ success: boolean; message: string }>;
  setService: (serviceName: string, startType: string, dryRun: boolean) => Promise<{ success: boolean; message: string }>;
  restoreService: (serviceName: string, dryRun: boolean) => Promise<{ success: boolean; message: string }>;
  createRestorePoint: () => Promise<{ success: boolean; message: string }>;
  rollbackSession: () => Promise<{ success: boolean; message: string }>;
  openBackupsDir: () => Promise<void>;
  onLog: (callback: (log: LogMessage) => void) => () => void;
  windowControl: (action: 'minimize' | 'maximize' | 'close') => Promise<void>;
}

declare global {
  interface Window {
    debloatApi: DebloatApi;
  }
}
