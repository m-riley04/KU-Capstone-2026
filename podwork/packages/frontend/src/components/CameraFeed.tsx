/*
CameraFeed.tsx
Modal component that displays the live Raspberry Pi camera stream.

Two streams are available via MediaMTX:
  - cam         raw hardware stream (no processing)
  - cam_detect  person detection + dwell-time overlay (published by detect.py)

The active host defaults to VITE_RPI_HOST (env var) → 172.20.10.11.
The user can override it at runtime via the IP input field.

MediaMTX serves a self-contained WebRTC player page at:
  http://<host>:8889/<path>/
We embed this in an iframe — no additional libraries required.
*/

import { useState } from 'react';

const DEFAULT_HOST = import.meta.env.VITE_RPI_HOST ?? '172.20.10.11';

type StreamPath = 'cam' | 'cam_detect';

interface CameraFeedProps {
  onClose: () => void;
}

export default function CameraFeed({ onClose }: CameraFeedProps) {
  const [stream, setStream] = useState<StreamPath>('cam');
  const [hostInput, setHostInput] = useState(DEFAULT_HOST);
  const [activeHost, setActiveHost] = useState(DEFAULT_HOST);

  const applyHost = () => {
    const trimmed = hostInput.trim();
    if (trimmed) setActiveHost(trimmed);
  };

  const streamBase = `http://${activeHost}:8889`;

  return (
    <div className="camera-modal-overlay" onClick={onClose}>
      <div className="camera-modal-content" onClick={e => e.stopPropagation()}>

        <div className="camera-modal-header">
          <h2 className="camera-modal-title">Camera Feed</h2>
          <button className="camera-close-btn" onClick={onClose} aria-label="Close camera">
            ✕
          </button>
        </div>

        <div className="camera-ip-row">
          <input
            className="camera-ip-input"
            type="text"
            value={hostInput}
            onChange={e => setHostInput(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && applyHost()}
            placeholder="Pi IP address"
            aria-label="Pi IP address"
            spellCheck={false}
          />
          <button className="camera-ip-apply-btn" onClick={applyHost}>
            Connect
          </button>
        </div>

        <div className="camera-stream-toggle">
          <button
            className={`camera-toggle-btn${stream === 'cam' ? ' active' : ''}`}
            onClick={() => setStream('cam')}
          >
            Raw
          </button>
          <button
            className={`camera-toggle-btn${stream === 'cam_detect' ? ' active' : ''}`}
            onClick={() => setStream('cam_detect')}
          >
            Detection
          </button>
        </div>

        <iframe
          key={`${activeHost}-${stream}`}
          className="camera-iframe"
          src={`${streamBase}/${stream}/`}
          allow="autoplay"
          title={`Camera stream — ${stream}`}
        />

      </div>
    </div>
  );
}
