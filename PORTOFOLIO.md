## Masalah
Obby di Roblox butuh sistem checkpoint yang adil dan tahan lama. Checkpoint berurutan, penolakan lompat checkpoint, dan data per pemain sering ditulis ulang. Akibatnya muncul memory leak dan sesi bermain memburuk.

## Yang Dibangun
Obby Checkpoint: modul Luau untuk checkpoint berurutan dan respawn. Modul menyimpan data per pemain, menolak lompat checkpoint, dan membersihkan koneksi saat pemain keluar. Hasil: ObbyCheckpoint.lua (6111 B) dan README.md (2758 B).

## Keputusan Teknis
Data checkpoint diikat ke pemain, bukan ke objek global. Urutan checkpoint divalidasi sebelum disimpan. Setiap koneksi event dilepas saat pemain keluar. Pendekatan ini menutup sumber memory leak, sekaligus menjaga aturan anti-lompat tetap konsisten.

## Bukti
QC selesai dalam 0,23 detik. Lapis aktif: kode. Lapis lulus: kode. Temuan: 0. Berkas kode: 1 Lua, 1 lain. Berkas Python, JavaScript, dan JSON: 0.

## Batasan
QC baru mencakup lapis kode. Uji beban pemain dan uji sesi panjang belum masuk cakupan. Modul tidak menyertakan UI checkpoint, jadi integrasi visual diserahkan ke pengembang.