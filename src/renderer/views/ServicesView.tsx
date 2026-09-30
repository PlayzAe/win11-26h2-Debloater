import React, { useState } from 'react';
import { ShieldAlert, ShieldCheck, Lock, RotateCcw, PowerOff, CheckCircle } from 'lucide-react';
import type { ServiceItem } from '../../shared/types';

interface ServicesViewProps {
  services: ServiceItem[];
  dryRun: boolean;
  onSetService: (serviceName: string, startType: string) => Promise<void>;
  onRestoreService: (serviceName: string) => Promise<void>;
  isExecuting: boolean;
}

export const ServicesView: React.FC<ServicesViewProps> = ({
  services,
  dryRun,
  onSetService,
  onRestoreService,
  isExecuting,
}) => {
  const [processingName, setProcessingName] = useState<string | null>(null);

  const handleDisable = async (svc: ServiceItem) => {
    setProcessingName(svc.name);
    try {
      await onSetService(svc.name, 'Disabled');
    } finally {
      setProcessingName(null);
    }
  };

  const handleRestore = async (svc: ServiceItem) => {
    setProcessingName(svc.name);
    try {
      await onRestoreService(svc.name);
    } finally {
      setProcessingName(null);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div className="section-header">
        <div>
          <h2 className="section-title">Background Services Manager</h2>
          <p className="section-sub">
            Audit and control telemetry workers, diagnostic listeners, and background daemon lifecycles.
          </p>
        </div>
      </div>

      <div className="cards-list">
        {services.map((svc) => {
          const isProtected = svc.action === 'Protect';
          const isBusy = isExecuting && processingName === svc.name;

          return (
            <div key={svc.name} className="bezel-outer">
              <div className="bezel-inner item-card">
                <div>
                  <div className="item-head">
                    <span className="item-name">{svc.displayName}</span>
                    {isProtected ? (
                      <span
                        className="badge badge-safe"
                        style={{ display: 'flex', alignItems: 'center', gap: 4 }}
                      >
                        <Lock size={10} />
                        <span>PROTECTED SERVICE</span>
                      </span>
                    ) : (
                      <span className="badge badge-warn">TELEMETRY SERVICE</span>
                    )}
                  </div>

                  <div className="item-desc">{svc.descriptionSimple}</div>
                  <div className="item-tech">
                    <span>Service: {svc.name}</span>
                    <span style={{ margin: '0 6px', color: 'var(--paper-4)' }}>•</span>
                    <span>Recommended State: {svc.recommendedStartType}</span>
                  </div>
                </div>

                <div className="card-actions">
                  {isProtected ? (
                    <div
                      style={{
                        fontSize: 11,
                        color: 'var(--good)',
                        background: 'rgba(16, 185, 129, 0.08)',
                        border: '1px solid rgba(16, 185, 129, 0.2)',
                        padding: '6px 12px',
                        borderRadius: 'var(--radius-1)',
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                      }}
                    >
                      <ShieldCheck size={14} />
                      <span>Protected from Modification</span>
                    </div>
                  ) : (
                    <>
                      <button
                        className="btn-danger"
                        onClick={() => handleDisable(svc)}
                        disabled={isExecuting}
                      >
                        <PowerOff size={13} />
                        <span>{isBusy ? 'Disabling...' : dryRun ? 'Simulate Disable' : 'Disable'}</span>
                      </button>
                      <button
                        className="btn-secondary"
                        onClick={() => handleRestore(svc)}
                        disabled={isExecuting}
                      >
                        <RotateCcw size={13} />
                        <span>Restore</span>
                      </button>
                    </>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
