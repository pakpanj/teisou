# Mode Game Card

Catatan rumusan untuk mode permainan kartu di Teisou — Kana Master.

**Status: masih perumusan. Belum ada satu baris kode pun** — tidak ada
model, layar, Cloud Function, maupun dataset untuk fitur ini. Catatan ini
sengaja dibuat lebih dulu.

---

## Keputusan yang sudah diambil

Bergaya kartu Yu-Gi-Oh: tiap pemain memegang deck, lalu saling mengeluarkan
kartu dan lawan menulis bacaannya.

| Hal | Keputusan |
|---|---|
| Isi deck | 20 kartu hiragana / katakana / kanji, N5–N1 |
| Kartu kanji | **Berisi kata, bukan kanji tunggal** |
| Jawaban kartu kana | Diketik **romaji** |
| Jawaban kartu kanji | Diketik **hiragana** |
| Cara mengetik hiragana | **Keyboard kana bawaan aplikasi** |
| Alur pertandingan | **Serentak**, dua pemain online bersamaan |
| Kondisi selesai | **Berakhir di 10 kartu**, poin terbanyak menang |
| Giliran | **Bergantian**, bukan menjawab bersamaan |
| Batas waktu | **Kartu 1–10: maksimal 30 detik**, lanjut begitu dijawab |
| Kalau seri | **Kartu 11–20: dipangkas 2 detik tiap kartu** |
| Habis waktu | **Kartu itu dihitung kalah** |
| Masih imbang di kartu 20 | **Seri** — keduanya dapat poin yang seharusnya |
| Lawan | Teman, clan, atau publik |
| Poin | Diakumulasi ke rank / papan peringkat |
| Harga | Gratis |

### Kenapa deck 20 tapi main hanya 10

Konsep nyawa sempat dipilih lalu dibatalkan; yang dipakai adalah bentuk
awal. Deck tetap 20 kartu, tapi satu pertandingan berhenti di 10.

Dua akibat yang bagus dan sebaiknya dipertahankan:

- **Panjangnya masuk akal.** Kalau ke-20 kartu tiap pemain dimainkan
  semua, itu 40 jawaban, sekitar 7 menit — terlalu lama untuk anak, dan
  makin lama makin besar peluang satu pemain kabur di tengah jalan.
- **Setengah deck tidak terpakai tiap match**, jadi kartu yang keluar
  berbeda-beda dan pertandingan berikutnya tidak terasa mengulang.

Berbeda dengan mode nyawa, di sini **anak yang masih lemah tetap main
sampai habis** dan tetap dapat 10 soal untuk dipelajari — kalah dengan
selisih poin, bukan tersingkir di giliran ketiga.

> **Perlu dipastikan:** "berakhir di 10 kartu" dicatat di sini sebagai
> **10 kartu per pemain** (jadi 20 jawaban, sekitar 3–4 menit). Kalau yang
> dimaksud 10 kartu total (5 per pemain, sekitar 2 menit), tinggal ubah
> angka ini — tidak ada yang bergantung padanya selain durasi.

### Timer, dan cara seri diselesaikan

**Kartu 1–10 diberi 30 detik per kartu.** Kalau setelah kartu ke-10 poinnya
masih sama, pertandingan **tidak berhenti seri** — lanjut ke **kartu 11–20
dengan waktu yang dipercepat tiap kartu** sampai salah satu unggul.

**30 detik itu batas atas, bukan durasi tetap** — begitu dijawab, giliran
langsung berganti. Ini penting, dan dua keputusan tadi saling menyelamatkan:

> Gilirannya **bergantian**, jadi satu kartu memakan dua jatah waktu. Kalau
> 30 detik itu durasi tetap, 10 kartu = 10 menit — justru lebih lama
> daripada 7 menit yang dihindari waktu konsep 40 jawaban dibatalkan.
>
> Karena 30 detik hanya batas atas, yang menentukan panjang pertandingan
> adalah kecepatan pemain, bukan timernya. Kalau rata-rata menjawab 5–8
> detik, 10 kartu selesai sekitar **2–3 menit**. Batas 30 detik hanya
> menangkap pemain yang benar-benar mandek.

Efek sampingnya juga bagus: kartu kana yang jawabannya cuma "a" tidak lagi
memakan 30 detik penuh, jadi tidak perlu timer terpisah untuk kartu kana
dan kartu kanji.

**Habis waktu dihitung kalah untuk kartu itu** — bukan langsung kalah
pertandingan.

### Kalau tetap imbang, hasilnya seri

