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

## Mockup "TEISOU BATTLE" — acuan tampilan, bukan acuan aturan

Empat layar dibuat user bersama ChatGPT: pencarian lawan, mulai
pertarungan, hasil, dan papan peringkat.

> **Statusnya acuan visual saja.** Arah tampilan diambil dari sini; aturan
> mainnya tetap yang sudah diputuskan di tabel atas. Jadi angka dan
> mekanik yang tergambar di mockup **tidak mengikat**.

Yang layak diambil dari sisi tampilan: susunan dua pemain berhadapan
dengan deck di kiri-kanan, kartu tertutup berjejer di bawah, panel skor
ringkas di tengah, maskot yang memberi semangat, dan gaya sakura/torii
yang memang sudah jadi bahasa visual aplikasi ini. Layar hasil dengan
deretan kartu yang dimainkan beserta tanda benar/salah juga bagus — itu
menjadikan hasil pertandingan sekaligus bahan belajar.

Dua hal dari mockup yang justru **memperjelas** keputusan kita, dan
sebaiknya dipertahankan sebagai istilah:

- **"Target: 10 per pemain"** menjawab pertanyaan yang sempat tergantung:
  10 kartu berarti **10 ronde, 20 jawaban**.
- **"Mode: Kanji (N5–N1)"** memisahkan istilah dengan rapi: *mode* =
  jenis deck, terpisah dari pilihan lawan.

### Elemen gambar yang jangan ikut disalin jadi aturan

Bukan kritik terhadap desainnya — cuma penanda supaya tidak diam-diam
berubah jadi spesifikasi waktu nanti dibangun:

- **`HP 5` dan "Damage"** — konsep nyawa sudah dibatalkan; yang berlaku
  adalah berakhir di 10 kartu, poin terbanyak menang.
- **🏆 1250 (+50) / 1130 (−20)** — itu bentuk rating berjalan, sedangkan
  yang dipilih adalah bintang bertingkat. Di layar hasil bahkan ada dua
  angka bergerak sekaligus (🏆 +50 dan "+5 Poin Rank").
- **Papan direset mingguan** — aturan musim belum diputuskan.
- **Bottom nav 6 tab** — aplikasi sekarang 3 tab, hasil penyederhanaan
  yang disengaja dari 4. Ini satu-satunya elemen *tampilan* yang sebaiknya
  tidak diikuti.

### Dua elemen yang kalau diambil, ada harganya

**Chat bebas di VS Publik.** Untuk teman dan clan wajar. Untuk lawan acak,
artinya anak bertukar teks bebas dengan orang tak dikenal — dan aplikasi
ini sudah menangani audiens campuran secara serius lewat `AdAudience`.
Ini jenis hal yang bisa membuat aplikasi kehilangan status Families di
Play, dan pelaporan menuntut moderasi yang belum ada sama sekali.
**Stiker saja sudah memberi kehangatan yang sama tanpa risiko itu.**

**"Deck JLPT lebih tinggi = poin lebih banyak."** Deck kita adalah yang
*dijawab lawan*, jadi aturan ini memberi hadiah ganda untuk memilih deck
tersulit: lawan lebih sering salah **dan** poin kita lebih besar. Semua
orang akhirnya memakai N1 dan tidak ada yang berlatih di levelnya sendiri.
Kalau maksudnya menghargai tantangan, yang tepat adalah poin lebih besar
untuk **menjawab benar kartu sulit**, bukan untuk memegangnya.

### Layar menjawab (mockup kelima)

Menyusul kemudian, dan menutup kekosongan yang paling penting. Yang
berguna dari sini:

- **Ruang untuk mengetik dapat jatah besar** — satu pita lebar di bawah,
  kira-kira sepertiga tinggi layar. Itu kabar baik: papan gojūon 5×10
  ditambah tombol tenten, maru, huruf kecil, dan っ butuh ruang, dan
  ternyata jatahnya cukup.
- **Aturannya ditulis langsung ke pemain**: "(Romaji untuk Kana, Hiragana
  untuk Kanji)". Bagus — aturan yang harus dijelaskan di layar bantuan
  biasanya aturan yang salah.
- Slot kartu diberi label jelas — kartu lawan muncul di sisi kita saat
  giliran kita. Alur gilirannya jadi terbaca tanpa penjelasan.

**Isi keyboard-nya sendiri masih kosong** (baru kotak putus-putus dengan
ikon). Jadi yang sudah diputuskan barulah *tempatnya*, bukan bentuknya.

### Satu hal baru yang baru kelihatan setelah layar ini digambar

**Ada dua cara mengetik dalam satu pertandingan.** Kartu kana dijawab
dengan romaji — butuh huruf latin. Kartu kanji dijawab dengan hiragana —
butuh keyboard kana. Deck kanji N5–N1 isinya kanji semua, jadi dalam satu
pertandingan mungkin konsisten; tapi begitu ada mode deck campuran, **kotak
jawaban harus berganti wujud tergantung jenis kartu yang sedang dijawab**.

