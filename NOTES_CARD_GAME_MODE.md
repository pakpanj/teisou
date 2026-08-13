# Mode Game Card

Catatan proyek untuk mode permainan kartu di Teisou — Kana Master.

**Status: konsep sudah ditetapkan, belum ada kode sama sekali.** Belum ada
model, layar, Cloud Function, maupun dataset untuk fitur ini.

---

## Konsep yang sudah diputuskan

Bergaya kartu Yu-Gi-Oh: tiap pemain memegang **deck**, lalu saling
mengeluarkan kartu.

- Setiap pemain memegang **20 kartu** berisi hiragana / katakana / kanji
  (N5 sampai N1).
- Pemain mengeluarkan kartu, **lawan menulis cara bacanya**.
- Poin diakumulasi ke **rank / papan peringkat**.
- Lawan bisa dipilih: **teman, clan, atau publik**.
- Ada pilihan **mode pertarungan** (bentuknya belum ditentukan).
- **Gratis** — tidak masuk skema premium.

## Modal yang sudah ada di aplikasi

Tidak semuanya dimulai dari nol:

- **Dataset kartunya sudah lengkap dan tinggal dipakai** — 208 kana dan
  2.425 kanji N5-N1, semuanya sudah punya bacaan. Tidak perlu menulis
  konten baru untuk ini.
- **`RomajiConverter`** (`lib/core/services/romaji_converter.dart`) sudah
  ada dan mengubah kana ke romaji dari `KanaRepository`. Ini bahan langsung
  untuk memeriksa jawaban ketikan.
- **Cloud Functions sudah hidup** (`functions/index.js`) — tapi keempatnya
  murni pemicu notifikasi (`onClanMessageCreated`, `onDirectMessageCreated`,
  dan dua lainnya). Belum ada satu pun logika permainan di server.
- **Clan dan sistem teman sudah jalan**, jadi "lawan teman / clan" punya
  daftar pemain yang bisa dipakai. Yang belum ada cuma pencarian lawan
  publik.
- **Papan peringkat sudah punya pola denormalisasi** yang cocok — nilai
  urutan disimpan sebagai satu field (`globalScore`) karena Firestore tidak
  bisa `orderBy` hasil hitungan. Mode ini bisa mengikuti pola yang sama.

## Tiga hal yang perlu diputuskan sebelum menulis kode

Ketiganya menentukan bentuk fitur, bukan detail yang bisa disusul.

### 1. Kanji tidak punya satu jawaban benar

Ini masalah terbesar, dan bukan perkiraan — sudah saya hitung dari
`kanji_data.json`: **1.508 dari 2.425 kanji (62%) punya lebih dari satu
bacaan.** Contohnya 生 punya lima: セイ, ショウ, い-きる, う-まれる, なま.

Jadi "lawan menulis cara baca kartu ini" jelas untuk kana, tapi **tidak
punya jawaban tunggal untuk mayoritas kanji**. Pilihannya:

- **Terima bacaan mana pun** yang terdaftar untuk kanji itu. Paling mudah,
  tapi pemain bisa selalu menjawab dengan bacaan yang paling ia hafal.
- **Kartunya berisi kata, bukan kanji tunggal.** Dataset sudah menyimpan
  contoh kata beserta bacaannya untuk tiap kanji, jadi 生 muncul sebagai
  学生 dengan satu bacaan benar. Ini yang paling saya sarankan — jawabannya
  tunggal, dan yang diuji jadi lebih dekat ke kemampuan membaca sungguhan.
- **Batasi ke kanji berbacaan tunggal** — hanya menyisakan 38% dataset.

### 2. Jawaban diketik atau dipilih?

Aplikasi ini **pernah gagal di jalan ini**. Kaiwa Fase 1 memakai input teks
bebas dan pencocokan jawaban, lalu diganti total jadi pilihan ganda karena
jadi sumber bug terbesar aplikasi (lihat CLAUDE.md).

Tapi preseden itu belum tentu berlaku di sini, dan alasannya penting:
Kaiwa mencocokkan **kalimat Jepang utuh**, sedangkan bacaan kana adalah
string romaji pendek yang deterministik — dan `RomajiConverter` sudah ada.
Untuk kana, mengetik itu wajar dan aman.

Yang membuatnya kembali berbahaya adalah kanji (masalah nomor 1). Kalau
kartunya berisi kata, mengetik tetap aman. Kalau kanji tunggal dengan
banyak bacaan, pencocokan teks bebas mulai menebak-nebak lagi.

### 3. Serentak atau bergiliran santai?

"Lawan publik" mengandaikan **dua pemain online bersamaan** — butuh antrean
pencarian lawan, penanganan pemain yang kabur di tengah permainan, dan
batas waktu per giliran.

Alternatifnya permainan **asinkron**: kartu dikeluarkan, lawan menjawab
kapan pun ia membuka aplikasi. Untuk aplikasi belajar yang dipakai anak di
perjalanan, ini jauh lebih realistis dan menghapus seluruh kerumitan
antrean. Ini percabangan produk yang besar — memilihnya belakangan berarti
membongkar ulang.

## Satu risiko teknis yang harus dipegang sejak awal

**Poin yang masuk papan peringkat tidak boleh dihitung di HP.** Begitu skor
dari pertandingan ikut menentukan peringkat publik, klien yang mengirim
skornya sendiri bisa mengarang angka. Aturan `firestore.rules` tidak bisa
memeriksa logika permainan — hanya bisa memeriksa siapa yang menulis.

Artinya penilaian pertandingan harus dijalankan di **Cloud Function**, dan
itu memang lompatan arsitektur terbesar yang pernah diambil aplikasi ini:
keempat function yang ada sekarang hanya mengirim notifikasi, tidak pernah
memutuskan apa pun.

Ini juga alasan bagus untuk memutuskan nomor 3 lebih dulu — mode asinkron
jauh lebih sederhana diamankan di server daripada pertandingan serentak.

## Yang masih kosong

Belum dibahas sama sekali:

- Bentuk "mode pertarungan" yang bisa dipilih itu apa saja.
- Kondisi menang — habisnya 20 kartu, poin tertinggi, atau nyawa.
- Apakah poinnya masuk `globalScore` yang sudah ada, atau punya peringkat
  sendiri.
- Apakah kartunya dikumpulkan/dibuka bertahap seperti Yu-Gi-Oh, atau deck
  dibagikan otomatis dari level yang dipilih.
- Karena gratis, iklan banner tetap muncul — perlu dipastikan tidak
  mengganggu di layar pertandingan.

## Catatan awal

_(kosong)_
