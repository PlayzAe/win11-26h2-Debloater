import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

export function nodeBuildOptions({ dev }) {
  return {
    absWorkingDir: root,
    entryPoints: [
      { in: 'src/main/index.ts', out: 'main/index' },
      { in: 'src/preload/index.ts', out: 'preload/index' },
    ],
    outdir: 'out',
    outExtension: { '.js': '.cjs' },
    bundle: true,
    platform: 'node',
    format: 'cjs',
    target: 'node22',
    external: ['electron'],
    sourcemap: dev ? 'inline' : false,
    minify: !dev,
    legalComments: dev ? 'inline' : 'none',
    logLevel: 'warning',
  };
}