Jalan paling sederhana: kartu kana memakai keyboard bawaan HP (semua HP
punya huruf latin, tidak ada hambatan sama sekali), kartu kanji memakai
keyboard kana bawaan aplikasi. Perpindahannya perlu terasa mulus, bukan
mengagetkan.

Alternatifnya: keyboard bawaan aplikasi menyediakan dua tata letak dan
berganti sendiri mengikuti jenis kartu — lebih rapi dilihat, lebih banyak
kerjanya.

### Yang masih belum digambar

- **Isi keyboard kana**-nya sendiri.
- Ada tombol kirim, atau jawaban otomatis terkirim begitu cocok?
- Layar babak tambahan (kartu 11–20, waktu dipangkas 2 detik tiap kartu).

Fitur baru yang ikut tergambar dan belum pernah dibahas: **Koin**, mata
uang bunga (5.430), dan **Tonton Ulang** — yang terakhir menuntut
penyimpanan seluruh langkah tiap pertandingan beserta pemutarnya.

## Yang belum tersentuh sama sekali

Dicek langsung ke data dan kode, bukan perkiraan.

### 1. Bacaan di dataset disimpan sebagai romaji, bukan kana

```json
{"word": "学生", "reading": "gakusei"}
```

Padahal jawaban kartu kanji diketik dalam **hiragana**. Jadi harus ada
konversi sebelum dibandingkan.

Kabar baiknya dua-duanya sudah setengah jalan: `RomajiConverter` sudah ada
(kana → romaji), dan **gaya romaji di dataset ternyata cocok** dengan
konversi per-huruf — 東京 ditulis `toukyou` (bukan `tōkyō`), 来週 ditulis
`raishuu`. Jadi jalurnya: pemain mengetik がくせい → diubah jadi `gakusei`
→ dibandingkan.

### 2. っ tidak ada di dataset kana — dan ini memblokir

Dataset kana berisi 104 huruf per aksara: 46 dasar + 25 tenten/maru + 33
gabungan. **っ kecil tidak termasuk**, begitu juga ッ dan ー.

Akibatnya nyata: **学校 dibaca がっこう, dan がっこう tidak bisa diketik**
dengan keyboard yang dibangun dari dataset itu, juga tidak bisa dikonversi
karena konverter tidak punya entri untuk っ.

Jadi dua hal wajib, dan keduanya kecil tapi tidak boleh terlewat:

- **Keyboard kana harus punya っ** selain tenten, maru, dan huruf kecil
  ゃゅょ.
- **Konverter harus menangani sokuon**: っ menggandakan konsonan
  berikutnya (がっこう → `gakkou`).

### 3. Kata berokurigana: jawabannya sampai mana?

**1.235 dari 7.275 contoh kata (16%) mengandung okurigana** — misalnya
生まれる dengan bacaan `umareru`. Perlu diputuskan apakah pemain mengetik
seluruhnya (うまれる) atau hanya bagian kanjinya (う). Mengetik seluruhnya
lebih sederhana dan lebih jujur sebagai latihan membaca.

### 4. Kalau tidak ada lawan, fiturnya mati

Ini risiko paling praktis dan belum dibahas sama sekali. Mode PvP serentak
menuntut **dua pemain online di saat yang sama**, sementara aplikasi ini
baru di tahap internal testing. Antrean yang kosong membuat "Mencari
Lawan…" berputar selamanya, dan fitur yang tidak pernah berhasil dimulai
akan ditinggalkan.

Perlu rencana untuk keadaan sepi — misalnya lawan bot, atau lawan "hantu"
yang memainkan ulang rekaman jawaban pemain lain.

### 5. Klien tidak boleh mengirim vonis, hanya teks jawaban

Ini turunan dari aturan skor dihitung di server, tapi belum pernah ditulis
tegas. Kalau HP mengirim "aku benar", curang jadi sepele — tinggal selalu
mengirim benar. Yang dikirim harus **teks jawabannya**, dan server yang
memutuskan benar atau salah.

Konsekuensinya: kunci jawaban harus ada di sisi server juga.

### 6. Butuh koneksi stabil — bertentangan dengan cara aplikasi ini dipakai

Catatan proyek ini berkali-kali menyebut aplikasi dipakai anak "di
perjalanan". Pertandingan serentak justru jenis fitur yang paling tidak
tahan sinyal jelek. Bukan alasan membatalkan, tapi menegaskan kenapa
penanganan pemain terputus perlu dipikirkan sejak awal, bukan belakangan.

### 7. Menyontek

