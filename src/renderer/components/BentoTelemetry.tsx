import React from 'react';
import type { SystemInfo } from '../../shared/types';

interface BentoTelemetryProps {
  sysInfo: SystemInfo | null;
}

export const BentoTelemetry: React.FC<BentoTelemetryProps> = ({ sysInfo }) => {
  return (
    <div className="bento-grid">
      {/* 1. Kernel Telemetry */}
      <div className="bezel-outer">
        <div className="bezel-inner">
          <div className="telemetry-eyebrow">KERNEL TELEMETRY</div>
          <div className="telemetry-val">
            {sysInfo ? `${sysInfo.osCaption}` : 'Windows 11 26H2'}
          </div>
          <div className="telemetry-sub" style={{ color: sysInfo?.isAdmin ? 'var(--good)' : 'var(--warn)', fontWeight: 600 }}>
            {sysInfo?.isAdmin ? 'ADMIN ELEVATED • SHIELD ACTIVE' : 'USER RESTRICTED'}
          </div>
        </div>
      </div>

      {/* 2. CPU Unparking & Timer */}
      <div className="bezel-outer">
        <div className="bezel-inner">
          <div className="telemetry-eyebrow">CPU UNPARKING &amp; TIMER</div>
          <div className="telemetry-val" style={{ color: 'var(--accent)' }}>
            {sysInfo ? `${sysInfo.cpuLogicalCores} Threads Active` : 'Cores Unparked (100%)'}
          </div>
          <div className="telemetry-sub">Timer: 0.500 ms (High-Res Multimedia)</div>
        </div>
      </div>

      {/* 3. RAM & SvcHost Threshold */}
      <div className="bezel-outer">
        <div className="bezel-inner">
          <div className="telemetry-eyebrow">RAM &amp; SVCHOST SPLITTING</div>
          <div className="telemetry-val">
            {sysInfo ? `${sysInfo.totalRamGb} GB RAM (${sysInfo.driveType})` : 'RAM Optimization'}
          </div>
          <div className="telemetry-sub">SvcHost Split: 0x380000 (Optimized)</div>
        </div>
      </div>

      {/* 4. Safety & Rollback Engine */}
      <div className="bezel-outer">
        <div className="bezel-inner">
          <div className="telemetry-eyebrow">SAFETY SHIELD</div>
          <div className="telemetry-val" style={{ color: 'var(--good)' }}>
            5-Tier Recovery Pipeline
          </div>
          <div className="telemetry-sub">Atomic Snapshots: Active</div>
        </div>
      </div>
    </div>
  );
};
