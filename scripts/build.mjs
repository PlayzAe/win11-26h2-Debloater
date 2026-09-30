import { resolve } from 'node:path';
import * as esbuild from 'esbuild';
import { build } from 'vite';
import { nodeBuildOptions } from './esbuild.config.mjs';

const root = resolve(import.meta.dirname, '..');

console.log('[build] Bundling renderer with Vite...');
await build({ configFile: resolve(root, 'vite.config.mts'), logLevel: 'warn' });

console.log('[build] Bundling main and preload with esbuild...');
await esbuild.build(nodeBuildOptions({ dev: false }));

console.log('[build] Complete. App ready in out/');
