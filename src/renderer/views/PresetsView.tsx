import React, { useState } from 'react';
import { motion } from 'motion/react';
import { Gamepad2, ShieldAlert, Cpu, Sparkles, CheckCircle2, Play } from 'lucide-react';

interface PresetsViewProps {
  dryRun: boolean;
  onApplyPreset: (presetId: 'gaming' | 'privacy' | 'full') => Promise<void>;
  isExecuting: boolean;
}

export const PresetsView: React.FC<PresetsViewProps> = ({
  dryRun,
  onApplyPreset,
  isExecuting,
}) => {
  const [activePreset, setActivePreset] = useState<string | null>(null);

  const presets = [
    {
      id: 'gaming' as const,
      title: 'Gaming Latency Master',
      badge: 'KERNEL LOW-LATENCY',
      badgeClass: 'badge-accent',
      icon: <Gamepad2 size={24} style={{ color: 'var(--accent)' }} />,
      desc: 'Unparks all CPU cores, unlocks Ultimate Performance plan, sets MMCSS GPU priority to 8, disables network throttling, and forces 0.500ms multimedia timer.',
      items: [
        'CPU Core Unparking (100% active state across all cores)',
        'MMCSS Games Scheduling (GPU Priority 8, Audio Priority 6)',
        'Network Throttling Index (0xFFFFFFFF disable queue delay)',
        'SvcHost Splitting Threshold (0x380000 dedicated host containers)',
        'Hardware-Accelerated GPU Scheduling (HAGS) & Game Mode',
      ],
      warning: 'Safe for all systems. Xbox Live and Bluetooth services remain completely untouched.',
    },
    {
      id: 'privacy' as const,
      title: 'Maximum Privacy & AI Guard',
      badge: 'DATA EXFIL BLOCK',
      badgeClass: 'badge-safe',
      icon: <ShieldAlert size={24} style={{ color: 'var(--good)' }} />,
      desc: 'Completely eliminates Windows telemetry, disables Copilot and Recall background indexing, strips advertising ID, and disables diagnostic uploads.',
      items: [
        'Disable Telemetry & Diagnostic Data (Level 0)',
        'Disable Windows Copilot & Recall AI background processing',
        'Disable Bing Search & Web Suggestions in Start Menu',
        'Disable Advertising ID & Tailored Experiences',
        'Disable Diagnostics Tracking Service (DiagTrack)',
      ],
      warning: 'Does not break Windows Update or Microsoft Store security signatures.',
    },
    {
      id: 'full' as const,
      title: 'Full Tactical Debloat',
      badge: 'MAX COMBINED',
      badgeClass: 'badge-critical',
      icon: <Sparkles size={24} style={{ color: 'var(--critical)' }} />,
      desc: 'Applies all kernel latency and privacy tweaks, plus removes verified safe consumer bloatware (Solitaire, News, Weather, Clipchamp, PowerAutomate).',
      items: [
        'Includes all Gaming Latency Master optimizations',
        'Includes all Maximum Privacy & AI Guard tweaks',
        'Safe removal of verified non-essential preinstalled UWP bloat',
        'Automatic pre-flight backup snapshot saved to backups/undo/',
      ],
      warning: 'High impact. Recommended after clean installation or major feature upgrade.',
    },
  ];

  const handleApply = async (presetId: 'gaming' | 'privacy' | 'full') => {
    setActivePreset(presetId);
    try {
      await onApplyPreset(presetId);
    } finally {
      setActivePreset(null);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div className="section-header">
        <div>
          <h2 className="section-title">Tactical Debloat Presets</h2>
          <p className="section-sub">
            Curated system profiles with zero guesswork. Fully audited for Windows 11 26H2 (Build 26100+).
          </p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
        {presets.map((preset) => {
          const isBusy = isExecuting && activePreset === preset.id;
          return (
            <motion.div
              key={preset.id}
              className="bezel-outer"
              whileHover={{ y: -3 }}
              transition={{ duration: 0.16 }}
              style={{ display: 'flex', flexDirection: 'column' }}
            >
              <div
                className="bezel-inner"
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  padding: '20px',
                }}
              >
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                    <div
                      style={{
                        width: 44,
                        height: 44,
                        borderRadius: 'var(--radius-2)',
                        background: 'var(--ink-2)',
                        display: 'grid',
                        placeItems: 'center',
                        border: '1px solid var(--line-2)',
                      }}
                    >
                      {preset.icon}
                    </div>
                    <span className={`badge ${preset.badgeClass}`}>{preset.badge}</span>
                  </div>

                  <h3 style={{ fontSize: 16, fontWeight: 780, color: 'var(--paper)', marginBottom: 6 }}>
                    {preset.title}
                  </h3>
                  <p style={{ fontSize: 12, color: 'var(--paper-2)', lineHeight: 1.5, marginBottom: 16 }}>
                    {preset.desc}
                  </p>

                  <div style={{ borderTop: '1px solid var(--line)', paddingTop: 14, marginBottom: 16 }}>
                    <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--paper-3)', textTransform: 'uppercase', marginBottom: 8, letterSpacing: '0.05em' }}>
                      Included Operations
                    </div>
                    <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'flex', flexDirection: 'column', gap: 6 }}>
                      {preset.items.map((it, idx) => (
                        <li key={idx} style={{ fontSize: 11.5, color: 'var(--paper-2)', display: 'flex', alignItems: 'flex-start', gap: 6 }}>
                          <CheckCircle2 size={13} style={{ color: 'var(--accent)', flexShrink: 0, marginTop: 2 }} />
                          <span>{it}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>

                <div>
                  <div
                    style={{
                      fontSize: 10.5,
                      color: 'var(--paper-3)',
                      marginBottom: 14,
                      padding: '8px 10px',
                      background: 'var(--ink-0)',
                      borderRadius: 'var(--radius-1)',
                      border: '1px solid var(--line)',
                    }}
                  >
                    {preset.warning}
                  </div>

                  <button
                    className="btn-primary"
                    style={{ width: '100%', justifyContent: 'center', height: 38 }}
                    onClick={() => handleApply(preset.id)}
                    disabled={isExecuting}
                  >
                    <Play size={14} />
                    <span>{isBusy ? 'Applying Preset...' : dryRun ? `Simulate ${preset.title}` : `Apply ${preset.title}`}</span>
                  </button>
                </div>
              </div>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
};
