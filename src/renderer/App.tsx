import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Rail, NavTab } from './components/Rail';
import { TitleBar } from './components/TitleBar';
import { BentoTelemetry } from './components/BentoTelemetry';
import { Terminal } from './components/Terminal';
import { PresetsView } from './views/PresetsView';
import { AppsView } from './views/AppsView';
import { TweaksView } from './views/TweaksView';
import { GamingView } from './views/GamingView';
import { ServicesView } from './views/ServicesView';
import { RollbackView } from './views/RollbackView';
import type {
  SystemInfo,
  AppItem,
  TweakItem,
  GamingOptimization,
  ServiceItem,
  SessionAction,
  LogMessage,
} from '../shared/types';

export const App: React.FC = () => {
  const [currentTab, setCurrentTab] = useState<NavTab>('presets');
  const [dryRun, setDryRun] = useState<boolean>(true); // Safe zero-mutation by default
  const [sysInfo, setSysInfo] = useState<SystemInfo | null>(null);
  const [apps, setApps] = useState<AppItem[]>([]);
  const [tweaks, setTweaks] = useState<TweakItem[]>([]);
  const [gamingOpts, setGamingOpts] = useState<GamingOptimization[]>([]);
  const [services, setServices] = useState<ServiceItem[]>([]);
  const [sessionActions, setSessionActions] = useState<SessionAction[]>([]);
  const [logs, setLogs] = useState<LogMessage[]>([]);
  const [isExecuting, setIsExecuting] = useState(false);
  const [isCreatingRestorePoint, setIsCreatingRestorePoint] = useState(false);

  useEffect(() => {
    // Initial fetch of system info and configuration items
    const init = async () => {
      try {
        if (!window.debloatApi) return;
        const [info, a, t, g, s, acts] = await Promise.all([
          window.debloatApi.getSystemInfo(),
          window.debloatApi.getApps(),
          window.debloatApi.getTweaks(),
          window.debloatApi.getGaming(),
          window.debloatApi.getServices(),
          window.debloatApi.getSessionActions(),
        ]);
        setSysInfo(info);
        setApps(a);
        setTweaks(t);
        setGamingOpts(g);
        setServices(s);
        setSessionActions(acts);
      } catch (err) {
        console.error('Initialization error:', err);
      }
    };

    init();

    // Subscribe to IPC log stream
    const unsubscribe = window.debloatApi?.onLog((log) => {
      setLogs((prev) => [...prev.slice(-400), log]); // Keep last 400 logs
    });

    return () => {
      unsubscribe?.();
    };
  }, []);

  const refreshSessionActions = async () => {
    try {
      const acts = await window.debloatApi?.getSessionActions();
      if (acts) setSessionActions(acts);
    } catch {}
  };

  const handleApplyPreset = async (presetId: 'gaming' | 'privacy' | 'full') => {
    setIsExecuting(true);
    try {
      await window.debloatApi?.applyPreset(presetId, dryRun);
      await refreshSessionActions();
    } finally {
      setIsExecuting(false);
    }
  };

  const handleRemoveApp = async (appId: string) => {
    setIsExecuting(true);
    try {
      await window.debloatApi?.removeApp(appId, dryRun);
      await refreshSessionActions();
    } finally {
      setIsExecuting(false);
    }
  };

  const handleRestoreApp = async (appId: string) => {
    setIsExecuting(true);
    try {
      await window.debloatApi?.restoreApp(appId, dryRun);
      await refreshSessionActions();
    } finally {
      setIsExecuting(false);
    }
  };

  const handleApplyTweak = async (tweak: TweakItem) => {
    setIsExecuting(true);
    try {
      await window.debloatApi?.setTweak(tweak, dryRun);
      await refreshSessionActions();
    } finally {
      setIsExecuting(false);
    }
  };

  const handleRestoreTweak = async (tweak: TweakItem) => {
    setIsExecuting(true);
    try {
      await window.debloatApi?.restoreTweak(tweak, dryRun);
      await refreshSessionActions();
    } finally {
      setIsExecuting(false);
    }
  };

  const handleTuneGaming = async (optId: string) => {
    setIsExecuting(true);
    try {
      await window.debloatApi?.tuneGaming(optId, dryRun);
      await refreshSessionActions();
    } finally {
      setIsExecuting(false);
    }
  };

  const handleSetService = async (serviceName: string, startType: string) => {
    setIsExecuting(true);
    try {
      await window.debloatApi?.setService(serviceName, startType, dryRun);
      await refreshSessionActions();
    } finally {
      setIsExecuting(false);
    }
  };

  const handleRestoreService = async (serviceName: string) => {
    setIsExecuting(true);
    try {
      await window.debloatApi?.restoreService(serviceName, dryRun);
      await refreshSessionActions();
    } finally {
      setIsExecuting(false);
    }
  };

  const handleCreateRestorePoint = async () => {
    setIsCreatingRestorePoint(true);
    try {
      await window.debloatApi?.createRestorePoint();
    } finally {
      setIsCreatingRestorePoint(false);
    }
  };

  const handleRollbackSession = async () => {
    setIsExecuting(true);
    try {
      await window.debloatApi?.rollbackSession();
      await refreshSessionActions();
    } finally {
      setIsExecuting(false);
    }
  };

  const handleOpenBackupsDir = async () => {
    await window.debloatApi?.openBackupsDir();
  };

  const handleClearLogs = () => {
    setLogs([]);
  };

  return (
    <div className="app-shell">
      <Rail currentTab={currentTab} onSelectTab={setCurrentTab} />

      <main className="content-pane">
        <TitleBar
          dryRun={dryRun}
          onToggleDryRun={() => setDryRun((prev) => !prev)}
          onCreateRestorePoint={handleCreateRestorePoint}
          isCreatingRestorePoint={isCreatingRestorePoint}
        />

        <div className="viewport">
          <BentoTelemetry sysInfo={sysInfo} />

          <AnimatePresence mode="wait">
            <motion.div
              key={currentTab}
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.14 }}
              style={{ flex: 1 }}
            >
              {currentTab === 'presets' && (
                <PresetsView
                  dryRun={dryRun}
                  onApplyPreset={handleApplyPreset}
                  isExecuting={isExecuting}
                />
              )}

              {currentTab === 'apps' && (
                <AppsView
                  apps={apps}
                  dryRun={dryRun}
                  onRemoveApp={handleRemoveApp}
                  onRestoreApp={handleRestoreApp}
                  isExecuting={isExecuting}
                />
              )}

              {currentTab === 'tweaks' && (
                <TweaksView
                  tweaks={tweaks}
                  dryRun={dryRun}
                  onApplyTweak={handleApplyTweak}
                  onRestoreTweak={handleRestoreTweak}
                  isExecuting={isExecuting}
                />
              )}

              {currentTab === 'gaming' && (
                <GamingView
                  gamingOpts={gamingOpts}
                  dryRun={dryRun}
                  onTuneGaming={handleTuneGaming}
                  isExecuting={isExecuting}
                />
              )}

              {currentTab === 'services' && (
                <ServicesView
                  services={services}
                  dryRun={dryRun}
                  onSetService={handleSetService}
                  onRestoreService={handleRestoreService}
                  isExecuting={isExecuting}
                />
              )}

              {currentTab === 'rollback' && (
                <RollbackView
                  actions={sessionActions}
                  onRollbackSession={handleRollbackSession}
                  onCreateRestorePoint={handleCreateRestorePoint}
                  onOpenBackupsDir={handleOpenBackupsDir}
                  isExecuting={isExecuting}
                />
              )}
            </motion.div>
          </AnimatePresence>
        </div>

        <Terminal logs={logs} onClear={handleClearLogs} />
      </main>
    </div>
  );
};
