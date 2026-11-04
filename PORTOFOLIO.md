## Masalah
Obby di Roblox sering kehilangan checkpoint saat pemain mati atau keluar. Banyak sistem menumpuk koneksi event tanpa pembersihan. Akibatnya memori bocor dan sesi panjang jadi tidak stabil.

## Yang Dibangun
Saya membangun Obby Checkpoint, sistem checkpoint dan respawn Luau. Isinya: checkpoint berurutan, anti-lompat, data per pemain, dan siklus hidup koneksi yang dibersihkan. Tiga berkas: `config.json` (133 B), `ObbyCheckpoint.lua` (5910 B), `README.md` (2200 B).

## Keputusan Teknis
Checkpoint berurutan memakai indeks eksplisit. Pemain tidak bisa menyalip urutan. Anti-lompat memvalidasi indeks terhadap progres terakhir. Data disimpan per pemain, bukan global. Setiap koneksi event diberi jalur pembersihan agar tidak menumpuk.

## Bukti Angka QC
QC berjalan 1,78 detik. Temuan: 0. Lapis aktif: kode. Lapis lulus: kode. Rincian kode: py 0, js 0, json 2, lua 1, lain 4. Semua lapis kode lulus pada satu putaran.

## Batasan
Angka QC mengukur lintasan kode, bukan beban pemain nyata. Uji lapangan di server padat belum tercakup. Config kecil membatasi variasi, jadi perubahan besar perlu revisi berkas, bukan sekadar nilai runtime.