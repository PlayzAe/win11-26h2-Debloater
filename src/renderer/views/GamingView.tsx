import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Gamepad2, Cpu, Zap, Activity, Wifi, Layers, ShieldCheck, CheckCircle2 } from 'lucide-react';
import type { GamingOptimization } from '../../shared/types';

interface GamingViewProps {
  gamingOpts: GamingOptimization[];
  dryRun: boolean;
  onTuneGaming: (optId: string) => Promise<void>;
  isExecuting: boolean;
}

export const GamingView: React.FC<GamingViewProps> = ({
  gamingOpts,
  dryRun,
  onTuneGaming,
  isExecuting,
}) => {
  const [processingId, setProcessingId] = useState<string | null>(null);

  const handleTune = async (id: string) => {
    setProcessingId(id);
    try {
      await onTuneGaming(id);
    } finally {
      setProcessingId(null);
    }
  };

  const getIconForOpt = (id: string) => {
    switch (id) {
      case 'cpu_unparking':
        return <Cpu size={22} style={{ color: 'var(--accent)' }} />;
      case 'ultimate_performance_plan':
        return <Zap size={22} style={{ color: 'var(--warn)' }} />;
      case 'network_scheduler_mmcss':
        return <Wifi size={22} style={{ color: 'var(--good)' }} />;
      case 'svchost_split_threshold':
        return <Layers size={22} style={{ color: 'var(--critical)' }} />;
      default:
        return <Activity size={22} style={{ color: 'var(--accent)' }} />;
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div className="section-header">
        <div>
          <h2 className="section-title">Kernel Gaming &amp; Latency Tuning</h2>
          <p className="section-sub">
            Sub-millisecond scheduling, thread priority elevation, and hardware interrupt optimization.
          </p>
        </div>
      </div>

      {/* Safeguard Banner */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 12,
          padding: '12px 18px',
          background: 'rgba(16, 185, 129, 0.08)',
          border: '1px solid rgba(16, 185, 129, 0.25)',
          borderRadius: 'var(--radius-2)',
        }}
      >
        <ShieldCheck size={20} style={{ color: 'var(--good)', flexShrink: 0 }} />
        <div style={{ fontSize: 12, color: 'var(--paper-2)', lineHeight: 1.4 }}>
          <strong style={{ color: 'var(--paper)' }}>Peripheral &amp; Xbox Safeguard Active:</strong> Xbox Game Pass,
          Wireless Xbox Controller adapter, Bluetooth HID headsets, and DirectX/Vulkan runtime dependencies are protected
          and will never be crippled.
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 14 }}>
        {gamingOpts.map((opt) => {
          const isBusy = isExecuting && processingId === opt.id;
          return (
            <div key={opt.id} className="bezel-outer">
              <div
                className="bezel-inner"
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  padding: 18,
                  gap: 14,
                }}
              >
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div
                        style={{
                          width: 38,
                          height: 38,
                          borderRadius: 'var(--radius-2)',
                          background: 'var(--ink-2)',
                          display: 'grid',
                          placeItems: 'center',
                          border: '1px solid var(--line-2)',
                        }}
                      >
                        {getIconForOpt(opt.id)}
                      </div>
                      <div>
                        <div style={{ fontSize: 15, fontWeight: 780, color: 'var(--paper)' }}>
                          {opt.name}
                        </div>
                        <div style={{ fontSize: 10, color: 'var(--paper-3)', fontFamily: 'var(--font-mono)' }}>
                          ID: {opt.id}
                        </div>
                      </div>
                    </div>
                    <span className="badge badge-safe">SAFE TUNE</span>
                  </div>

                  <p style={{ fontSize: 12.5, color: 'var(--paper-2)', lineHeight: 1.45, marginTop: 6 }}>
                    {opt.descriptionSimple}
                  </p>

                  <div
                    style={{
                      fontSize: 11,
                      color: 'var(--paper-3)',
                      fontFamily: 'var(--font-mono)',
                      background: 'var(--ink-0)',
                      padding: '6px 10px',
                      borderRadius: 'var(--radius-1)',
                      border: '1px solid var(--line)',
                      marginTop: 10,
                    }}
                  >
                    {opt.descriptionTech}
                  </div>
                </div>

                <button
                  className="btn-primary"
                  style={{ width: '100%', justifyContent: 'center' }}
                  onClick={() => handleTune(opt.id)}
                  disabled={isExecuting}
                >
                  <Zap size={13} />
                  <span>{isBusy ? 'Optimizing...' : dryRun ? `Simulate ${opt.name}` : `Activate ${opt.name}`}</span>
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
