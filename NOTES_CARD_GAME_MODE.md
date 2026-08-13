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
| Peringkat | **Bintang bertingkat ala Mobile Legends** |
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

## Rank pakai bintang, terpisah dari poin

Ide awalnya mempertaruhkan poin. Diganti jadi **sistem bintang seperti
Mobile Legends**: menang naik bintang, kalah turun bintang.

**Ini memakai dua mata uang yang terpisah, dan justru itu kuncinya:**

| | Poin | Bintang |
|---|---|---|
| Gunanya | Catatan hasil belajar | Peringkat kompetitif |
| Arah | Hanya bertambah | Bisa naik dan turun |
| Kalah | Tetap dapat poin dari jawaban benar | Bintang berkurang |

**Ini tetap taruhan, dan memang disengaja.** Anak main untuk mengejar
peringkat, jadi bintang yang bisa hilang itu persis sesuatu yang
dipertaruhkan tiap pertandingan — kalau tidak begitu, kalah tidak ada
harganya dan peringkat cuma jadi ukuran siapa paling sering main.

Yang berubah bukan *ada atau tidaknya* taruhan, tapi **apa yang
dipertaruhkan**:

- **Mempertaruhkan poin** berarti catatan belajarnya sendiri yang menyusut.
  Menjawab 6 kartu benar lalu kalah bisa berakhir dengan poin lebih sedikit
  daripada sebelum main. Bentuknya sama dengan mode nyawa yang sudah kita
  tolak — paling memukul anak yang masih lemah, lalu membuatnya berhenti.
- **Mempertaruhkan bintang** berarti hanya kedudukan kompetitifnya yang
  turun. Jawaban benar tetap tercatat sebagai jawaban benar; yang hilang
  adalah lencana, bukan hasil belajarnya.

Jadi risikonya tetap ada, dan tetap terasa — cuma tidak menghapus bukti
bahwa anak itu sudah belajar.

### Kenapa "pakai poin yang sudah ada saja" ternyata tidak tersedia

Muncul pertanyaan wajar: kenapa tidak mempertaruhkan poin yang sudah ada,
supaya tidak menambah sistem baru? Jawabannya ada di kodenya:

```dart
double get computedGlobalScore =>
    kanaRecordAvg + dokkaiRecordAvg + choukaiRecordAvg + kanjiComboRecordAvg;
```

**Poin di papan peringkat bukan saldo yang bisa dikurangi** — itu jumlah
empat *rata-rata* nilai ujian (Kana, Dokkai, Choukai, Kanji-Kombinasi),
masing-masing 0–100. Tidak ada tabungan poin di mana pun.

Artinya "mengurangi 10 poin" harus dilakukan dengan merusak salah satu
rata-rata nilai ujian — dan begitu itu terjadi, angkanya berhenti berarti
"rata-rata nilai ujianku", yang sekaligus merusak keempat tab Rekor.

**Jadi pilihannya bukan antara memakai ulang dan membuat baru.** Angka baru
tetap dibutuhkan, apa pun namanya — dan setelah itu jelas, **bintang
bertingkat yang dipilih**, bukan sekadar satu angka datar.

Konsekuensinya jujur saja: bintang bertingkat memang lebih banyak
kerjanya. Selain satu angka yang bisa diurutkan, ia menuntut definisi
tingkatan, aturan naik dan turun tingkat, dan kemungkinan musim. Dipilih
karena rasanya jauh lebih dekat ke game yang memang jadi acuan konsep ini,
bukan karena lebih murah.

**Yang perlu diputuskan untuk sistem bintangnya:**

- Tingkatannya apa saja, dan berapa bintang per tingkat.
- Seri berarti bintang tidak berubah? (paling masuk akal)
- Kalau bintang habis, turun tingkat atau berhenti di dasar tingkat itu?
  ML menurunkan tingkat; untuk anak, lantai per tingkat lebih lembut.
- Ada musim yang mereset bintang, atau berjalan terus?
- Bintangnya cuma untuk pertandingan publik, atau lawan teman dan clan
  juga menghitung? (Main santai bareng teman sebaiknya tidak merugikan.)
- Papan peringkat `globalScore` yang sudah ada tetap terpisah, atau
  peringkat bintang jadi papan sendiri?

## Mockup "TEISOU BATTLE" (dibuat user + ChatGPT)

Empat layar: pencarian lawan, mulai pertarungan, hasil, dan papan
peringkat. Arah visualnya sudah cocok dengan aplikasi — maskot, sakura,
torii, palet yang sama.

### Yang cocok dan bisa langsung dipakai

- Deck 20 kartu, **target 10 kartu per pemain** — ini sekaligus menjawab
  pertanyaan yang sempat tergantung: 10 kartu berarti **10 ronde, 20
  jawaban**, bukan 10 jawaban total.
