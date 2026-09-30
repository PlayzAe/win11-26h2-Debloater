import React, { useState } from 'react';
import { History, RotateCcw, FolderOpen, ShieldCheck, CheckCircle2, AlertOctagon } from 'lucide-react';
import type { SessionAction } from '../../shared/types';

interface RollbackViewProps {
  actions: SessionAction[];
  onRollbackSession: () => Promise<void>;
  onCreateRestorePoint: () => Promise<void>;
  onOpenBackupsDir: () => Promise<void>;
  isExecuting: boolean;
}

export const RollbackView: React.FC<RollbackViewProps> = ({
  actions,
  onRollbackSession,
  onCreateRestorePoint,
  onOpenBackupsDir,
  isExecuting,
}) => {
  const [isRollingBack, setIsRollingBack] = useState(false);
  const [isCreatingPoint, setIsCreatingPoint] = useState(false);

  const handleRollback = async () => {
    setIsRollingBack(true);
    try {
      await onRollbackSession();
    } finally {
      setIsRollingBack(false);
    }
  };

  const handleCreatePoint = async () => {
    setIsCreatingPoint(true);
    try {
      await onCreateRestorePoint();
    } finally {
      setIsCreatingPoint(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div className="section-header">
        <div>
          <h2 className="section-title">Rollback, Snapshots &amp; Rescue</h2>
          <p className="section-sub">
            Complete five-tier recovery pipeline. Every registry mutation, app removal, and service state change is journaled for 100% atomic reversal.
          </p>
        </div>
      </div>

      {/* Primary Rescue Actions */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14 }}>
        <div className="bezel-outer">
          <div className="bezel-inner" style={{ padding: 18, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: 12 }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                <RotateCcw size={20} style={{ color: 'var(--bad)' }} />
                <h3 style={{ fontSize: 15, fontWeight: 780, color: 'var(--paper)' }}>1-Click Session Rollback</h3>
              </div>
              <p style={{ fontSize: 12, color: 'var(--paper-2)', lineHeight: 1.45 }}>
                Reverts all actions executed in the active session by playing back the undo journal in reverse order.
              </p>
            </div>
            <button
              className="btn-danger"
              style={{ width: '100%', justifyContent: 'center' }}
              onClick={handleRollback}
              disabled={isExecuting || isRollingBack}
            >
              <RotateCcw size={13} />
              <span>{isRollingBack ? 'Rolling Back...' : 'Execute Full Session Rollback'}</span>
            </button>
          </div>
        </div>

        <div className="bezel-outer">
          <div className="bezel-inner" style={{ padding: 18, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: 12 }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                <ShieldCheck size={20} style={{ color: 'var(--good)' }} />
                <h3 style={{ fontSize: 15, fontWeight: 780, color: 'var(--paper)' }}>Windows Restore Point</h3>
              </div>
              <p style={{ fontSize: 12, color: 'var(--paper-2)', lineHeight: 1.45 }}>
                Creates a genuine VSS (Volume Shadow Copy) Windows System Restore Point named "Win11_26H2_Debloater_PreFlight".
              </p>
            </div>
            <button
              className="btn-primary"
              style={{ width: '100%', justifyContent: 'center' }}
              onClick={handleCreatePoint}
              disabled={isExecuting || isCreatingPoint}
            >
              <ShieldCheck size={13} />
              <span>{isCreatingPoint ? 'Creating Point...' : 'Create Restore Point'}</span>
            </button>
          </div>
        </div>

        <div className="bezel-outer">
          <div className="bezel-inner" style={{ padding: 18, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: 12 }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                <FolderOpen size={20} style={{ color: 'var(--accent)' }} />
                <h3 style={{ fontSize: 15, fontWeight: 780, color: 'var(--paper)' }}>Inspect Journal Logs</h3>
              </div>
              <p style={{ fontSize: 12, color: 'var(--paper-2)', lineHeight: 1.45 }}>
                Opens the local <code style={{ color: 'var(--accent)' }}>backups/</code> folder in File Explorer to inspect timestamped session logs and undo JSON files.
              </p>
            </div>
            <button
              className="btn-secondary"
              style={{ width: '100%', justifyContent: 'center' }}
              onClick={onOpenBackupsDir}
              disabled={isExecuting}
            >
              <FolderOpen size={13} />
              <span>Open Backups Folder</span>
            </button>
          </div>
        </div>
      </div>

      {/* Session Actions History Timeline */}
      <div style={{ marginTop: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
          <h3 style={{ fontSize: 14, fontWeight: 780, color: 'var(--paper)' }}>
            Active Session Undo Journal ({actions.length} Operations Recorded)
          </h3>
        </div>

        {actions.length === 0 ? (
          <div
            style={{
              padding: 32,
              textAlign: 'center',
              color: 'var(--paper-3)',
              background: 'var(--ink-1)',
              borderRadius: 'var(--radius-2)',
              border: '1px solid var(--line)',
              fontSize: 12.5,
            }}
          >
            No mutations recorded in the active session journal yet. Your system is untouched.
          </div>
        ) : (
          <div className="cards-list">
            {actions.map((act, idx) => (
              <div key={idx} className="bezel-outer">
                <div className="bezel-inner item-card" style={{ padding: '10px 16px' }}>
                  <div>
                    <div className="item-head">
                      <span className="badge badge-accent">{act.actionType}</span>
                      <span className="item-name" style={{ fontSize: 13 }}>
                        {act.targetId}
                      </span>
                    </div>
                    <div className="item-desc" style={{ fontSize: 12 }}>
                      {act.description}
                    </div>
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--paper-3)', fontFamily: 'var(--font-mono)' }}>
                    {act.timestamp}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