Kartu 11–20 dipangkas 2 detik tiap kartu: kartu 11 dapat 28 detik, dan
kartu 20 dapat 10 detik. **Lantainya 10 detik**, tidak pernah jadi mustahil.

Itu artinya percepatan ini **tidak dijamin memaksa hasil**, dan aturan seri
memang dibutuhkan — bukan sekadar jaring pengaman untuk keadaan yang tak
mungkin terjadi. Dua pemain yang sama-sama lancar biasanya menjawab jauh di
bawah 10 detik, jadi tekanan waktunya baru terasa di kartu-kartu terakhir
saja. Kalau nanti terasa terlalu sering seri, pangkasannya bisa dibuat
lebih tajam; sekarang cukup disadari saja.

Kalau sampai kartu ke-20 masih imbang, hasilnya **seri dan kedua pemain
mendapat poin yang seharusnya mereka dapat**.

Dua hal yang menyenangkan dari bentuk ini, dan keduanya kebetulan cocok
dengan keputusan yang sudah diambil sebelumnya:

- **Sisa deck-nya sudah tersedia.** Deck 20 kartu dengan 10 dipakai
  menyisakan tepat 10 kartu — itulah bahan untuk babak tambahannya. Tidak
  perlu aturan pengambilan kartu yang baru.
- **Timer yang makin cepat memaksa hasil.** Semakin pendek waktunya,
  semakin kecil kemungkinan keduanya sama-sama benar, jadi seri
  berkepanjangan selesai dengan sendirinya tanpa aturan tambahan.

**Batas alaminya: babak tambahan paling banyak 10 kartu**, karena setelah
itu deck habis. Perlu diputuskan apa yang terjadi kalau sampai titik itu
masih imbang juga — kemungkinan besar tidak akan pernah terjadi kalau
timernya terus dipercepat, tapi tetap butuh jawaban supaya kode tidak
menggantung di keadaan yang tidak diantisipasi.

**Akibat teknis yang harus dipegang: timernya tidak boleh bersandar pada
jam HP.** Kalau hitungan mundur dijalankan sepenuhnya di perangkat, pemain
bisa memperlambat atau menghentikan waktunya sendiri, dan itu langsung
merusak peringkat publik. Waktunya harus berpatokan pada **stempel waktu
server** — sejalan dengan aturan bahwa skor resmi dihitung di Cloud
Function, bukan di HP.

### Kenapa kartu kanji berisi kata

Dihitung langsung dari `kanji_data.json`, bukan perkiraan: **1.508 dari
2.425 kanji (62%) punya lebih dari satu bacaan** — 生 saja punya lima (セイ,
ショウ, い-きる, う-まれる, なま). Kartu berisi kanji tunggal berarti mayoritas
soal tidak punya jawaban benar yang tunggal.

Dengan kartu berisi kata, 生 muncul sebagai 学生 dan jawabannya pasti:
がくせい. Dataset **sudah menyimpan contoh kata beserta bacaannya** untuk
tiap kanji, jadi ini tidak menambah pekerjaan konten sama sekali.

## Modal yang sudah ada

Fitur ini tidak dimulai dari nol:

- **Dataset kartu lengkap** — 208 kana dan 2.425 kanji N5–N1, semuanya
  sudah punya bacaan dan contoh kata. Tidak perlu konten baru.
- **Clan dan sistem teman sudah jalan**, jadi "lawan teman / clan" sudah
  punya daftar pemain. Yang belum ada hanya pencarian lawan publik.
- **Papan peringkat sudah punya pola denormalisasi yang cocok** — nilai
  pengurut disimpan sebagai satu field (`globalScore`) karena Firestore
  tidak bisa `orderBy` hasil hitungan.
- **Cloud Functions sudah hidup** (`functions/index.js`) — tapi keempatnya
  murni pemicu notifikasi dan tidak memutuskan apa pun.

## Dua hal yang harus dibangun baru, dan tidak kecil

### 1. Keyboard kana di dalam aplikasi

Tidak bisa mengandalkan keyboard HP: mengetik hiragana di Android menuntut
keyboard Jepang terpasang dan pengguna berganti keyboard. Hampir tidak ada
anak Indonesia yang punya itu — dan hambatan seperti ini membuat fitur
tidak pernah dipakai, bukan sekadar merepotkan.

Yang perlu diperhatikan saat membangunnya:

- **Hiragana saja sudah cukup.** Kartu kana dijawab dengan romaji, jadi
  keyboard ini hanya dipakai untuk bacaan kanji, dan bacaan selalu hiragana.
  Tidak perlu mode katakana.
