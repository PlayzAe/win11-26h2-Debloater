import React from 'react';
import { Zap, Package, Settings, Gamepad2, Shield, History, Terminal } from 'lucide-react';

export type NavTab = 'presets' | 'apps' | 'tweaks' | 'gaming' | 'services' | 'rollback';

interface RailProps {
  currentTab: NavTab;
  onSelectTab: (tab: NavTab) => void;
}

export const Rail: React.FC<RailProps> = ({ currentTab, onSelectTab }) => {
  const items: { id: NavTab; label: string; icon: React.ReactNode }[] = [
    { id: 'presets', label: 'Quick Presets', icon: <Zap size={20} /> },
    { id: 'apps', label: 'App Debloater', icon: <Package size={20} /> },
    { id: 'tweaks', label: 'System Tweaks', icon: <Settings size={20} /> },
    { id: 'gaming', label: 'Gaming Latency', icon: <Gamepad2 size={20} /> },
    { id: 'services', label: 'Service Shield', icon: <Shield size={20} /> },
    { id: 'rollback', label: 'Rollback & Rescue', icon: <History size={20} /> },
  ];

  return (
    <nav className="rail" aria-label="Main Navigation">
      <div className="rail-logo" title="Windows 11 26H2 Debloater">
        <Terminal size={22} />
      </div>

      <div className="rail-items">
        {items.map((item) => {
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              className={`rail-item ${isActive ? 'is-current' : ''}`}
              onClick={() => onSelectTab(item.id)}
              title={item.label}
            >
              {item.icon}
              <span className="sr-only">{item.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
