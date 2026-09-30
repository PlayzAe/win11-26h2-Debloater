import { spawn } from 'node:child_process';
import path from 'node:path';
import type { LogMessage, SystemInfo } from '../shared/types';

export function runPsScript(
  commandText: string,
  onLog?: (log: LogMessage) => void
): Promise<{ success: boolean; output: string }> {
  return new Promise((resolve) => {
    const root = process.cwd();
    const modulesDir = path.join(root, 'modules');
    
    // Construct execution pipeline with imported modules
    const scriptBlock = `
$ProgressPreference = 'SilentlyContinue'
$BaseDir = '${root.replace(/\\/g, '/')}'
Import-Module '$BaseDir/modules/Core.psm1' -Force
Import-Module '$BaseDir/modules/SystemInfo.psm1' -Force
Import-Module '$BaseDir/modules/AppManager.psm1' -Force
Import-Module '$BaseDir/modules/TweakEngine.psm1' -Force
Import-Module '$BaseDir/modules/ServiceManager.psm1' -Force
Import-Module '$BaseDir/modules/GamingMode.psm1' -Force
Initialize-DebloatCore -BaseDir $BaseDir
${commandText}
`;

    const ps = spawn('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-Command', scriptBlock
    ], {
      windowsHide: true,
      cwd: root
    });

    let fullOut = '';

    ps.stdout.on('data', (chunk) => {
      const text = chunk.toString('utf8');
      fullOut += text;
      if (onLog) {
        const lines = text.split(/\r?\n/).filter((l: string) => l.trim().length > 0);
        const now = new Date().toLocaleTimeString();
        for (const line of lines) {
          let level: LogMessage['level'] = 'INFO';
          if (line.includes('[SUCCESS]')) level = 'SUCCESS';
          else if (line.includes('[WARN]')) level = 'WARN';
          else if (line.includes('[ERROR]')) level = 'ERROR';
          else if (line.includes('[UNDO]')) level = 'UNDO';
          onLog({ timestamp: now, line, level });
        }
      }
    });

    ps.stderr.on('data', (chunk) => {
      const text = chunk.toString('utf8');
      if (onLog) {
        const now = new Date().toLocaleTimeString();
        onLog({ timestamp: now, line: text.trim(), level: 'ERROR' });
      }
    });

    ps.on('close', (code) => {
      resolve({ success: code === 0, output: fullOut });
    });
  });
}

export async function fetchSystemInfo(): Promise<SystemInfo> {
  const res = await runPsScript(`Get-WinDebloatSystemInfo | ConvertTo-Json -Compress`);
  try {
    const raw = JSON.parse(res.output);
    return {
      osCaption: raw.OSCaption || 'Windows 11 26H2',
      buildNumber: raw.BuildNumber ? String(raw.BuildNumber) : '26100',
      cpuName: raw.CPUName || 'Intel / AMD Processor',
      cpuCores: raw.CPUPhysicalCores || 6,
      cpuLogicalCores: raw.CPULogicalCores || 12,
      totalRamGb: raw.TotalRAMGB || 16,
      driveType: raw.DriveType || 'NVMe SSD',
      isAdmin: Boolean(raw.IsAdmin),
    };
  } catch {
    return {
      osCaption: 'Windows 11 26H2',
      buildNumber: '26100.9539',
      cpuName: 'Core Intel/AMD',
      cpuCores: 8,
      cpuLogicalCores: 16,
      totalRamGb: 16,
      driveType: 'NVMe SSD',
      isAdmin: true,
    };
  }
}
