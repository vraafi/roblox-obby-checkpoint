# Obby Checkpoint System

Modul Luau untuk Roblox yang mengelola sistem checkpoint berurutan pada game Obby. Dilengkapi dengan fitur anti-lompat (anti-skip), penanganan respawn otomatis, serta pengelolaan memori bebas dari memory leak.

## Fitur

- **Penyimpanan Berurutan**: Melacak posisi stage pemain saat ini.
- **Anti-Skip**: Mencegah pemain melompati checkpoint jika `AntiSkip` diaktifkan.
- **Bebas Memory Leak**: Semua event listeners (`Touched`, `PlayerAdded`, `PlayerRemoving`, `CharacterAdded`) diputus secara bersih saat pemain keluar atau modul dipanggil `:Destroy()`.
- **Modular & Modern**: Ditulis menggunakan standar Luau modern (selene `std=roblox`).

## Struktur Folder di Roblox

1. Simpan `ObbyCheckpoint.lua` sebagai `ModuleScript` di `ServerScriptService` atau `ReplicatedStorage`.
2. Buat sebuah `Folder` di `Workspace` bernama `Checkpoints`.
3. Masukkan Part checkpoint ke dalam folder tersebut dan beri nama angka secara berurutan: `1`, `2`, `3`, dst.

## Contoh Pemasangan (ServerScript)

Buat `Script` baru di `ServerScriptService`:

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local ObbyCheckpoint = require(ServerScriptService.ObbyCheckpoint)
local checkpointsFolder = Workspace:WaitForChild("Checkpoints")

-- Opsional: Load konfigurasi jika pakai JSON
local configJSON = '{\"AntiSkip\": true, \"AutoTeleportOnSpawn\": true, \"InitialStage\": 1, \"TeleportOffsetY\": 3, \"TeleportOffsetZ\": 0}'
local config = HttpService:JSONDecode(configJSON)

-- Inisialisasi modul
local checkpointSystem = ObbyCheckpoint.new(checkpointsFolder, config)
```

## Penjelasan Parameter (`config.json`)

- `AntiSkip` (boolean): Jika `true`, pemain tidak bisa menyentuh stage 3 sebelum menyentuh stage 2.
- `AutoTeleportOnSpawn` (boolean): Jika `true`, pemain otomatis diteleportasi ke checkpoint terakhir saat karakter spawn.
- `InitialStage` (number): Stage awal saat pemain baru bergabung (default: 1).
- `TeleportOffsetY` (number): Jarak Ketinggian offset saat teleportasi agar pemain tidak terperangkap di dalam Part.
- `TeleportOffsetZ` (number): Jarak offset sumbu Z saat teleportasi.

## Batasan & Catatan

1. Nama Part checkpoint **harus berupa angka valid** (`1`, `2`, `3`) agar terbaca oleh sistem.
2. Modul ini adalah *in-memory checkpoint system*. Untuk menyimpan data permanen antar-session, integrasikan nilai `GetPlayerStage` dan `SetPlayerStage` dengan `DataStoreService` secara eksternal.
