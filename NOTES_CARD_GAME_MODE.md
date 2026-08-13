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

### Bentuk konkretnya: dua jalur yang sengaja saling lepas

Wawasan yang baru kelihatan saat merumuskan ini: **benar/salah tidak
butuh server sama sekali.** Bacaan yang benar untuk tiap kartu sudah ada
di dataset yang sudah dibundel di HP — sama seperti yang dipakai
Kotoba/Kanji/Bunpou di seluruh aplikasi ini. Jadi kedua pemain bisa
langsung tahu benar/salah secara lokal, tanpa menunggu apa pun dari
server sama sekali.

Yang **benar-benar** butuh disinkronkan real-time antara dua HP cuma
empat hal: giliran siapa, kartu apa yang sedang tampil, teks yang baru
diketik (supaya lawan lihat apa yang dijawab), dan jangkar waktu giliran.
Tidak satu pun dari empat ini butuh Cloud Function untuk berjalan cepat.

| Jalur | Cepat, buat rasa main | Lambat, buat yang dihitung |
|---|---|---|
| Tempatnya | Firestore, listener biasa | Cloud Function |
| Isinya | Giliran maju, kartu berikutnya, teks jawaban tersimpan | `officialScore`, divalidasi ulang independen |
| Kecepatan | Sub-detik | Beberapa detik (jeda cold start, sudah diterima) |
| Yang menulis | Klien yang baru menjawab | Cloud Function saja |

**(Dikonfirmasi: ini memang yang dimaksud.)** Klien yang baru menjawab
langsung menulis "giliran pindah" — tidak menunggu apa pun, karena
kebenaran jawabannya tidak perlu ditulis, cukup teksnya. Lawan yang
sedang menunggu (listener Firestore biasa) langsung lihat giliran
berpindah dalam hitungan milidetik, dan menghitung sendiri secara lokal
apakah jawaban itu benar, dari teks yang baru masuk dicocokkan ke dataset
yang sudah ada di HP-nya juga. Cloud Function jalan di belakang, murni
untuk `officialScore` — kalau ada klien nakal yang menampilkan "benar"
secara lokal padahal salah, bintangnya tetap tidak bergerak karena yang
dipakai untuk rank cuma angka dari Cloud Function.

Ini juga **otomatis menegakkan** aturan "klien tidak boleh mengirim
vonis" yang sudah diputuskan di atas — klien memang tidak pernah perlu
mengirim vonis sama sekali. Benar/salahnya cuma perhitungan tampilan di
kedua HP, bukan sesuatu yang pernah ditulis ke server.

### Bentuk data

**Koreksi dari versi sebelumnya**: bentuk `cards: [cardId, ...]` yang
ditulis kemarin salah asumsi — itu mengira ada satu deck bersama yang
dibagi dua pemain. Aturan yang sudah diputuskan sejak awal justru
sebaliknya: **"tiap pemain memegang deck [sendiri], lalu saling
mengeluarkan kartu dan lawan menulis bacaannya."** Jadi ada dua deck
terpisah (20 kartu A, 20 kartu B), dan giliran menentukan **deck siapa
yang dikeluarkan kartunya** — penjawabnya selalu pemain yang **lain**,
bukan pemilik deck itu sendiri.

```
battleMatches/{matchId}
  players: [uidA, uidB]
  status: "active" | "finished"
  currentTurnUid            // deck siapa yang dikeluarkan giliran ini
                             // (penjawabnya = pemain satunya, bukan ini)
  currentRound              // 0-based, 0-9 di babak utama, 10-19 di tambahan
  cardsByPlayer: {uidA: [cardId x10], uidB: [cardId x10]}   // lihat "Undian kartu" di bawah
  turnStartedAt              // stempel waktu server, jangkar timer giliran ini
  clientResult                // dihitung cepat di HP, buat layar "selesai" instan
  officialScore: {uidA: n, uidB: n}   // HANYA Cloud Function yang menulis
  result                       // dihitung ulang Cloud Function setelah semua kartu masuk

battleMatches/{matchId}/answers/{round}
  byUid              // yang MENJAWAB (bukan pemilik deck kartu itu)
  text, submittedAt
```

`answers` sengaja jadi subkoleksi, bukan array di dokumen induk — supaya
Cloud Function bisa `onCreate` per jawaban langsung (memicu per dokumen
baru), bukan harus membandingkan isi array sebelum/sesudah tiap kali
dokumen induk berubah.

### Alur satu giliran

1. Kartu ke-`currentRound` dari deck `currentTurnUid` ditampilkan ke
   **pemain satunya** (dia yang menjawab, bukan pemilik deck).
2. Pemain penjawab mengetik jawaban, menekan kirim.
3. Klien menulis ke `answers/{currentRound}` (teks mentah saja, dengan
   `byUid` = dirinya sendiri), lalu di tulisan yang sama memajukan
   `currentRound`, memindahkan `currentTurnUid` ke pemain yang **barusan
   menjawab** (supaya giliran berikutnya kartunya keluar dari deck dia,
   sesuai pola "saling mengeluarkan kartu"), dan mengatur ulang
   `turnStartedAt`.
4. Pemilik deck yang barusan kartunya keluar (listener Firestore)
   langsung lihat jawabannya masuk, dan menampilkan benar/salah untuk
   jawaban itu — dihitung sendiri secara lokal dari dataset yang sudah
   ada di HP-nya.
