/**
 * public/icon-source.png から各サイズを作り直す。
 * 例: npx --yes sharp-cli -i public/icon-source.png -o public/icon-512.png resize 512 512
 */
import { spawnSync } from 'node:child_process'
import { existsSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const dir = dirname(fileURLToPath(import.meta.url))
const out = join(dir, '..', 'public')
const source = join(out, 'icon-source.png')

if (!existsSync(source)) {
  console.error('missing public/icon-source.png')
  process.exit(1)
}

const sizes = [
  ['icon-512.png', 512],
  ['icon-192.png', 192],
  ['apple-touch-icon.png', 180],
  ['favicon.png', 64],
]

for (const [name, size] of sizes) {
  const result = spawnSync(
    'npx',
    ['--yes', 'sharp-cli', '-i', source, '-o', join(out, name), 'resize', String(size), String(size)],
    { stdio: 'inherit', shell: true },
  )
  if (result.status !== 0) process.exit(result.status ?? 1)
}

console.log('icons written from icon-source.png')