- **Tenten, maru, dan huruf kecil wajib ada.** がくせい butuh が, dan bacaan
  seperti きょう butuh ょ kecil. Tanpa ketiganya sebagian besar bacaan kanji
  tidak bisa diketik sama sekali.
- Datanya sudah ada — 104 hiragana lengkap dengan barisan gojūon-nya, sama
  seperti yang dipakai tabel kana.
- Layak dibuat sebagai widget mandiri, karena kemungkinan besar berguna di
  modul lain nanti.

### 2. Penilaian di server, bukan di HP

**Begitu poin masuk peringkat publik, hasil pertandingan tidak boleh
dihitung di HP.** Klien yang mengirim skornya sendiri bisa mengarang angka,
dan `firestore.rules` hanya bisa memeriksa *siapa* yang menulis, bukan
apakah logika permainannya benar.

Konsekuensi bentuknya, dan ini penting untuk rasa mainnya:

> **Umpan balik cepat di HP, skor resmi dari server.** Firestore trigger
> punya jeda cold start sampai beberapa detik — terlalu lambat untuk
> menilai tiap giliran. Jadi benar/salah ditampilkan langsung di HP supaya
> pertandingan terasa hidup, sementara Cloud Function menghitung skor
> resmi yang masuk peringkat.

Ini juga lompatan arsitektur terbesar yang pernah diambil aplikasi ini.

## Usulan yang belum diputuskan: mempertaruhkan poin

Sempat dilempar ide **entry fee** — kedua pemain mempertaruhkan poin, dan
kalau seri taruhannya kembali.

**Alasan yang disebut sudah terjawab tanpa taruhan.** Motivasinya tadi
"biar kalau seri poinnya bisa balik", padahal aturan seri sudah
memutuskan kedua pemain mendapat poin yang seharusnya. Jadi kasus seri
sudah beres.

**Tapi taruhan menjawab masalah lain yang nyata:** tanpa risiko, kalah
tidak berbiaya apa pun. Artinya main sebanyak-banyaknya selalu untung, dan
peringkat perlahan berubah jadi ukuran *siapa paling sering main*, bukan
siapa paling bisa.

**Yang membuat saya ragu**, dan ini pola yang sudah kita tolak sekali:
mengambil kembali poin yang sudah didapat itu bentuknya sama dengan mode
nyawa — yang paling terpukul adalah anak yang masih lemah, dan efeknya
membuat ia berhenti main. Untuk aplikasi belajar itu kebalikan dari yang
diinginkan. Dua efek ikutan lain yang biasa muncul di sistem bertaruh:
pemain menghindari pertandingan saat mendekati batas rank, dan cenderung
hanya menantang lawan yang lebih lemah.

**Jalan tengah yang layak dipertimbangkan:**

- **Pemenang dapat banyak, yang kalah dapat sedikit — tapi tidak pernah
  minus.** Tetap ada jarak yang bikin menang terasa berarti, tanpa
  menghukum. Seri otomatis dapat nilai tengah, dan itu sudah persis
  perilaku "poinnya balik" yang diinginkan.
- **Taruhan hanya di mode publik**, tidak di lawan teman dan clan — supaya
  main santai bareng teman tidak pernah merugikan.

Belum diputuskan; dicatat supaya tidak hilang.

## Yang masih harus diputuskan

Belum dijawab. Sebagian menentukan bentuk, sebagian tinggal angka:

**Aturan main**
- 10 kartu itu 10 ronde (tiap pemain mengeluarkan satu kartu, jadi 20
  jawaban), atau 10 jawaban total? Dengan giliran bergantian, keduanya
  masuk akal.
- Deck 20 kartu dipilih sendiri, atau dibagikan otomatis dari level JLPT?
- Kedua pemain menjawab bersamaan, atau bergantian?
- Deck 20 kartu dipilih sendiri, atau dibagikan otomatis dari level JLPT
  yang dipilih?
- "Mode pertarungan" yang bisa dipilih itu apa saja bedanya?

**Pertandingan serentak**
- Bagaimana kalau lawan menutup aplikasi di tengah pertandingan? Dihitung
  kalah, dibatalkan, atau ditunggu?
- Lawan publik dipasangkan berdasarkan apa — level JLPT, rank, atau acak?
- Butuh status online untuk menantang teman dan anggota clan.

**Peringkat**
- Poinnya masuk `globalScore` yang sudah ada, atau punya rank sendiri?
- Rumus poinnya seperti apa — jumlah jawaban benar, kecepatan, atau
  keduanya?

**Lain-lain**
- Karena gratis, iklan banner tetap muncul. Perlu dipastikan tidak
  mengganggu di layar pertandingan.

## Catatan awal

_(kosong)_