- 30 detik per giliran.
- VS Teman / VS Clan / VS Publik.
- **Kartu kanji berisi kata**, persis keputusan kita — 学生, 時間, 電車,
  友達, 勉強, dengan bacaannya muncul di layar hasil.
- "Mode: Kanji (N5–N1)" memperjelas satu istilah: **mode = jenis deck**
  (kana atau kanji), terpisah dari pilihan lawan.

### Yang bentrok dengan keputusan kita

**1. HP 5 muncul lagi — padahal konsep nyawa sudah dibatalkan.**
Layar pertarungan menampilkan `HP 5` dengan aturan "Benar = Damage ke
lawan, Salah = Damage ke kamu", sekaligus "selesai setelah 10 kartu per
pemain". Itu **dua kondisi selesai yang berjalan bersamaan**. Perlu
diputuskan mana yang menang, dan kalau HP dipakai, kekhawatiran yang dulu
membuat kita membatalkannya kembali berlaku: dengan 5 HP, anak yang lemah
bisa habis di kartu ke-5 dan tidak pernah mendapat 5 soal sisanya.

**2. Peringkatnya angka berjalan, bukan bintang bertingkat.**
Mockup memakai 🏆 1200 → 1250 (+50) dan lawannya 1130 (−20), plus lencana
tingkat (Rookie, Beginner). Itu bentuk **rating**, bukan bintang. Layar
hasil malah menampilkan dua angka sekaligus: 🏆 +50 dan "+5 Poin Rank" —
belum jelas mana mata uang peringkat yang sebenarnya.

**3. Papan peringkat direset mingguan** ("Periode: Minggu Ini", hitung
mundur 02:45:12), sementara ratingnya terlihat kumulatif. Dua hal ini
tidak bisa keduanya benar tanpa aturan musim yang jelas.

**4. Bottom nav jadi 6 tab** (Beranda, Belajar, Kartu, Battle, Clan,
Profil). Sekarang aplikasinya **3 tab**, hasil penyederhanaan yang
disengaja dari 4. Menambah jadi 6 itu perubahan navigasi besar dan
membatalkan keputusan yang sudah diambil.

### Dua hal yang menurut saya berisiko

**Chat bebas dengan orang asing.** Layar pertarungan punya tombol Chat dan
Stiker. Untuk VS Teman dan VS Clan itu wajar. Untuk **VS Publik** artinya
anak bertukar teks bebas dengan orang yang tidak dikenal — ini masalah
keselamatan anak, dan aplikasi ini sudah menangani audiens campuran secara
serius lewat `AdAudience` (COPPA, Families). Chat bebas dengan orang asing
adalah jenis hal yang bisa membuat aplikasi dikeluarkan dari program
Families di Play. **Stiker saja jauh lebih aman**, dan tetap terasa hidup.
Tombol "Laporkan" di layar hasil bagus, tapi pelaporan menuntut sistem
moderasi yang belum ada sama sekali.

**"Semakin tinggi level JLPT deckmu, semakin banyak poin."** Karena deck
kita adalah yang *dijawab lawan*, aturan ini memberi hadiah ganda untuk
memilih deck tersulit: lawan lebih sering salah **dan** poin kita lebih
besar. Akibatnya semua orang memakai deck N1, pemula digilas, dan tidak
ada yang berlatih di levelnya sendiri. Kalau tujuannya menghargai
tantangan, yang lebih masuk akal adalah memberi poin lebih besar untuk
**menjawab benar kartu sulit**, bukan untuk memegangnya.

### Fitur baru yang belum pernah dibahas

Semuanya menambah cakupan, jadi perlu disadari sebagai pilihan:

- **Koin dan mata uang bunga (5.430)** — ini ekonomi dalam aplikasi.
  Belum ada apa pun soal untuk apa koinnya dipakai.
- **EXP +50** — kemungkinan bisa memakai sistem XP yang sudah ada.
- **"Tonton Ulang"** — menuntut penyimpanan seluruh langkah tiap
  pertandingan plus pemutar ulangnya. Fitur tersendiri, tidak kecil.

### Yang belum digambar, dan justru paling penting

**Layar menjawab belum ada.** Keempat mockup berhenti di "Battle Dimulai";
tidak ada satu pun yang menunjukkan pemain sedang mengetik jawaban. Padahal
di situlah letak keputusan tersulit kita: **keyboard kana bawaan aplikasi**
untuk mengetik bacaan hiragana. Itu layar yang paling menentukan rasa main
dan paling banyak kerjanya — layak digambar berikutnya.

Layar babak tambahan (kartu 11–20 dengan waktu dipangkas) juga belum ada.

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
