import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Trash2, RotateCcw, AlertTriangle, Search, Info, Check } from 'lucide-react';
import type { AppItem } from '../../shared/types';

interface AppsViewProps {
  apps: AppItem[];
  dryRun: boolean;
  onRemoveApp: (appId: string) => Promise<void>;
  onRestoreApp: (appId: string) => Promise<void>;
  isExecuting: boolean;
}

export const AppsView: React.FC<AppsViewProps> = ({
  apps,
  dryRun,
  onRemoveApp,
  onRestoreApp,
  isExecuting,
}) => {
  const [search, setSearch] = useState('');
  const [selectedRisk, setSelectedRisk] = useState<'All' | 'Safe' | 'Moderate' | 'High' | 'Critical'>('All');
  const [pendingApp, setPendingApp] = useState<AppItem | null>(null);
  const [processingId, setProcessingId] = useState<string | null>(null);

  const filteredApps = useMemo(() => {
    return apps.filter((app) => {
      const matchSearch =
        app.name.toLowerCase().includes(search.toLowerCase()) ||
        app.id.toLowerCase().includes(search.toLowerCase()) ||
        app.descriptionSimple.toLowerCase().includes(search.toLowerCase());
      const matchRisk = selectedRisk === 'All' || app.risk === selectedRisk;
      return matchSearch && matchRisk;
    });
  }, [apps, search, selectedRisk]);

  const handleActionClick = (app: AppItem) => {
    if (app.risk === 'High' || app.risk === 'Critical') {
      setPendingApp(app);
    } else {
      executeRemove(app.id);
    }
  };

  const executeRemove = async (appId: string) => {
    setProcessingId(appId);
    try {
      await onRemoveApp(appId);
    } finally {
      setProcessingId(null);
      setPendingApp(null);
    }
  };

  const executeRestore = async (appId: string) => {
    setProcessingId(appId);
    try {
      await onRestoreApp(appId);
    } finally {
      setProcessingId(null);
    }
  };

  const getRiskBadgeClass = (risk: string) => {
    switch (risk) {
      case 'Safe':
        return 'badge-safe';
      case 'Moderate':
        return 'badge-warn';
      case 'High':
        return 'badge-danger';
      case 'Critical':
        return 'badge-critical';
      default:
        return 'badge-safe';
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div className="section-header">
        <div>
          <h2 className="section-title">App Debloater & Package Remover</h2>
          <p className="section-sub">
            Safely remove pre-installed bloatware, consumer telemetry packages, and non-essential UWP store apps.
          </p>
        </div>
      </div>

      <div className="filter-bar">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Search size={16} style={{ color: 'var(--paper-3)' }} />
          <input
            type="text"
            className="search-input"
            placeholder="Search packages by name, ID, or purpose..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="pill-group">
          {(['All', 'Safe', 'Moderate', 'High', 'Critical'] as const).map((risk) => (
            <button
              key={risk}
              className={`filter-pill ${selectedRisk === risk ? 'is-active' : ''}`}
              onClick={() => setSelectedRisk(risk)}
            >
              {risk}
            </button>
          ))}
        </div>
      </div>

      <div className="cards-list">
        {filteredApps.length === 0 ? (
          <div
            style={{
              padding: 40,
              textAlign: 'center',
              color: 'var(--paper-3)',
              background: 'var(--ink-1)',
              borderRadius: 'var(--radius-2)',
              border: '1px solid var(--line)',
            }}
          >
            No packages match your search filter.
          </div>
        ) : (
          filteredApps.map((app) => {
            const isBusy = isExecuting && processingId === app.id;
            return (
              <div key={app.id} className="bezel-outer">
                <div className="bezel-inner item-card">
                  <div>
                    <div className="item-head">
                      <span className="item-name">{app.name}</span>
                      <span className={`badge ${getRiskBadgeClass(app.risk)}`}>{app.risk} Risk</span>
                    </div>
                    <div className="item-desc">{app.descriptionSimple}</div>
                    <div className="item-tech">
                      <span>Package: {app.id}</span>
                      <span style={{ margin: '0 6px', color: 'var(--paper-4)' }}>•</span>
                      <span>{app.descriptionTech}</span>
                    </div>
                  </div>

                  <div className="card-actions">
                    <button
                      className="btn-danger"
                      onClick={() => handleActionClick(app)}
                      disabled={isExecuting}
                      title={`Remove ${app.name}`}
                    >
                      <Trash2 size={13} />
                      <span>{isBusy ? 'Processing...' : dryRun ? 'Simulate Removal' : 'Remove'}</span>
                    </button>
                    <button
                      className="btn-secondary"
                      onClick={() => executeRestore(app.id)}
                      disabled={isExecuting}
                      title={`Reinstall / Restore ${app.name}`}
                    >
                      <RotateCcw size={13} />
                      <span>Restore</span>
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* 2-Tier Confirmation Modal for High / Critical Apps */}
      <AnimatePresence>
        {pendingApp && (
          <div className="modal-backdrop">
            <motion.div
              className="modal-box"
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, color: 'var(--bad)', marginBottom: 14 }}>
                <AlertTriangle size={24} />
                <h3 style={{ fontSize: 18, fontWeight: 780, color: 'var(--paper)' }}>
                  Elevated Risk Confirmation
                </h3>
              </div>

              <div style={{ fontSize: 13, color: 'var(--paper)', marginBottom: 12 }}>
                You are about to remove <strong>{pendingApp.name}</strong>, classified as{' '}
                <span className={`badge ${getRiskBadgeClass(pendingApp.risk)}`}>{pendingApp.risk}</span>.
              </div>

              <div
                style={{
                  background: 'var(--ink-0)',
                  border: '1px solid var(--line-2)',
                  borderRadius: 'var(--radius-2)',
                  padding: 12,
                  marginBottom: 16,
                }}
              >
                <div style={{ fontSize: 12, color: 'var(--paper-2)', marginBottom: 8 }}>
                  <strong>Impact:</strong> {pendingApp.descriptionSimple}
                </div>
                <div style={{ fontSize: 11, color: 'var(--paper-3)', fontFamily: 'var(--font-mono)' }}>
                  <strong>Technical:</strong> {pendingApp.descriptionTech}
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
                <button
                  className="btn-secondary"
                  onClick={() => setPendingApp(null)}
                  disabled={isExecuting}
                >
                  Cancel
                </button>
                <button
                  className="btn-danger"
                  onClick={() => executeRemove(pendingApp.id)}
                  disabled={isExecuting}
                >
                  {dryRun ? 'Confirm Simulation' : 'Confirm & Remove'}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};
