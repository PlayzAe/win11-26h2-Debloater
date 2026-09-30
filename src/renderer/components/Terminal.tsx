import React, { useRef, useEffect } from 'react';
import { Terminal as TerminalIcon, Copy, Trash2 } from 'lucide-react';
import type { LogMessage } from '../../shared/types';

interface TerminalProps {
  logs: LogMessage[];
  onClear: () => void;
}

export const Terminal: React.FC<TerminalProps> = ({ logs, onClear }) => {
  const bodyRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (bodyRef.current) {
      bodyRef.current.scrollTop = bodyRef.current.scrollHeight;
    }
  }, [logs]);

  const handleCopy = () => {
    const text = logs.map((l) => `${l.timestamp} [${l.level}] ${l.line}`).join('\n');
    navigator.clipboard.writeText(text);
  };

  return (
    <section className="terminal-pane">
      <div className="terminal-bar">
        <div className="terminal-title">
          <TerminalIcon size={14} />
          <span>TACTICAL EXECUTION TERMINAL</span>
          <span style={{ color: 'var(--paper-4)', fontWeight: 400 }}>| Real-time diagnostic stream</span>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <button
            className="btn-secondary"
            style={{ padding: '2px 8px', fontSize: 10, display: 'flex', alignItems: 'center', gap: 4 }}
            onClick={handleCopy}
            title="Copy entire log to clipboard"
          >
            <Copy size={11} />
            <span>Copy Log</span>
          </button>
          <button
            className="btn-secondary"
            style={{ padding: '2px 8px', fontSize: 10, display: 'flex', alignItems: 'center', gap: 4 }}
            onClick={onClear}
            title="Clear terminal buffer"
          >
            <Trash2 size={11} />
            <span>Clear</span>
          </button>
        </div>
      </div>

      <div className="terminal-body" ref={bodyRef}>
        {logs.length === 0 ? (
          <div style={{ color: 'var(--paper-4)', fontStyle: 'italic' }}>
            System ready. Zero-mutation engine standing by.
          </div>
        ) : (
          logs.map((log, i) => (
            <div key={i} className="log-line">
              <span className="log-ts num">{log.timestamp}</span>
              <span className={`log-${log.level}`}>{log.line}</span>
            </div>
          ))
        )}
      </div>
    </section>
  );
};
