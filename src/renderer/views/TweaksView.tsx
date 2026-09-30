import React, { useState, useMemo } from 'react';
import { Settings2, RotateCcw, Check, Search, ShieldCheck } from 'lucide-react';
import type { TweakItem } from '../../shared/types';

interface TweaksViewProps {
  tweaks: TweakItem[];
  dryRun: boolean;
  onApplyTweak: (tweak: TweakItem) => Promise<void>;
  onRestoreTweak: (tweak: TweakItem) => Promise<void>;
  isExecuting: boolean;
}

export const TweaksView: React.FC<TweaksViewProps> = ({
  tweaks,
  dryRun,
  onApplyTweak,
  onRestoreTweak,
  isExecuting,
}) => {
  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [processingId, setProcessingId] = useState<string | null>(null);

  const categories = useMemo(() => {
    const set = new Set<string>();
    tweaks.forEach((t) => {
      if (t.category) set.add(t.category);
    });
    return ['All', ...Array.from(set)];
  }, [tweaks]);

  const filteredTweaks = useMemo(() => {
    return tweaks.filter((tweak) => {
      const matchSearch =
        tweak.name.toLowerCase().includes(search.toLowerCase()) ||
        tweak.path.toLowerCase().includes(search.toLowerCase()) ||
        tweak.valueName.toLowerCase().includes(search.toLowerCase()) ||
        tweak.descriptionSimple.toLowerCase().includes(search.toLowerCase());
      const matchCat = selectedCategory === 'All' || tweak.category === selectedCategory;
      return matchSearch && matchCat;
    });
  }, [tweaks, search, selectedCategory]);

  const handleApply = async (tweak: TweakItem) => {
    setProcessingId(tweak.id);
    try {
      await onApplyTweak(tweak);
    } finally {
      setProcessingId(null);
    }
  };

  const handleRestore = async (tweak: TweakItem) => {
    setProcessingId(tweak.id);
    try {
      await onRestoreTweak(tweak);
    } finally {
      setProcessingId(null);
    }
  };

  const getRiskBadgeClass = (risk: string) => {
    switch (risk?.toLowerCase()) {
      case 'safe':
        return 'badge-safe';
      case 'moderate':
        return 'badge-warn';
      case 'high':
        return 'badge-danger';
      default:
        return 'badge-safe';
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div className="section-header">
        <div>
          <h2 className="section-title">System &amp; Registry Tweaks</h2>
          <p className="section-sub">
            Granular Windows 11 26H2 policies, privacy controls, Explorer enhancements, and telemetry kill-switches.
          </p>
        </div>
      </div>

      <div className="filter-bar">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Search size={16} style={{ color: 'var(--paper-3)' }} />
          <input
            type="text"
            className="search-input"
            placeholder="Search tweaks by name, registry key, or value..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="pill-group" style={{ overflowX: 'auto', maxWidth: '65%' }}>
          {categories.map((cat) => (
            <button
              key={cat}
              className={`filter-pill ${selectedCategory === cat ? 'is-active' : ''}`}
              onClick={() => setSelectedCategory(cat)}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      <div className="cards-list">
        {filteredTweaks.length === 0 ? (
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
            No tweaks match your filter criteria.
          </div>
        ) : (
          filteredTweaks.map((tweak) => {
            const isBusy = isExecuting && processingId === tweak.id;
            return (
              <div key={tweak.id} className="bezel-outer">
                <div className="bezel-inner item-card">
                  <div>
                    <div className="item-head">
                      <span className="item-name">{tweak.name}</span>
                      <span className={`badge ${getRiskBadgeClass(tweak.risk)}`}>{tweak.risk || 'Safe'}</span>
                      <span className="badge badge-accent">{tweak.category}</span>
                    </div>
                    <div className="item-desc">{tweak.descriptionSimple}</div>
                    <div className="item-tech">
                      <span>
                        {tweak.hive}:\{tweak.path} [{tweak.valueName} = {String(tweak.value)}]
                      </span>
                    </div>
                  </div>

                  <div className="card-actions">
                    <button
                      className="btn-primary"
                      onClick={() => handleApply(tweak)}
                      disabled={isExecuting}
                    >
                      <Settings2 size={13} />
                      <span>{isBusy ? 'Applying...' : dryRun ? 'Simulate' : 'Apply'}</span>
                    </button>
                    <button
                      className="btn-secondary"
                      onClick={() => handleRestore(tweak)}
                      disabled={isExecuting}
                    >
                      <RotateCcw size={13} />
                      <span>Revert</span>
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};
