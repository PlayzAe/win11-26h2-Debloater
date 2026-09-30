/// <reference types="vite/client" />
import type { DebloatApi } from '../shared/types';

declare global {
  interface Window {
    debloatApi: DebloatApi;
  }
}

export {};