Dengan 30 detik, pemain punya waktu berlimpah untuk pindah aplikasi dan
mencari bacaannya. Tidak ada cara benar-benar mencegahnya di HP.
Pertahanan alaminya cuma tekanan waktu — dan itu baru terasa di babak
tambahan yang waktunya memendek.

### 8. Biaya per pertandingan

Tiap pertandingan berarti sejumlah tulisan Firestore ditambah pemanggilan
Cloud Function. Aplikasinya gratis dan bersandar pada iklan, jadi biaya
per pertandingan perlu disadari sebelum ramai, bukan sesudah.

## Yang masih harus diputuskan

Belum dijawab. Sebagian menentukan bentuk, sebagian tinggal angka:

**Aturan main**
- 10 kartu itu 10 ronde (tiap pemain mengeluarkan satu kartu, jadi 20
  jawaban), atau 10 jawaban total? Dengan giliran bergantian, keduanya
  masuk akal.
- Deck 20 kartu dipilih sendiri, atau dibagikan otomatis dari level JLPT?
- Siapa yang mengeluarkan kartu duluan?
- Kartu diambil acak dari deck atau berurutan? Boleh kartu yang sama
  muncul dua kali dalam satu pertandingan?
- Kalau koneksi putus lalu pemain kembali, bisa menyambung pertandingan
  yang sama atau dianggap selesai?
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

## Desain putaran kedua (7 layar + kartu aturan)

Dibuat ulang memakai prompt di bawah. **Jauh lebih tepat** — keempat hal
yang bermasalah di putaran pertama hilang semua: tidak ada HP/damage,
peringkat sudah memakai bintang bertingkat (Pemula III → Pemula II, +1
bintang), tidak ada chat teks bebas (hanya stiker), dan tidak ada bonus
poin untuk deck level tinggi.

Aturan main tercermin dengan benar di mana-mana: 10 kartu per pemain, 30
detik sebagai batas atas, kana romaji dan kanji hiragana, skor = jumlah
jawaban benar, imbang lanjut ke kartu 11–20 dengan potongan 2 detik, dan
seri kalau masih imbang. Layar hasil bahkan memecah skornya jadi "Ronde
1–10: 5–5 (Imbang)" dan "Ronde 11–15: 2–0", jadi babak tambahannya
terbaca.

Keyboard kana-nya juga ada, lengkap dengan **っ**, tenten, maru, huruf
kecil ゃゅょ, tombol hapus, dan tombol kirim.

### Satu kesalahan yang membatalkan permainannya

**Kartu menampilkan furigana di atas kanjinya.** Di layar 3, 学生 digambar
dengan がくせい tertulis di atasnya — sementara pemain diminta mengetik
bacaan kata itu. Jawabannya terpampang di soal. Hal yang sama terjadi di
layar 5 (電車 dengan でんしゃ).

Ini bukan detail visual, ini membatalkan seluruh mekanik permainan. **Kartu
soal hanya boleh menampilkan kanjinya saja.** Furiganya baru muncul setelah
dijawab — dan di layar hasil, tempatnya memang sudah benar.

### Hal kecil lainnya

- **Papan keyboard punya kolom ganda.** Beberapa huruf muncul dua kali (や,
  ゆ, よ, ろ, っ). Kemungkinan besar cuma kesalahan gambar, tapi tata
  letak sebenarnya perlu mengikuti gojūon: 5 baris vokal × kolom konsonan,
  dengan lubang di tempat yang memang kosong — sama seperti tabel kana yang
  sudah ada di aplikasi.
- **Bottom nav 5 tab** (Beranda, Belajar, Kartu, Battle, Profil).
  Aplikasinya sekarang 3 tab. Sudah turun dari 6, tapi tetap perlu
  diputuskan apakah Battle memang layak jadi tab utama atau cukup masuk
  lewat Beranda.

### Yang justru ikut terputuskan lewat gambar ini

- **Pemain memilih sendiri kartu mana yang dikeluarkan** tiap giliran
  (layar 4), bukan diambil acak oleh sistem. Ini menjawab pertanyaan yang
  sebelumnya terbuka, dan pilihannya bagus: ada unsur siasat, dan pemain
  bisa menyimpan kartu sulit untuk saat genting.
- **Ada musim** ("Musim ini" di papan peringkat).
- Papan peringkat diperbarui berkala, bukan seketika — masuk akal dan
  murah.

## Prompt untuk membuat ulang desainnya

Disimpan di sini supaya tidak hilang, dan supaya kalau desainnya dibuat
ulang lagi nanti, aturannya tetap sama. Salin blok di bawah apa adanya.

````
Kamu adalah desainer UI game mobile. Buatkan mockup layar untuk sebuah mode
permainan kartu bernama "TEISOU BATTLE" di dalam aplikasi belajar bahasa
Jepang bernama Teisou — Kana Master.

## Tentang aplikasinya