5. Cloud Function terpicu oleh dokumen `answers` baru, memvalidasi ulang
   secara independen, menulis ke `officialScore`. Begitu jumlah jawaban
   yang masuk sama dengan panjang pertandingan, Cloud Function menghitung
   `result` final dan itulah yang menggerakkan bintang.

### Kalau lawan menutup aplikasi di tengah pertandingan

**Dikonfirmasi: HP lawan yang mendeteksi, bukan Cloud Function** — cara
paling sederhana untuk versi pertama, memakai timer yang memang sudah
ada (30 detik, atau versi dipangkas di babak tambahan) tanpa perlu
membangun apa pun yang baru.

Begitu jangka waktu giliran lewat (dihitung dari `turnStartedAt`
ditambah batas waktu kartu itu, bukan jam HP sendiri), pemain yang
**menunggu** — bukan yang gilirannya — yang menulis transaksi Firestore
untuk memajukan giliran, dengan kartu itu dihitung kalah sesuai aturan
yang sudah ada ("habis waktu dihitung kalah untuk kartu itu"). Transaksi
memastikan cuma satu tulisan yang berhasil kalau jawabannya ternyata
masuk di detik-detik terakhir.

> **Satu penyempurnaan kecil yang perlu ditambahkan supaya tidak terasa
> aneh**: kalau cuma "habis waktu = kalah satu kartu", pemain yang benar-
> benar menutup aplikasinya akan membuat lawannya menunggu 30 detik
> kosong berulang-ulang sampai seluruh sisa kartu habis — bisa beberapa
> menit menonton kekosongan. Karena sistem presence sudah ada dari
> rumusan undangan, syarat forfeit dini bisa ditambahkan murah: **kalau
> giliran yang sama habis waktu DAN presence lawan menunjukkan offline**,
> pertandingan langsung ditutup sebagai kemenangan WO, bukan lanjut
> menghitung kalah per kartu. Kalau lawan cuma lambat mengetik (bukan
> benar-benar pergi), presence-nya tetap online dan aturan lama (kalah
> satu kartu, lanjut) yang berlaku.

### Tiga pertanyaan yang tersisa — sekarang terjawab

**Siapa keluar kartu duluan: acak.** Tidak ada alasan kuat untuk memihak
salah satu pemain (penantang vs yang diundang, atau pemain publik vs
lawannya), dan kartu pertama tidak berarti keuntungan apa pun dalam
aturan yang sudah ada — jadi pilihan yang paling sederhana sekaligus
paling adil adalah lempar koin, ditentukan begitu `battleMatches/{matchId}`
dibuat. `currentTurnUid` awal cukup diisi hasil `Random` biasa saat
dokumen ditulis.

**Kartu diambil acak, tanpa pengembalian — dan ini sebenarnya sudah
terjawab dari keputusan lama, cuma belum pernah disambungkan.** Bagian
"Kenapa deck 20 tapi main hanya 10" sudah bilang "setengah deck tidak
terpakai tiap match, jadi kartu yang keluar berbeda-beda" — itu cuma
masuk akal kalau pengambilannya acak, bukan berurutan (kalau berurutan,
10 kartu pertama akan selalu sama persis tiap pertandingan). Dan bagian
"Kalau tetap imbang, hasilnya seri" sudah bilang **10 kartu sisa dari
deck 20 itulah bahan babak tambahan** — itu juga cuma konsisten kalau 10
yang dipakai duluan adalah **10 dari 20 yang diacak**, menyisakan tepat
10 sisanya. Jadi: `cardsByPlayer` diisi dengan mengacak seluruh 20 kartu
pemain itu lalu mengambil 10 pertama untuk `currentRound` 0-9; 10
sisanya menyusul kalau pertandingan lanjut ke babak tambahan
(`currentRound` 10-19). **Tidak ada kartu yang dobel dalam satu
pertandingan**, karena diambil dari 20 kartu yang memang berbeda-beda,
tanpa pengembalian.

