# Obby Checkpoint Module

Modul Luau untuk Roblox yang menyediakan sistem checkpoint dan respawn untuk obby. Mendukung checkpoint berurutan, anti-lompat, data per pemain, dan pembersihan koneksi yang benar.

## Cara Pakai

1. Letakkan `ObbyCheckpoint.lua` sebagai ModuleScript di `ReplicatedStorage` atau `ServerScriptService`.
2. Buat Script server yang me-require modul dan menginisialisasinya.
3. Tandai part checkpoint dengan attribute `Checkpoint` (atau sesuai config) dan `CheckpointOrder` (angka urutan).

Contoh:

```lua
local ObbyCheckpoint = require(game.ReplicatedStorage.ObbyCheckpoint)
local config = require(game.ReplicatedStorage.config)

local checkpointSystem = ObbyCheckpoint.new(config)

-- Opsional: daftarkan checkpoint baru secara manual
-- checkpointSystem:RegisterCheckpoint(part)

-- Saat server shutdown atau modul tidak diperlukan:
-- checkpointSystem:Destroy()
```

## Pemasangan Checkpoint

- Setiap part checkpoint harus memiliki attribute `Checkpoint` (boolean true) dan `CheckpointOrder` (number, urutan).
- Contoh: Part dengan attribute `Checkpoint = true`, `CheckpointOrder = 1`.
- Respawn akan menempatkan pemain 5 stud di atas part checkpoint terakhir.

## Konfigurasi

File `config.json` berisi parameter yang dapat diubah:

- `checkpointTag` (string): Nama attribute penanda checkpoint. Default: `"Checkpoint"`.
- `respawnDelay` (number): Jeda respawn setelah mati (detik). Default: `0.5`.
- `antiSkip` (boolean): Cegah pemain melompati checkpoint. Default: `true`.
- `spawnOnJoin` (boolean): Paksa spawn karakter saat join. Default: `true`.
- `resetOnDeath` (boolean): Respawn ke checkpoint saat mati. Default: `true`.

## Batasan

- Hanya mendukung checkpoint berbasis part dengan attribute.
- Anti-lompat mengandalkan urutan `CheckpointOrder`; pastikan unik dan berurutan.
- Tidak menangani kasus checkpoint dihapus saat runtime (perlu panggil `RegisterCheckpoint` ulang).
- Modul ini tidak membuat GUI atau feedback visual.
- Respawn delay menggunakan `task.delay`; pastikan tidak ada konflik dengan sistem respawn lain.
- Untuk performa, hindari terlalu banyak checkpoint (ratusan) karena pengecekan linear.