Aplikasi belajar bahasa Jepang untuk anak dan pemula berbahasa Indonesia.
Seluruh teks antarmuka dalam Bahasa Indonesia. Nuansanya ramah, hangat,
dan sopan — bukan garang seperti game pertarungan pada umumnya.

## Gaya visual yang harus diikuti

- Palet: koral/pink lembut sebagai warna utama, biru langit lembut sebagai
  warna kedua, teks biru tua (navy), kartu putih krem. Latar bergradasi
  sangat lembut.
- Ornamen khas Jepang yang lembut: kelopak sakura beterbangan, gerbang
  torii, Gunung Fuji, pagoda — semuanya samar sebagai latar, tidak ramai.
- Maskot kucing maneki-neko putih berkalung merah dan lonceng emas sebagai
  pemain kita; anjing shiba sebagai lawan. Keduanya bergaya kartun bulat,
  ramah, mata besar.
- Sudut membulat besar, bayangan lembut, jarak antar elemen lega.
- Ikon sederhana dan jelas. Hindari kesan mewah/metalik/gelap.

## Aturan main yang WAJIB tercermin di desain

- Tiap pemain punya deck 20 kartu. Satu pertandingan berhenti di 10 kartu
  per pemain (10 ronde, 20 jawaban).
- Pemain bergantian mengeluarkan kartu. Lawan menjawab bacaan kartu itu.
- Batas waktu 30 detik per giliran, TAPI ini batas atas — begitu dijawab,
  giliran langsung berganti. Tampilkan sebagai hitung mundur.
- Kartu kana dijawab dengan mengetik ROMAJI.
- Kartu kanji berisi KATA (misalnya 学生, 電車, 友達), dijawab dengan
  mengetik HIRAGANA.
- Skor pertandingan = jumlah jawaban benar. Poin terbanyak menang.
- Kalau imbang di kartu ke-10, lanjut ke kartu 11–20 dengan waktu
  dipangkas 2 detik tiap kartu. Kalau masih imbang juga, hasilnya seri.
- Peringkat memakai BINTANG BERTINGKAT seperti Mobile Legends (tingkatan
  bernama + jumlah bintang), bukan angka rating berjalan.
- Mode gratis. Boleh ada iklan banner kecil di layar non-pertandingan.

## Layar yang diminta

1. Pilih mode: jenis deck (Kana / Kanji N5–N1) dan jenis lawan (Teman,
   Clan, Publik).
2. Mencari lawan.
3. **Layar bertanding — giliran MENJAWAB.** Ini yang paling penting.
   Harus menampilkan keyboard kana buatan aplikasi secara lengkap:
   - Papan hiragana gojūon (あ sampai ん).
   - Tombol tenten (゛) dan maru (゜).
   - Tombol huruf kecil ゃ ゅ ょ.
   - Tombol huruf kecil っ — WAJIB ada, tanpa ini kata seperti 学校
     (がっこう) tidak bisa diketik sama sekali.
   - Tombol hapus dan tombol kirim.
   - Kolom jawaban yang menampilkan kana yang sudah diketik.
   Sisakan ruang lebar di bagian bawah layar untuk keyboard ini.
4. Layar bertanding — giliran MENGELUARKAN kartu (memilih kartu dari deck).
5. Babak tambahan kartu 11–20, dengan penanda bahwa waktunya menyusut.
6. Hasil pertandingan: skor akhir, daftar semua kartu yang dimainkan
   beserta bacaannya dan tanda benar/salah, perubahan bintang, tombol
   main lagi.
7. Papan peringkat bintang: tingkatan, jumlah bintang, posisi pemain.

## Yang TIDAK boleh ada

- JANGAN menampilkan furigana (bacaan kana) di atas kanji pada kartu soal.
  Pemain justru sedang diminta menebak bacaan itu — menampilkannya sama
  saja membocorkan jawaban. Kartu soal hanya berisi kanjinya saja.
  Furigana baru boleh muncul setelah dijawab dan di layar hasil.
- Jangan pakai HP / nyawa / damage. Pertandingan selesai karena kartu
  habis, bukan karena nyawa habis.
- Jangan pakai angka rating berjalan (misalnya 1200 → 1250). Pakai
  bintang bertingkat.
- Jangan ada fitur chat teks bebas dengan lawan. Stiker atau emoji siap
  pakai saja — aplikasi ini dipakai anak-anak.
- Jangan tampilkan bonus poin karena memakai deck level tinggi.
- Jangan mengubah navigasi utama aplikasi menjadi banyak tab.

## Format keluaran

Satu gambar per layar, rasio potret untuk ponsel, resolusi tinggi. Semua
teks dalam Bahasa Indonesia. Sertakan teks placeholder yang masuk akal
(nama pemain, angka skor, contoh kartu kanji nyata seperti 学生 / 電車 /
友達).
````