**Sinkronisasi jam server-HP: pakai Realtime Database, bukan Firestore
— dan kebetulan infrastrukturnya sudah mau dibangun juga untuk
presence.** Firestore tidak punya cara membaca waktu server tanpa
menulis dulu (`FieldValue.serverTimestamp()` cuma muncul lewat tulisan
sungguhan, mahal kalau dipakai tiap detik untuk hitung mundur). Realtime
Database punya jalur bawaan persis untuk ini:
[`.info/serverTimeOffset`](https://firebase.google.com/docs/database/android/offline-capabilities#clock-skew) —
selisih antara jam HP dan jam server, dibaca sekali (misalnya begitu
pertandingan dimulai), lalu dipakai untuk menghitung "sekarang menurut
server" secara lokal (`DateTime.now() + selisih`) tanpa perlu tanya
server lagi tiap kali hitung mundur di layar diperbarui. `turnStartedAt`
yang sesungguhnya tetap ditulis lewat `FieldValue.serverTimestamp()`
Firestore seperti rencana semula — offset RTDB ini cuma dipakai supaya
hitung mundur di layar HP tidak meleset dari jam server yang jadi acuan
sesungguhnya.

Ketiganya menutup seluruh pertanyaan arsitektur pertandingan yang
sempat tersisa — tidak ada lagi yang menghalangi bentuk datanya untuk
mulai dikerjakan.

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

### Tangga bintang — usulan angka

Tingkatannya sudah ditetapkan: **Bronze, Silver, Gold, Diamond, Emerald.**
Jumlah bintangnya diserahkan ke saya, jadi ini usulan lengkap dengan
alasannya. Semua angkanya gampang disetel ulang nanti.

| Tingkat | Divisi | Bintang per divisi | Total naik |
|---|---|---|---|
| Bronze | V, IV, III, II, I | 3 | 15 |
| Silver | V, IV, III, II, I | 4 | 20 |
| Gold | V, IV, III, II, I | 5 | 25 |
| Diamond | V, IV, III, II, I | 6 | 30 |
| Emerald | — | bintang terus terkumpul | — |

Lima divisi per tingkat, sesuai permintaan agar jumlahnya sampai puluhan —
dan kebetulan ini juga cocok dengan mockup, yang memang sudah menggambar
divisi bergaya V sampai I. Total dari Bronze V ke Emerald: **90 bintang.**

Aturannya: **menang +1 bintang, seri 0, kalah −1.** Bintang penuh di satu
divisi berarti naik divisi; penuh di divisi I berarti naik tingkat dan
mulai lagi dari divisi V tingkat berikutnya.

**Beruntun 3 kemenangan memberi +2 bintang, bukan +1.** Ini bukan hiasan —
tanpanya tangga atas praktis tidak bisa didaki. Dengan 90 bintang dan
selisih menang-kalah yang tipis, pemain bagus sekalipun akan mandek
berbulan-bulan di Gold. Bonus beruntun membuat pemain yang benar-benar
lebih kuat naik dengan kecepatan yang terasa, tanpa menurunkan syaratnya
bagi yang lain. Mobile Legends memakai cara yang sama persis.

#### Jebakan yang membuat angka polos tidak bisa dipakai

Kalau menang +1 dan kalah −1 berlaku di semua tingkat, kemajuannya nyaris
berhenti. Pemain dengan tingkat kemenangan 55% hanya untung 0,1 bintang
per pertandingan — artinya butuh **sekitar 360 pertandingan** untuk naik 36
bintang. Untuk aplikasi belajar anak, itu bukan tantangan, itu tembok.

**Jadi Bronze dan Silver diberi perlindungan: kalah tidak mengurangi
bintang.** (Disetujui.) Konsekuensinya bagus:

- Naik ke Gold cuma butuh **35 kemenangan**, berapa pun kalahnya. Anak yang
  masih lemah tetap maju selama ia terus main — persis semangat yang sama
  dengan alasan kita membatalkan mode nyawa dulu.
- **Tangga yang sesungguhnya baru mulai di Gold**, tempat kalah benar-benar
  ada harganya. Puncaknya tetap berarti.

> Dicatat sebagai perlindungan di **Bronze dan Silver**, jadi kehilangan
> bintang mulai berlaku begitu masuk Gold. Kalau yang dimaksud "sampai
> Gold" itu termasuk Gold, tinggal geser satu tingkat — tidak ada bagian
> lain yang bergantung padanya.

#### Turun tingkat

Kalah saat bintang 0 menurunkan satu divisi — tapi **tidak pernah keluar
dari tingkat yang sudah dicapai.** Sekali Gold, selamanya minimal Gold III.

Alasannya: naik tingkat itu momen yang diingat anak. Mengambilnya kembali
terasa jauh lebih menyakitkan daripada nilai bintang yang hilang, dan
lantai per tingkat sudah cukup membuat kekalahan terasa tanpa menghapus
pencapaian.

### Musim

**Dua bulan sekali.** Saat musim berganti, bintang tidak dihapus habis —
pemain memulai musim baru dengan **70% bintang terakhirnya** (dibulatkan).

Bentuk reset separuh jalan seperti ini memang yang paling masuk akal di
sini: peringkat tetap bergerak tiap musim sehingga pemain baru punya
peluang, tapi pemain lama tidak dilempar balik ke Bronze V setelah dua
bulan bermain. Untuk anak, kehilangan seluruh tingkat sekaligus adalah
alasan berhenti main, bukan alasan main lagi.

### Isi kartu ditentukan oleh rank

**Kesulitannya tidak dipilih pemain — mengikuti tingkat yang sedang
dinaunginya.** Naik peringkat berarti naik tahap belajar, jadi tangganya
sekaligus menjadi kurikulum.

Usulan pemetaannya:

| Tingkat | Isi kartu |
|---|---|
| Bronze | Hiragana dasar |
| Silver | Katakana dasar + huruf gabungan (tenten, maru, youon) |
| Gold | Kanji N5 |
| Diamond | Kanji N4–N3 |
| Emerald | Kanji N2–N1 |

Kenapa kanji sudah masuk di Gold, bukan ditahan sampai Diamond: kanji
justru bagian yang paling ingin diuji pemain, dan menaruhnya di Diamond
berarti butuh 60 kemenangan sebelum kartu kanji pertama muncul — sebagian
besar pemain tidak akan pernah sampai ke sana. Di Gold, kartu kanji
pertama datang setelah 35 kemenangan, dan itu terasa sebagai hadiah,
bukan sebagai pintu terkunci.

#### Ini sekaligus menyelesaikan masalah dua keyboard

Dulu saya tandai bahwa satu pertandingan bisa butuh dua cara mengetik —
romaji untuk kartu kana, hiragana untuk kartu kanji — sehingga kotak
jawaban harus berganti wujud di tengah permainan.

Dengan isi kartu dikunci oleh tingkat, **satu pertandingan tidak akan
pernah mencampur kana dan kanji.** Jadi cara mengetiknya tetap sama dari
awal sampai akhir:

- **Bronze, Silver** → ketik romaji, cukup keyboard bawaan HP.
- **Gold ke atas** → ketik hiragana, memakai keyboard kana aplikasi.

Keyboard kana bahkan baru dibutuhkan mulai Gold, jadi bisa dikerjakan
setelah versi pertama jalan.

#### Kecuali lawan teman dan clan — di sana kartunya bebas dipilih

Isi kartu dikunci rank **hanya untuk lawan publik.** Untuk lawan teman dan
anggota clan, pemain bisa memilih sendiri kartu apa yang dipakai.

Ini sekaligus menjawab pertanyaan yang tadi terbuka: kalau Gold menantang
Diamond lewat undangan, tidak perlu aturan siapa yang menang — kartunya
memang dipilih, tinggal disepakati. Yang mengundang memilih, dan yang
diundang melihat pilihannya sebelum menerima.

**Karena itu, pertandingan teman dan clan tidak menggerakkan bintang sama
sekali.** (Diputuskan.) Kalau isinya bebas dipilih dan bintangnya tetap
bergerak, jalan pintasnya terlalu mudah — pilih hiragana, tantang teman
berulang kali, naik ke Emerald tanpa pernah menyentuh kanji.

Untungnya itu juga yang paling enak dimainkan: main santai bareng teman
jadi benar-benar santai, tidak ada yang perlu takut merusak rank-nya.
Poin belajar dan EXP tetap didapat.

**Artinya bintang hanya bergerak di pertandingan publik dan lawan bot.**

#### Akibat lain yang perlu disadari

- **Layar "Pilih Deck" di mockup jadi tidak berlaku.** Tidak ada lagi
  pilihan Kana atau Kanji — yang tampil adalah isi kartu tingkat saat ini.
  Layar 1 tinggal memilih lawan.
- Pemain yang sudah lancar kana tetap harus melewati Bronze dan Silver.
  Tidak apa-apa: keduanya berperlindungan, jadi ia akan menang beruntun
  dan naik cepat — 35 kemenangan itu lewat dengan sendirinya.
- Filter "Mode" di papan peringkat berubah makna, karena mode tidak lagi
  dipilih.

### Lawan bot saat sepi

Kalau tidak ada pemain online, lawannya bot. Tiga hal yang menyertainya:

- **Bot harus dilabeli jelas sebagai bot.** Anak tidak boleh dibiarkan
  mengira ia mengalahkan orang sungguhan. Ini aplikasi belajar untuk anak,
  dan kejujuran di sini murah harganya.
- **Bot tetap memberi bintang, di semua tingkat.** Saya sempat mengusulkan
  membatasinya sampai Silver karena khawatir peringkat bisa didaki tanpa
  pernah melawan orang — tapi keputusannya bintang tetap diberikan penuh.
- **Kesulitan bot mengikuti tingkat pemain.**

Dua keputusan itu sebenarnya saling menopang, dan itu yang membuat
kekhawatiran tadi jauh berkurang: kalau bot Diamond memang menjawab cepat
dan nyaris selalu benar, mengalahkannya bukan jalan pintas — itu prestasi
yang setara. Yang menjaga peringkat tetap berarti bukan larangan, tapi
kurva kesulitannya.

Satu hal yang perlu dijaga saat membangunnya: **bot tidak boleh punya pola
yang bisa dihafal.** Kalau kesalahannya selalu jatuh di tempat yang sama,
pemain akan menemukannya dan kurva kesulitan itu runtuh. Kesulitan
sebaiknya diatur lewat kecepatan menjawab dan peluang salah, bukan lewat
daftar kartu tertentu yang selalu ia lewatkan.

Poin belajar dan EXP juga tetap didapat dari lawan bot.

### Bentuk konkret bot — dikonfirmasi: server yang memutuskan

**Bot lewat arsitektur pertandingan yang sama persis** dengan lawan
manusia — `battleMatches` yang sama, `answers` subkoleksi yang sama,
Cloud Function penilaian yang sama. Salah satu dari dua `players` cuma
diisi penanda tetap (mis. `"BOT"`) alih-alih uid sungguhan. Ini penting
supaya bintang/poin/EXP dari lawan bot lewat **satu** sumber kebenaran
yang sama dengan lawan manusia, bukan sistem penilaian kedua yang bisa
berbeda hasil.

**Dikonfirmasi: gerakan bot diputuskan server, bukan HP pemain** —
supaya tidak ada celah klien yang di-modifikasi bisa memaksa bot selalu
salah demi menang mudah, setara ketatnya dengan lawan manusia sungguhan.

**Cara menjeda tanpa Cloud Tasks**: jeda "bot mikir dulu" itu murni
kosmetik — bagian yang menentukan (benar/salah, kapan resminya) sudah
diputuskan server seketika itu juga, tidak perlu benar-benar ditunda di
sisi server. Begitu giliran bot menjawab tiba, Cloud Function langsung
(tanpa nunggu apa pun) menggelindingkan peluang benar/salah sesuai
tingkat, memilih jawabannya, dan menulis ke `answers/{round}` — tapi
menyertakan satu field tambahan, `revealAt` (waktu tulis + jeda acak
sesuai rentang tingkat). Klien pemain manusia melihat dokumen jawaban
ini lewat listener seketika juga, tapi **sengaja menahan tampilannya**
sampai jam lokal (yang sudah disesuaikan offset RTDB) melewati
`revealAt` — barulah "bot menjawab: ..., benar!/salah!" ditampilkan dan
giliran berikutnya terbuka.

Kenapa ini tetap aman walau bagian penundaannya ada di klien: **yang
bisa dimanipulasi klien cuma ilusi kecepatannya, bukan hasilnya.**
Seandainya klien yang di-modifikasi mengabaikan `revealAt` dan langsung
menampilkan jawaban bot detik itu juga, `officialScore` tidak berubah
sedikit pun — datanya sudah ditulis lengkap oleh Cloud Function
sebelumnya. Paling buruk yang bisa didapat curang di sini cuma "bot
terasa menjawab instan", bukan "bot dipaksa salah".

**Kurva kesulitan** (usulan, gampang disetel ulang):

| Tingkat | Peluang bot jawab benar | Rentang jeda `revealAt` |
|---|---|---|
| Bronze | 50% | 15–30 detik |
| Silver | 65% | 10–25 detik |
| Gold | 80% | 6–18 detik |
| Diamond | 92% | 3–12 detik |
| Emerald | 97% | 2–8 detik |

Kedua angka digelindingkan ulang **tiap kartu**, tidak disimpan/
dipatok ke kartu tertentu — supaya "bot selalu salah di 学生" tidak
pernah bisa dihafal, sesuai aturan yang sudah diputuskan. Rentang jeda
juga sengaja selalu di bawah 30 detik supaya bot tidak pernah kena
timeout — itu bukan gaya kesulitan yang dimaksud di sini.

**Yang masih perlu diputuskan saat membangun (bukan arsitektur, cuma
konten)**: kalau bot menjawab salah, teks yang ditulis harus jawaban
yang *plausibel* salah, bukan sekadar kosong atau acak sembarangan —
pengecoh seperti ini sudah ada polanya di `kanji_combo_repository.dart`
(pengecoh berbasis mutasi dakuten/vokal untuk soal bacaan), layak dipakai
ulang polanya, bukan dibangun dari nol.

**Dikonfirmasi: bot otomatis muncul kalau lawan publik sedang sepi**,
sesuai bunyi catatan yang sudah ada dari awal — **bukan** dipilih
langsung sebagai jenis lawan sendiri. Konsekuensinya jujur perlu
dicatat: ini artinya bot **tidak bisa dibangun sendirian** dulu — perlu
tahu dulu bagaimana pemasangan lawan publik bekerja (siapa dipasangkan
dengan siapa, berapa lama menunggu sebelum dianggap "sepi") supaya ada
titik pasti kapan sistem jatuh ke bot. Itu masih pertanyaan terbuka di
bagian lain dokumen ini ("Lawan publik dipasangkan berdasarkan apa").
Mekanisme bot di atas (kurva kesulitan, `revealAt`, arsitektur
`battleMatches` yang sama) tetap bisa dikerjakan sekarang — yang
menunggu cuma bagian "kapan tepatnya sistem memutuskan untuk
menawarkannya".

### Papan peringkat bintang berdiri sendiri

Terpisah dari papan `globalScore` yang sudah ada. Keduanya mengukur hal
yang berbeda — `globalScore` itu rata-rata nilai ujian, bintang itu hasil
bertanding — jadi menggabungkannya memang cuma akan mengaburkan keduanya.

**Catatan teknis: "papan sendiri" tidak berarti koleksi Firestore baru.**
Cukup menambah field di dokumen `leaderboard/{uid}` yang sudah ada
(tingkat, jumlah bintang, id musim) lalu mengurutkannya sendiri. Cara ini
langsung mewarisi sesuatu yang sudah jadi: nama dan avatar di dokumen itu
sudah disinkronkan otomatis lewat `syncProfileInfo` setiap kali pemain
mengganti nama atau foto. Koleksi baru berarti membangun ulang seluruh
penyelarasan identitas itu tanpa alasan.

Yang perlu dipikir terpisah hanya riwayat musim — kalau peringkat musim
lama mau bisa dilihat lagi, itu baru butuh subkoleksi tersendiri.

## Cara mengundang teman/clan bertanding

Dicek dulu ke kode sebelum diusulkan, bukan reka-reka: `FriendRepository`
(pertemanan mutual lewat handshake permintaan/terima) dan `ClanRepository`
(roster clan) sudah ada, begitu juga `NotificationRepository` generik —
satu `create()` langsung memberi entri di feed notifikasi **dan** push
notification asli lewat Cloud Function `onUserNotificationCreated`.

**Yang tidak ada sama sekali: status online.** Dicek langsung —
`isOnline`, `lastSeenAt`, atau apa pun sejenisnya tidak ada satu pun di
`lib/data/`. Ini penting karena dua keputusan berikut memang menuntut
status online *sungguhan* (bukan sekadar "terakhir aktif kapan"), jadi
fitur ini butuh infrastruktur baru, bukan sekadar tabel undangan baru.

### Keputusan

| Hal | Keputusan |
|---|---|
| Status online | **Sungguhan, real-time** — bukan "terakhir aktif" |
| Tantangan tidak direspons | **Expired setelah 2 menit** |
| Cara mengundang | Tombol "Tantang" dari daftar teman / daftar anggota clan yang sudah ada |
| Isi undangan | Nama+avatar penantang, deck/level yang **sudah dipilih penantang** |
| Sasaran | Satu orang, bukan siaran ke seluruh clan sekaligus |

### Kenapa status online butuh infrastruktur baru, bukan sekadar field

Firestore tidak punya cara mendeteksi koneksi terputus. Kalau statusnya
disimpan sebagai field biasa (mis. `isOnline: true`), field itu **cuma
berubah kalau ada kode yang sengaja menulisnya jadi `false`** — dan kode
itu tidak pernah sempat jalan kalau aplikasi ditutup paksa, HP kehabisan
baterai, atau sinyal hilang mendadak. Hasilnya: status "online" yang
macet selamanya di `true` untuk pemain yang sebenarnya sudah lama pergi —
persis kebalikan dari yang dibutuhkan untuk menantang orang sungguhan.

**Firebase Realtime Database punya jawaban bawaan untuk masalah ini:**
`onDisconnect()`. Klien mendaftarkan "kalau koneksi soket saya putus,
server yang menuliskan `offline` atas nama saya" — ini terjadi di sisi
server, jadi berlaku juga saat aplikasi mati paksa, bukan cuma saat
pengguna menutup aplikasi dengan baik-baik. Firestore tidak punya
mekanisme setara sama sekali. Ini alasan kenapa presence adalah satu dari
sedikit hal di aplikasi ini yang layak keluar dari Firestore, bukan
dipaksakan ke sana.

Bentuknya kecil dan terpisah dari data pertandingan:

```
presence/{uid}: { state: "online" | "offline", lastChanged: <server timestamp> }
```

Begitu aplikasi dibuka, klien menulis `state: "online"` dan langsung
mendaftarkan `onDisconnect()` untuk menulis `state: "offline"`. Efek
sampingnya bagus: begitu path ini ada, daftar teman dan daftar anggota
clan bisa langsung menampilkan penanda "online" di mana pun mereka
muncul, bukan cuma di layar tantang — jadi kerjanya tidak habis untuk
satu fitur sempit saja.

> **Konsekuensi teknis yang harus diingat kalau ini dibangun:** Realtime
> Database punya berkas aturan sendiri (`database.rules.json`), terpisah
> dari `firestore.rules`, dan perlu di-deploy sendiri lewat Firebase
> Console — sama seperti aturan Firestore yang sudah ada, ini tidak bisa
> dipastikan sudah aktif hanya karena berkasnya benar di repo.

### Tombol "Tantang" hanya aktif kalau target online

Karena presence-nya sudah nyata, gerbangnya bisa dipasang di tempat yang
paling murah: **tombol "Tantang" di daftar teman/clan hanya aktif kalau
orang itu sedang online.** Ini lebih baik daripada mengirim tantangan
membabi buta lalu menunggu — pemain langsung tahu siapa yang bisa
ditantang sekarang, tidak ada tantangan yang dikirim ke kekosongan.

### Kenapa 2 menit, dan apa yang terjadi setelah itu

Diturunkan dari usulan awal 5 menit — pertimbangannya berubah begitu
diingat bahwa tombol "Tantang" **sudah digerbangi status online**: target
baru saja dikonfirmasi sedang online tepat sebelum tantangan terkirim,
jadi asumsi "dia lihat notifikasinya dalam hitungan detik" itu kuat, dan
2 menit sudah lebih dari cukup untuk kasus wajar. Yang hilang di angka
lebih pendek ini adalah ruang untuk kasus "target online lalu tepat saat
itu berpindah ke layar lain (menjawab kuis, dsb.) dan tidak sempat lihat
notifikasi" — kalau ini ternyata sering terjadi setelah dipakai
sungguhan, angkanya gampang dinaikkan lagi, tidak ada bagian lain yang
bergantung pada nilai pastinya.

`BattleInvite` menyimpan `expiresAt` (waktu kirim + 2 menit). **Tidak
perlu Cloud Function terjadwal untuk menegakkannya** — setiap layar yang
menampilkan daftar tantangan (baik punya penantang maupun yang ditantang)
menyaring `expiresAt < sekarang` di sisi klien, sama seperti pola
"self-heal saat dibaca" yang sudah dipakai di beberapa tempat lain di
aplikasi ini (mis. `backfillGlobalScore`). Dokumen yang sudah kedaluwarsa
boleh menumpuk secara fisik sebentar — kebersihan penyimpanan itu urusan
terpisah (kandidat: kebijakan TTL bawaan Firestore), bukan sesuatu yang
perlu menghalangi jalannya fitur.

### Bentuk data undangan

Mengikuti pola `ClanInvite` persis, ditulis ke koleksi milik target
(sama seperti undangan clan dan permintaan pertemanan) supaya aturan
`firestore.rules` yang sudah ada untuk pola ini tinggal dipakai ulang,
bukan dirancang dari nol:

```
users/{targetUid}/battleInvites/{id}
  fromUid, fromName, fromPhotoUrl, fromAvatarType, fromAvatarValue
  source: "friend" | "clan"
  deckLevel   // dipilih penantang SEBELUM undangan dikirim
  status: "pending" | "accepted" | "declined" | "expired"
  createdAt, expiresAt
```

`deckLevel` wajib sudah terisi saat undangan dibuat — bukan setelah
diterima — karena aturan yang sudah diputuskan bilang **yang diundang
melihat kartunya sebelum menerima**. Kalau dipilih setelah diterima,
target menerima tantangan tanpa tahu isinya, dan itu melanggar aturan itu
sendiri.

Menerima memicu pertandingan mulai, sama seperti `respondToInvite` untuk
clan — bedanya, "menerima" di sini bukan cuma menulis status, tapi juga
titik awal dari sesi pertandingan real-time yang sudah dibahas di bagian
"Penilaian di server, bukan di HP" di atas.

### Yang ikut terjawab

Baris "Butuh status online untuk menantang teman dan anggota clan" di
bagian "Yang masih harus diputuskan" sekarang terjawab — dihapus dari
sana, dipindah jadi bagian ini.

### Yang masih terbuka dari keputusan ini

- **Apa yang ditampilkan ke penantang kalau targetnya offline sebelum
  sempat menekan Tantang?** Kemungkinan besar tombolnya sekadar
  nonaktif/abu-abu dengan keterangan "sedang tidak online" — belum
  diputuskan bentuk pastinya.
- **Notifikasi push untuk undangan yang keburu kedaluwarsa** — apakah
  penantang perlu diberi tahu tantangannya tidak dijawab, atau cukup
  hilang diam-diam dari daftar?
- **Biaya presence**: `onDisconnect()` andal untuk deteksi putus, tapi
  menulis presence tiap kali aplikasi dibuka/ditutup menambah trafik
  Realtime Database kecil-kecilan di luar Firestore yang selama ini jadi
  satu-satunya backend. Bukan alasan membatalkan, tapi baris biaya baru
  yang perlu disadari sebelum fitur ini ramai dipakai — sama seperti
  catatan "Biaya per pertandingan" di bagian lain dokumen ini.

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

### 2. っ tidak ada di dataset kana — **sisi konverter sudah beres**

Dataset kana berisi 104 huruf per aksara: 46 dasar + 25 tenten/maru + 33
gabungan. **っ kecil sengaja tidak dijadikan entri dataset** — beda dari
huruf gojūon biasa, っ tidak punya bacaan romaji tetap sendiri (bacaannya
tergantung huruf sesudahnya), jadi kalau dipaksa jadi entri kana biasa dia
akan aneh muncul di kartu flashcard/ujian tanpa jawaban benar yang jelas.

**`RomajiConverter` sekarang menangani っ/ッ langsung lewat logika, bukan
lewat tabel**: begitu ketemu っ, ia mengintip romaji dari posisi
sesudahnya (misalnya こ → `ko`) dan mengulang huruf pertamanya saja (`k`)
— がっこう → `gakkou`, きっぷ → `kippu`, いっしょ → `issho` (termasuk kasus
っ diikuti youon, bukan cuma huruf tunggal). Diverifikasi lewat
`test/romaji_converter_test.dart`.

**Bug lain ketemu sekalian saat memperbaiki ini, dan ikut dibenahi**: youon
(きゃ, dst.) disimpan sebagai kunci dua-karakter di dataset, tapi
`RomajiConverter` sebelumnya membaca satu rune per satu rune — jadi kunci
dua-karakter itu **tidak pernah bisa cocok sama sekali**. Setiap kata
berisi youon (きょう, しゃしん, dst.) sebenarnya sudah rusak konversinya
sejak baris youon ditambahkan ke dataset, cuma belum pernah kelihatan
karena belum ada yang benar-benar memakai jalur ini untuk youon.
Sekarang `convert()` selalu coba cocokkan dua karakter dulu (mengikuti
cara `FuriganaDictionary.segment` mencocokkan kompoun), baru turun ke satu
karakter kalau tidak ketemu.

**Yang masih terbuka**: keyboard kana-nya sendiri belum dibangun sama
sekali (lihat bagian "Keyboard kana di dalam aplikasi" di atas) — begitu
dibangun, っ tetap perlu jadi tombol di baris pengubah (bersama tenten,
maru, ゃゅょ), sama seperti yang sudah digambar di mockup. Dan **ー
(chōonpu, tanda vokal panjang) masih belum tersentuh** — beda masalah
dari っ (ー bukan modifier, tapi belum ada entrinya sama sekali di dataset
maupun di konverter), jadi kata seperti ロボット yang punya ー di dalamnya
belum bisa dikonversi sempurna. Baru ketahuan saat menulis tes untuk っ;
belum diperbaiki, dicatat di sini supaya tidak hilang.

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

## Putaran ketiga — desain dianggap selesai

Ketiga perbaikan masuk semua:

1. **Furigana hilang dari kartu soal.** 学生 dan 電車 kini tampil sebagai
   kanji saja dengan label N5. Layar hasil tetap menampilkan bacaannya —
   persis seperti yang diminta.
2. **Struktur keyboard sudah benar.** 11 baris × 5 kolom vokal, dan yang
   paling penting: **celahnya dipertahankan** — baris や kosong di kolom i
   dan e, baris わ kosong di i/u/e, ん sendirian di bawah. Baris pengubah
   lengkap dan diberi label Indonesia: tenten, maru, kecil ya, kecil yu,
   kecil yo, **kecil tsu**, hapus.
3. **Navigasi bawah hilang** dari layar pertarungan.

### Sisa kesalahan yang sebaiknya TIDAK dikejar lagi

Beberapa huruf di papan keyboard masih salah — baris pertama tergambar
あ か か ヒ け (seharusnya あ い う え お), bahkan ada katakana ヒ
menyelip, dan beberapa baris lain ikut tertukar.

**Ini batas alat gambarnya, bukan kesalahan desain.** Model gambar tidak
bisa diandalkan menuliskan glif CJK tertentu, dan menyuruhnya mengulang
biasanya cuma menukar kesalahan dengan kesalahan lain.

Yang penting sudah didapat: **tata letak, jumlah baris/kolom, posisi
celah, dan daftar tombol pengubah.** Huruf-hurufnya nanti datang dari
dataset kana aplikasi sendiri saat dikodekan, bukan disalin dari gambar.

Jadi desainnya sudah cukup sebagai acuan. Putaran berikutnya sebaiknya
bukan gambar lagi.

## Prompt perbaikan untuk desain putaran kedua

Dipakai kalau desain putaran kedua mau diperbaiki, bukan digambar ulang
dari nol — supaya bagian yang sudah benar tidak ikut berubah.

````
Desain 7 layar TEISOU BATTLE ini sudah bagus. Pertahankan seluruh gaya
visual, tata letak, warna, maskot, dan semua layar yang sudah ada.
Perbaiki HANYA tiga hal berikut.

## 1. Hapus furigana dari kartu soal (paling penting)

Di layar "3. Bertanding — Menjawab", kartu 学生 digambar dengan bacaan
がくせい tertulis di atas kanjinya. Di layar "5. Babak Tambahan", kartu
電車 digambar dengan でんしゃ di atasnya.

Itu jawaban yang justru sedang ditanyakan ke pemain — jadi soalnya
membocorkan jawabannya sendiri.

Perbaikan: kartu soal HANYA menampilkan kanjinya saja (学生, 電車), tanpa
bacaan kana apa pun di atas, di bawah, maupun di sampingnya. Label level
(N5) boleh tetap ada.

Jangan diubah di layar "6. Hasil Pertandingan" — di sana bacaan memang
sudah seharusnya ditampilkan, dan itu sudah benar.

## 2. Rapikan tata letak keyboard kana

Sekarang ada huruf yang muncul dua kali (や, ゆ, よ, ろ, っ) dan ada
kolom yang tidak jelas.

Susun ulang mengikuti tabel gojūon: 5 kolom vokal (a, i, u, e, o) dan
baris per konsonan, berurutan dari atas ke bawah:

  あ い う え お
  か き く け こ
  さ し す せ そ
  た ち つ て と
  な に ぬ ね の
  は ひ ふ へ ほ
  ま み む め も
  や ・ ゆ ・ よ
  ら り る れ ろ
  わ ・ ・ ・ を
  ん

Bagian yang kosong (baris や di kolom i dan e, baris わ di kolom i, u, e)
dibiarkan KOSONG sebagai celah, jangan diisi huruf lain dan jangan
dirapatkan — kesejajaran tiap kolom vokal itu yang membuat papan ini
mudah dibaca anak.

Di bawah papan itu, satu baris tombol pengubah:
  ゛(tenten)   ゜(maru)   ゃ   ゅ   ょ   っ   ⌫ (hapus)

Lalu tombol "KIRIM JAWABAN" di paling bawah.

## 3. Navigasi bawah

Hilangkan saja navigasi bawah dari layar-layar pertarungan (layar 3, 4,
5). Saat bertanding, layarnya harus penuh tanpa gangguan.

Selain tiga hal itu, jangan ubah apa pun.
````

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
   Kartu soal HANYA menampilkan kanjinya (misalnya 学生) — tanpa furigana
   sama sekali, karena bacaan itulah yang sedang ditanyakan.
   Harus menampilkan keyboard kana buatan aplikasi secara lengkap:
   - Papan gojūon 5 kolom vokal (a, i, u, e, o) dengan baris per konsonan:
     あ/か/さ/た/な/は/ま/や/ら/わ/ん. Bagian yang memang kosong (baris や
     di kolom i dan e, baris わ di kolom i, u, e) dibiarkan kosong sebagai
     celah — jangan diisi dan jangan dirapatkan. Jangan ada huruf yang
     muncul dua kali.
   - Satu baris tombol pengubah di bawahnya: ゛(tenten), ゜(maru), ゃ, ゅ,
     ょ, っ, dan tombol hapus.
   - Tombol kirim jawaban.
   - Kolom jawaban yang menampilkan kana yang sudah diketik.
   っ WAJIB ada — tanpa itu kata seperti 学校 (がっこう) tidak bisa diketik
   sama sekali.
   Sisakan ruang lebar di bagian bawah layar untuk keyboard ini, dan
   jangan tampilkan navigasi bawah aplikasi di layar pertarungan.
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
