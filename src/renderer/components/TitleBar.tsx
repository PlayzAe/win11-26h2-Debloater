import React from 'react';
import { ShieldCheck } from 'lucide-react';

interface TitleBarProps {
  dryRun: boolean;
  onToggleDryRun: () => void;
  onCreateRestorePoint: () => void;
  isCreatingRestorePoint: boolean;
}

export const TitleBar: React.FC<TitleBarProps> = ({
  dryRun,
  onToggleDryRun,
  onCreateRestorePoint,
  isCreatingRestorePoint,
}) => {
  return (
    <header className="titlebar">
      <div className="titlebar-left">
        <span
          className="pulsing-led"
          style={{
            display: 'inline-block',
            width: 8,
            height: 8,
            borderRadius: '50%',
            background: 'var(--accent)',
            boxShadow: '0 0 10px var(--accent)',
          }}
        />
        <span style={{ fontSize: 13, fontWeight: 800, letterSpacing: '-0.01em', color: 'var(--paper)' }}>
          PLAYZDEBLOAT
        </span>
        <span className="brand-badge">26H2 TACTICAL</span>
      </div>

      <div className="titlebar-right">
        <button
          className="sim-switch"
          onClick={onToggleDryRun}
          title="Toggle zero-mutation simulation mode"
        >
          <input
            type="checkbox"
            checked={dryRun}
            onChange={() => {}}
            style={{ accentColor: 'var(--warn)', cursor: 'pointer' }}
          />
          <span>{dryRun ? 'DRY-RUN SIMULATION ACTIVE' : 'LIVE SYSTEM MODE'}</span>
        </button>

        <button
          className="btn-primary"
          style={{ padding: '4px 12px', fontSize: 11 }}
          onClick={onCreateRestorePoint}
          disabled={isCreatingRestorePoint}
        >
          <ShieldCheck size={14} />
          <span>{isCreatingRestorePoint ? 'Creating...' : 'Create Restore Point'}</span>
        </button>
      </div>
    </header>
  );
};
