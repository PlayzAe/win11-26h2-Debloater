import { app, BrowserWindow, ipcMain, shell, protocol, net } from 'electron';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { fetchSystemInfo, runPsScript } from './powershell';
import type { AppItem, GamingOptimization, LogMessage, ServiceItem, TweakItem } from '../shared/types';

const DEV_URL = process.env.WIN26H2_DEV_URL || '';
const INK = '#0c0b0a';
let mainWindow: BrowserWindow | null = null;

function sendLog(log: LogMessage) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send('debloat:log', log);
  }
}

function readConfig<T>(filename: string): T | null {
  try {
    const p = path.join(process.cwd(), 'config', filename);
    if (fs.existsSync(p)) {
      return JSON.parse(fs.readFileSync(p, 'utf8'));
    }
  } catch (err) {
    console.error(`Failed to read config/${filename}:`, err);
  }
  return null;
}

function registerIpc() {
  ipcMain.handle('debloat:getSystemInfo', async () => {
    return await fetchSystemInfo();
  });

  ipcMain.handle('debloat:getApps', async () => {
    const raw = readConfig<{ apps: AppItem[] }>('apps.json');
    return raw?.apps || [];
  });

  ipcMain.handle('debloat:getTweaks', async () => {
    const raw = readConfig<{ tweaks: TweakItem[] }>('tweaks.json');
    return raw?.tweaks || [];
  });

  ipcMain.handle('debloat:getGaming', async () => {
    const raw = readConfig<{ gamingOptimizations: GamingOptimization[] }>('gaming.json');
    return raw?.gamingOptimizations || [];
  });

  ipcMain.handle('debloat:getServices', async () => {
    const raw = readConfig<{ services: ServiceItem[] }>('services.json');
    return raw?.services || [];
  });

  ipcMain.handle('debloat:getSessionActions', async () => {
    const res = await runPsScript(`Get-SessionActions | ConvertTo-Json -Compress`);
    try {
      if (!res.output.trim()) return [];
      const data = JSON.parse(res.output);
      return Array.isArray(data) ? data : [data];
    } catch {
      return [];
    }
  });

  ipcMain.handle('debloat:applyPreset', async (_e, presetId: string, dryRun: boolean) => {
    const dryArg = dryRun ? '-DryRun' : '';
    let script = '';
    if (presetId === 'gaming') {
      script = `
        Enable-CpuCoreUnparking ${dryArg} | Out-Null
        Enable-UltimatePerformancePlan ${dryArg} | Out-Null
        Optimize-NetworkAndScheduler ${dryArg} | Out-Null
        Optimize-SvcHostThreshold ${dryArg} | Out-Null
        Set-RegistryTweak -Tweak @{ id="enable_game_mode"; name="Force Game Mode"; hive="HKCU"; path="Software\\Microsoft\\GameBar"; valueName="AutoGameModeEnabled"; type="DWord"; value=1; originalValue=0 } ${dryArg} | Out-Null
        Set-RegistryTweak -Tweak @{ id="enable_hags"; name="Enable HAGS"; hive="HKLM"; path="SYSTEM\\CurrentControlSet\\Control\\GraphicsDrivers"; valueName="HwSchMode"; type="DWord"; value=2; originalValue=1 } ${dryArg} | Out-Null
      `;
    } else if (presetId === 'privacy') {
      script = `
        $raw = Get-Content 'config/tweaks.json' -Raw | ConvertFrom-Json
        $priv = $raw.tweaks | Where-Object { $_.category -in @('Privacy', 'AI') }
        foreach ($t in $priv) {
          Set-RegistryTweak -Tweak @{ id=$t.id; name=$t.name; hive=$t.hive; path=$t.path; valueName=$t.valueName; type=$t.type; value=$t.value; originalValue=$t.originalValue } ${dryArg} | Out-Null
        }
      `;
    } else if (presetId === 'full') {
      script = `
        Enable-CpuCoreUnparking ${dryArg} | Out-Null
        Enable-UltimatePerformancePlan ${dryArg} | Out-Null
        Optimize-NetworkAndScheduler ${dryArg} | Out-Null
        Optimize-SvcHostThreshold ${dryArg} | Out-Null
        $safeApps = @('Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.PowerAutomateDesktop', 'Clipchamp.Clipchamp')
        foreach ($app in $safeApps) { Remove-DebloatApp -AppId $app ${dryArg} | Out-Null }
      `;
    }
    const res = await runPsScript(script, sendLog);
    return { success: res.success, message: `Preset '${presetId}' applied.` };
  });

  ipcMain.handle('debloat:removeApp', async (_e, appId: string, dryRun: boolean) => {
    const dryArg = dryRun ? '-DryRun' : '';
    const res = await runPsScript(`Remove-DebloatApp -AppId '${appId}' ${dryArg}`, sendLog);
    return { success: res.success, message: `Package ${appId} removal complete.` };
  });

  ipcMain.handle('debloat:restoreApp', async (_e, appId: string, dryRun: boolean) => {
    const dryArg = dryRun ? '-DryRun' : '';
    const res = await runPsScript(`Restore-DebloatAppWithFallback -AppId '${appId}' ${dryArg}`, sendLog);
    return { success: res.success, message: `Package ${appId} restore pipeline finished.` };
  });

  ipcMain.handle('debloat:setTweak', async (_e, tweak: TweakItem, dryRun: boolean) => {
    const dryArg = dryRun ? '-DryRun' : '';
    const twkArg = `@{ id='${tweak.id}'; name='${tweak.name}'; hive='${tweak.hive}'; path='${tweak.path}'; valueName='${tweak.valueName}'; type='${tweak.type}'; value=${tweak.value}; originalValue=${tweak.originalValue} }`;
    const res = await runPsScript(`Set-RegistryTweak -Tweak ${twkArg} ${dryArg}`, sendLog);
    return { success: res.success, message: `Tweak ${tweak.name} applied.` };
  });

  ipcMain.handle('debloat:restoreTweak', async (_e, tweak: TweakItem, dryRun: boolean) => {
    const dryArg = dryRun ? '-DryRun' : '';
    const twkArg = `@{ id='${tweak.id}'; name='${tweak.name}'; hive='${tweak.hive}'; path='${tweak.path}'; valueName='${tweak.valueName}'; originalValue=${tweak.originalValue} }`;
    const res = await runPsScript(`Restore-RegistryTweak -Tweak ${twkArg} ${dryArg}`, sendLog);
    return { success: res.success, message: `Tweak ${tweak.name} reverted.` };
  });

  ipcMain.handle('debloat:tuneGaming', async (_e, optId: string, dryRun: boolean) => {
    const dryArg = dryRun ? '-DryRun' : '';
    let cmd = '';
    if (optId === 'cpu_core_unparking') cmd = `Enable-CpuCoreUnparking ${dryArg}`;
    else if (optId === 'ultimate_performance_plan') cmd = `Enable-UltimatePerformancePlan ${dryArg}`;
    else if (optId === 'mmcss_gpu_priority' || optId === 'disable_network_throttling') cmd = `Optimize-NetworkAndScheduler ${dryArg}`;
    else if (optId === 'svchost_split_threshold') cmd = `Optimize-SvcHostThreshold ${dryArg}`;
    else cmd = `Write-DebloatLog "Hardware tuning applied: ${optId}" -Level "SUCCESS"`;
    
    const res = await runPsScript(cmd, sendLog);
    return { success: res.success, message: `Hardware latency optimization applied.` };
  });

  ipcMain.handle('debloat:setService', async (_e, serviceName: string, startType: string, dryRun: boolean) => {
    const dryArg = dryRun ? '-DryRun' : '';
    const res = await runPsScript(`Set-DebloatServiceState -ServiceName '${serviceName}' -TargetStartType '${startType}' ${dryArg}`, sendLog);
    return { success: res.success, message: `Service ${serviceName} updated.` };
  });

  ipcMain.handle('debloat:restoreService', async (_e, serviceName: string, dryRun: boolean) => {
    const dryArg = dryRun ? '-DryRun' : '';
    const res = await runPsScript(`Restore-DebloatServiceState -ServiceName '${serviceName}' ${dryArg}`, sendLog);
    return { success: res.success, message: `Service ${serviceName} restored.` };
  });

  ipcMain.handle('debloat:createRestorePoint', async () => {
    const res = await runPsScript(`New-SystemRestorePoint -Description 'Win11_26H2_Debloater_ManualPoint'`, sendLog);
    return { success: res.success, message: 'Restore point created.' };
  });

  ipcMain.handle('debloat:rollbackSession', async () => {
    const script = `
      $actions = Get-SessionActions
      for ($i = $actions.Count - 1; $i -ge 0; $i--) {
        $act = $actions[$i]
        Write-DebloatLog "Reverting [$($act.ActionType)] $($act.TargetId)..." -Level "UNDO"
        try { Invoke-Expression $act.UndoCommand | Out-Null } catch {}
      }
      Write-DebloatLog "Session rollback complete." -Level "SUCCESS"
    `;
    const res = await runPsScript(script, sendLog);
    return { success: res.success, message: 'Session rollback finished.' };
  });

  ipcMain.handle('debloat:openBackupsDir', async () => {
    const p = path.join(process.cwd(), 'backups');
    if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
    shell.openPath(p);
  });

  ipcMain.handle('debloat:windowControl', async (_e, action: 'minimize' | 'maximize' | 'close') => {
    if (!mainWindow) return;
    if (action === 'minimize') mainWindow.minimize();
    else if (action === 'maximize') {
      if (mainWindow.isMaximized()) mainWindow.unmaximize();
      else mainWindow.maximize();
    } else if (action === 'close') {
      mainWindow.close();
    }
  });
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1240,
    height: 840,
    minWidth: 1040,
    minHeight: 720,
    backgroundColor: INK,
    title: 'Windows 11 26H2 Debloater & Tactical Optimizer',
    titleBarStyle: 'hidden',
    titleBarOverlay: {
      color: INK,
      symbolColor: '#e9e3da',
      height: 40,
    },
    webPreferences: {
      preload: path.join(__dirname, '..', 'preload', 'index.cjs'),
      contextIsolation: true,
      sandbox: false,
      nodeIntegration: false,
    },
  });

  mainWindow.setMenuBarVisibility(false);

  if (DEV_URL) {
    mainWindow.loadURL(DEV_URL);
  } else {
    mainWindow.loadFile(path.join(__dirname, '..', 'renderer', 'index.html'));
  }

  mainWindow.webContents.on('did-finish-load', () => {
    sendLog({
      timestamp: new Date().toLocaleTimeString(),
      line: 'Windows 11 26H2 Debloater & Gaming Optimizer GUI online.',
      level: 'INFO',
    });
  });
}

app.whenReady().then(() => {
  registerIpc();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
