import { deflateSync } from 'node:zlib'
import { writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const dir = dirname(fileURLToPath(import.meta.url))

function crc32(buffer) {
  let crc = 0xffffffff
  for (const byte of buffer) {
    crc ^= byte
    for (let i = 0; i < 8; i += 1) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1))
    }
  }
  return (crc ^ 0xffffffff) >>> 0
}

function chunk(type, data) {
  const length = Buffer.alloc(4)
  length.writeUInt32BE(data.length)
  const payload = Buffer.concat([Buffer.from(type), data])
  const crc = Buffer.alloc(4)
  crc.writeUInt32BE(crc32(payload))
  return Buffer.concat([length, payload, crc])
}

function createIcon(size) {
  const bg = [20, 14, 12]
  const gold = [245, 197, 24]
  const rows = []
  const cx = (size - 1) / 2
  const cy = (size - 1) / 2
  const radius = size * 0.28
  const barW = size * 0.055
  const barH = size * 0.42

  for (let y = 0; y < size; y += 1) {
    const row = [0]
    for (let x = 0; x < size; x += 1) {
      const dx = x - cx
      const dy = y - cy
      const inStem = Math.abs(dx) < barW && dy > -barH * 0.15 && dy < barH * 0.55
      const inTop = Math.abs(dx) < barW && dy > -barH * 0.62 && dy < -barH * 0.28
      const inCross1 = Math.abs(dy + barH * 0.08) < barW * 0.7 && Math.abs(dx) < radius * 0.85
      const inCross2 = Math.abs(dy - barH * 0.18) < barW * 0.7 && Math.abs(dx) < radius * 0.72
      const yen = inStem || inTop || inCross1 || inCross2
      const color = yen ? gold : bg
      row.push(color[0], color[1], color[2])
    }
    rows.push(Buffer.from(row))
  }

  const ihdr = Buffer.alloc(13)
  ihdr.writeUInt32BE(size, 0)
  ihdr.writeUInt32BE(size, 4)
  ihdr[8] = 8
  ihdr[9] = 2
  const png = Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(Buffer.concat(rows))),
    chunk('IEND', Buffer.alloc(0)),
  ])
  return png
}

const out = join(dir, '..', 'public')
writeFileSync(join(out, 'icon-192.png'), createIcon(192))
writeFileSync(join(out, 'icon-512.png'), createIcon(512))
writeFileSync(join(out, 'apple-touch-icon.png'), createIcon(180))
console.log('icons written')
