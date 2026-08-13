# Mode Game Card

Catatan rumusan untuk mode permainan kartu di Teisou — Kana Master.

## Ringkasan serah-terima sesi (2026-08-14) — baca ini dulu kalau
## mengambil alih sesi ini dari awal

**Seluruh 10 butir "Urutan mengerjakan" (di bawah) sudah dibangun,
diuji, dan di-deploy ke produksi `teisou-kana-master`.** Ini BUKAN
berarti fitur ini 100% selesai secara produk — lihat "Yang masih benar-
benar terbuka" di bawah, dua hal besar masih kurang.

### Sudah selesai + hidup di produksi

| Tahap/butir | Status |
|---|---|
| Tahap 1 (keyboard kana, field rank, presence RTDB) | ✅ selesai, hidup, diverifikasi di perangkat fisik |
| Tahap 2 butir 4-7 (battleMatches, layar pertandingan, penilaian Cloud Function) | ✅ selesai, hidup, diverifikasi lintas 2 device fisik |
| Tahap 3 butir 8 (bot AI) | ✅ selesai, hidup, **diverifikasi ujung-ke-ujung di perangkat fisik** (Moto G52J, match nyata sampai selesai) |
| Tahap 3 butir 9 (undangan teman/clan) | ✅ selesai, hidup, **diverifikasi ujung-ke-ujung** (G52J vs emulator, dua akun, match tuntas 1-0) |
| Tahap 3 butir 10 (matchmaking publik) | ✅ selesai, hidup, **diverifikasi ujung-ke-ujung** (dipasangkan ~12 dtk, kartu identik di dua layar, match tuntas 4-3) |
| Tangga bintang (di luar 10 butir) | ✅ selesai, hidup, **diverifikasi ujung-ke-ujung** (3 kemenangan beruntun: Bronze V 0/3 → V 1/3 → V 2/3 → IV 1/3; yang kalah tetap 0/3) |

Semua Cloud Function (`onBattleAnswerCreated`, `onBattleMatchWritten`,
`onMatchmakingQueueJoined`, `onBattleMatchConcluded`) tampil di `firebase functions:list`
(`asia-southeast1`). `firestore.rules` dan `database.rules.json`
keduanya sudah dirilis lewat `npx firebase-tools@latest deploy` — CLI
ini (bukan binary `/c/flutter/bin/firebase` yang macet) adalah jalur
deploy yang benar ke depannya, lihat "Penemuan penting" di butir 7.

### Yang masih benar-benar terbuka (2 hal besar)

1. ✅ **SELESAI (2026-08-14): butir 9 dan 10 sudah diverifikasi di
   perangkat sungguhan** — Moto G52J melawan emulator Pixel 8, dua akun
   Firebase berbeda, keduanya main sampai pertandingan tuntas dengan
   skor yang cocok di kedua layar. Detailnya di penutup butir 9 dan 10.
   Sisa yang belum dicoba tinggal jalur-jalur pinggir: menolak undangan,
   menantang lewat clan, jatuh ke bot saat benar-benar sendirian, dan
   memastikan dua tingkat berbeda tidak saling dipasangkan.
2. ✅ **SELESAI (2026-08-14): tangga bintang sudah hidup** —
   `functions/battle_stars.js` (baru) berisi seluruh aturan yang selama
   ini cuma rumusan: menang +1, seri 0, kalah −1, perlindungan Bronze/
   Silver, bonus beruntun +2, naik/turun divisi, lantai per tingkat, dan
   pergantian musim dengan bawaan 70%. Dipicu oleh
   `onBattleMatchConcluded`, trigger baru yang menyala begitu sebuah
   match punya `result`. Sudah di-deploy dan **sudah diverifikasi di dua
   perangkat sungguhan** — rinciannya di bagian "Tangga bintang sudah
   jalan" di bawah.

   Yang **belum** dikerjakan dari bagian bintang: papan peringkat
   bintangnya sendiri belum dibuat — Cloud Function
   sudah menulis field-nya (`cardGameTier`/`cardGameStars`/
   `cardGameStarTotal`/`cardGameSeason` di `leaderboard/{uid}`), tapi
   belum ada layar yang membacanya.

3. ✅ **SELESAI (2026-08-14): pintu masuk dari Home sudah ada.** Sampai
   hari ini seluruh mesin mode ini — matchmaking, bot, penilaian di
   server, tangga bintang — sudah jadi dan ter-deploy tapi **tidak bisa
   dibuka pengguna sungguhan sama sekali**: satu-satunya jalan masuk
   adalah tombol Tantang di `ChatHubScreen` (khusus lawan teman), dan
   lawan publik cuma bisa dicoba dengan menyunting `main.dart` sementara.
   Sekarang ada bagian **"Bertanding"** di Home berisi kartu **"Mode
   Kartu"** (`_CardGameCard` di `modules_section.dart`) yang langsung
   membuka `BattleMatchmakingScreen`.

   Kartunya sekaligus jadi satu-satunya tempat pemain bisa melihat
   peringkatnya tanpa memulai apa pun — subjudulnya menampilkan
   tingkat + bintang sungguhan ("Bronze IV · 1/3 bintang"), diambil dari
   `cardGameRankProvider`. Kalau peringkatnya belum termuat, subjudulnya
   jatuh ke deskripsi biasa, bukan memblokir pintunya — masuk
   pertandingan sama sekali tidak bergantung pada tahu peringkat lebih
   dulu.

   Judul layar matchmaking-nya juga dilepas dari "(dev)" karena sekarang
   benar-benar dilihat pengguna, dan **tombol back-nya muncul dengan
   sendirinya** begitu layar itu di-push dari Home (sebelumnya tidak ada
   karena ia jadi akar navigasi di build tes).

   Dijaga oleh `test/widget_test.dart` ("HomeScreen has a way into Card
   Game Mode") — dicek benar-benar menggigit dengan menghapus kartunya.
   Ini justru kegagalan yang tidak bisa dilihat pemeriksaan lain: semua
   layarnya meng-compile, merender, dan lulus tesnya sendiri sambil tetap
   tidak bisa dijangkau.

### Hal kecil lain yang perlu diingat

- **Navigasi produksinya setengah ada** — dicek ulang ke kode, dan ini
  koreksi terhadap catatan sebelumnya yang menulis "belum ada sama
  sekali":
  - **Jalur undangan SUDAH bisa dijangkau pengguna sungguhan.** Tombol
    Tantang hidup di `ChatHubScreen` (dibuka dari Profil) dan
    `ClanMembersScreen` (dibuka dari tab Clan), dan menerima undangan
    membuka `BattleScreen` langsung (`chat_hub_screen.dart:173`).
    **Artinya butir 9 sebenarnya bisa diuji di perangkat fisik hari ini
    juga, tanpa menyentuh `main.dart` sama sekali** — cukup dua akun
    yang berteman.
  - **Yang benar-benar belum punya pintu masuk cuma memulai sendiri**:
    `BattleTestStartScreen`/`BattleMatchmakingScreen` masih perlu
    `main.dart` diubah sementara (lihat teknik verifikasi butir 8 —
    ubah `_TutorialGate`, build, install, lalu
    `git checkout -- lib/main.dart` sebelum commit). Jadi butir 10 yang
    masih butuh cara itu untuk diuji.
  - Tidak ada tombol di Home/Modules yang membuka mode ini. Ini bukan
    bagian dari 10 butir — belum pernah diminta, jadi belum dikerjakan.
- **Trade-off yang sengaja dibiarkan terbuka** (dicatat lengkap di
  masing-masing butir, bukan lupa): kedaluwarsa undangan 2 menit murni
  kosmetik di sisi tampilan (butir 9); menolak undangan tidak
  membatalkan match yang sudah terlanjur dibuat (butir 9); balapan
  kecil di detik ke-20 saat jatuh ke bot bisa (jarang) membuat dua
  match sekaligus (butir 10).

Dua hal lain yang jadi *prasyarat* fitur ini sudah dikerjakan duluan
juga (lihat "Modal yang sudah ada"): dataset kana diperluas ke 104
karakter (tenten/maru/youon), dan `RomajiConverter` sudah bisa
menangani っ/youon dengan benar. Ketiganya kode sungguhan yang sudah
jalan (`flutter analyze` bersih, test suite hijau), bukan cuma
catatan.

## Urutan mengerjakan (disusun dari ketergantungan, bukan sembarang)

Satu hal yang baru kelihatan saat menyusun urutan ini: **bahkan
pertandingan lawan bot butuh tahu tingkat/rank pemain saat ini duluan**
— "isi kartu ditentukan oleh rank" berlaku untuk semua jenis lawan,
termasuk bot. Jadi field rank harus ada lebih dulu daripada biasanya
fitur "peringkat" dikerjakan (biasanya di akhir).

**Tahap 1 — fondasi, tidak saling bergantung, bisa paralel**
1. ✅ **Selesai** — Keyboard kana. `KanaKeyboardInput`
   (`lib/core/services/kana_keyboard_input.dart`) adalah kelas logika
   murni (tanpa widget) yang menangani tenten/maru/small-ya-yu-yo/
   sokuon/backspace — semua pemetaan hurufnya diturunkan langsung dari
   `row`/`column` dataset kana yang sudah ada, bukan tabel kedua yang
   ditulis tangan, jadi tidak ada risiko drift antara dataset dan
   keyboard. `KanaKeyboard` (`lib/core/widgets/kana_keyboard.dart`)
   adalah widget-nya — grid gojūon 46 karakter dasar + baris modifier
   (゛ ゜ ゃ ゅ ょ っ ⌫), murni controlled component (`value`/
   `onChanged`, tanpa tombol submit sendiri) sesuai keputusan "mandiri,
   tidak terikat konteks pertandingan" di atas. Tombol modifier otomatis
   nonaktif (abu-abu, tidak bisa ditekan) kalau karakter terakhir di
   buffer tidak punya bentuk itu (mis. ゛ nonaktif setelah "あ", yang
   tidak punya bentuk tenten). Diuji lewat dua file test: satu untuk
   logikanya sendiri (`test/kana_keyboard_input_test.dart`, terhadap
   dataset kana sungguhan) dan satu untuk widget-nya
   (`test/kana_keyboard_test.dart`, terhadap data hiragana sungguhan
   yang di-override lewat provider — bukan lewat asset loading
   langsung, karena dua widget test berurutan yang sama-sama menunggu
   `rootBundle.loadString` lewat `FutureProvider` terbukti flaky:
   test pertama selesai, test kedua tidak pernah selesai walau sudah
   ditunggu lama — jadi datanya di-fetch sekali di `setUpAll` lalu
   di-inject lewat `overrideWith`, menghindari race itu sepenuhnya).
   `flutter analyze` bersih, seluruh test suite (344 test) hijau.
   Belum dipasang ke layar mana pun — baru komponennya saja, sesuai
   urutan "bisa didemokan sendiri tanpa nunggu apa pun".
2. ✅ **Selesai** — Field rank minimal. `CardGameRank`
   (`lib/data/models/card_game_rank.dart`) menyimpan `tier`/`division`/
   `stars`/`season`, default `CardGameRank.initial()` (Bronze V, 0
   bintang, musim 1) untuk pemain yang field-nya belum pernah ditulis
   — sengaja **belum ada logika naik-turun tingkat sama sekali** (tidak
   ada method "menang"/"kalah", tidak ada perlindungan Bronze/Silver,
   tidak ada bonus beruntun, tidak ada pergantian musim) sesuai
   cakupan yang disepakati; logika itu baru masuk akal begitu
   `battleMatches` sungguhan ada yang memicunya, jadi menyatu dengan
   pekerjaan Cloud Function penilaian di Tahap 2.
   `CardGameTier` (enum Bronze..Emerald) membawa semua angka dan
   pemetaan yang sudah dikunci di bagian "Tangga bintang" dan "Isi
   kartu ditentukan oleh rank" di bawah — `starsPerDivision` (3/4/5/6),
   `hasDivisions` (Emerald: tidak), `lossProtected` (Bronze/Silver),
   `cardContent` (Bronze→hiragana ... Emerald→N2-N1), dan
   `answersWithKanaKeyboard` (Gold ke atas) — supaya Tahap 2 nanti
   tinggal membaca properti ini, bukan menghafal ulang tabelnya.
   `ProgressRepository` dapat tiga method baru
   (`watchCardGameRank`/`getCardGameRank`/`setCardGameRank`), mengikuti
   pola persis yang sudah ada untuk `Subscription` (field map di
   `users/{uid}.cardGameRank`, bukan koleksi terpisah), dan
   `cardGameRankProvider` (StreamProvider) ditambahkan ke
   `providers.dart` mengikuti pola `subscriptionProvider`. Belum ada
   satu pun layar atau kode lain yang membacanya — murni "field-nya
   ADA", sesuai cakupan Tahap 1 butir 2. `flutter analyze` bersih,
   355 test hijau (11 test baru di `test/card_game_rank_test.dart`).
3. ✅ **Selesai dan sudah hidup (bukan cuma kode)** —
   Presence. `PresenceService` (`lib/core/services/presence_service.dart`)
   menulis `presence/{uid}: { state, lastChanged }` ke Realtime Database
   begitu aplikasi dibuka (`goOnline`, dipanggil dari `appStartupProvider`
   sama seperti `FcmService.init`), dan mendaftarkan `onDisconnect()`
   **sebelum** menulis status online — urutannya sengaja begitu, supaya
   ada jeda waktu di antara keduanya tetap meninggalkan nilai yang benar
   kalau koneksi putus tepat di celah itu. `PresenceStatus`
   (`lib/data/models/presence_status.dart`) mem-parsing node mentahnya;
   `watchPresence`/`presenceProvider` (family, dikunci per uid) sudah ada
   untuk membaca status pemain lain, walau belum dipanggil dari mana pun
   — sama seperti `kanaKeyboardInputProvider`, infrastrukturnya disiapkan
   duluan sebelum layar yang membutuhkannya.
   Berkas aturannya, `database.rules.json` (baru, terpisah dari
   `firestore.rules`), mengikuti skema yang sudah dikunci: siapa saja
   yang sudah login boleh membaca node presence siapa pun, tapi cuma
   pemilik uid yang boleh menulis miliknya sendiri.

   **Langkah Console yang tadinya jadi penghalang sudah selesai
   dilakukan (2026-08-13)**: instans Realtime Database dibuat lewat
   Firebase Console (region `asia-southeast1`/Singapore, mode "locked"),
   `database.rules.json` di-paste ke tab Rules lalu di-publish, dan URL
   database-nya (`https://teisou-kana-master-default-rtdb.asia-southeast1.firebasedatabase.app`)
   ditambahkan sebagai `databaseURL` ke kedua blok `FirebaseOptions`
   (Android dan iOS) di `firebase_options.dart` — nilai ini **bukan
   karangan**, dicatat langsung dari Console setelah database-nya benar-
   benar ada, sesuai kehati-hatian yang sama dengan gap Firebase iOS di
   `CLAUDE.md` (jangan karang, tunggu nilai sungguhan). Setiap panggilan
   `PresenceService` tetap dibungkus try/catch supaya gagal diam-diam
   kalau suatu saat database-nya bermasalah, bukan cuma sampai langkah
   ini selesai — pola defensifnya tetap dipertahankan, bukan dilepas
   begitu database-nya sudah ada.

   **Diverifikasi hidup sungguhan di device fisik**: build debug baru
   dipasang, aplikasi dibuka fresh (force-stop lalu launch ulang), dan
   node `presence/{uid}` muncul di tab Data Firebase Console dengan
   `state: "online"` dan `lastChanged` terisi angka timestamp asli —
   bukan cuma "kode-nya tidak error", tapi tulisannya benar-benar sampai
   ke server. Sempat perlu refresh manual halaman Console sekali (listener
   real-time-nya tidak langsung menampilkan tanpa reload) sebelum
   terlihat — kalau ini dicek lagi nanti dan sempat terlihat kosong,
   coba refresh dulu sebelum menyimpulkan ada yang gagal.

   `flutter analyze` bersih, 362 test hijau (7 test baru untuk
   `PresenceStatus.fromSnapshotValue` di
   `test/presence_status_test.dart` — `PresenceService` sendiri tidak
   diuji unit, mengikuti pola yang sudah ada di aplikasi ini bahwa kelas
   servis yang bergantung pada koneksi Firebase sungguhan tidak
   diuji-unit, cuma logika murni di sekitarnya yang diuji). Paket
   `firebase_database` ditambahkan ke `pubspec.yaml`, `flutter build
   apk --debug` dicoba lagi setelah penambahan ini untuk memastikan
   tidak ada masalah Gradle/native — sukses.

**Tahap 2 — inti pertandingan**
4. ✅ **Selesai (kode) — ⚠️ rules Firestore belum di-deploy** —
   `battleMatches` + aturan Firestore. `TurnOrderEntry`
   (`lib/data/models/turn_order_entry.dart`) adalah satu kartu dalam
   `turnOrder`; `buildTurnOrder`
   (`lib/core/services/battle_turn_order_builder.dart`) adalah fungsi
   murni yang membangun 20 ronde itu sekali di awal — deck tiap pemain
   diacak, 10 pertama dari hasil acak dipakai (5 ke babak utama ronde
   0-9, 5 ke babak tambahan ronde 10-19), 10 sisanya sengaja tidak
   terpakai (sesuai "setengah deck tidak terpakai tiap match"), giliran
   bergantian ketat mulai dari `firstUid` (siapa duluan diputuskan lewat
   `Random` di pemanggil, bukan di fungsi ini).

   **Satu titik ambigu di rumusan yang perlu dicatat, bukan ditebak diam-
   diam**: kalimat "10 pertama dipakai untuk ronde 0-9 milik pemain itu,
   10 sisanya mengisi ronde 10-19" — dibaca sepersis mungkin — sebenarnya
   tidak bisa benar bersamaan dengan "giliran bergantian" (karena tiap
   pemain cuma memiliki 5 dari 10 slot di ronde 0-9, bukan 10). Kode ini
   memilih pembacaan yang membuat SEMUA angka lain yang sudah dikunci
   tetap konsisten sekaligus (deck 20, maksimal 10 kartu/pemain, separuh
   deck tidak terpakai, ronde 0-9/10-19, giliran bergantian) — dijelaskan
   lengkap di komentar `buildTurnOrder` sendiri. Kalau ternyata maksud
   aslinya beda, cuma fungsi ini yang perlu diubah.

   `cardTimeLimit` (`lib/core/services/battle_timer.dart`) mengunci angka
   timer per ronde global (30 detik untuk ronde 0-9, menyusut 2 detik
   tiap kartu untuk ronde 10-19, lantai 10 detik).

   `BattleMatch`/`BattleAnswer` (`lib/data/models/`) mem-parsing skema
   `battleMatches/{matchId}` dan `.../answers/{round}` persis seperti
   yang sudah dikunci — `officialScore`/`result` sengaja **read-only
   dari sisi klien**, tidak ada satu pun method yang menulisnya (itu
   jatah Cloud Function, butir 7). `BattleRepository`
   (`lib/data/repositories/battle_repository.dart`) menyediakan
   `createMatch` (lempar koin, panggil `buildTurnOrder`, tulis dokumen),
   `watchMatch`/`getMatch`, `submitAnswer` (transaksi: tulis jawaban +
   majukan `currentRound`/`turnStartedAt` dalam satu tulisan, dijaga
   supaya jawaban yang telat karena ronde sudah dimajukan lawat lain
   diam-diam dibuang, bukan memajukan giliran dua kali), dan
   `setClientResult` untuk layar "selesai" instan nanti.

   **Sengaja belum dikerjakan di sini** (menunggu butir 5/7): pemilihan
   20 kartu sungguhan per pemain (repository menerima deck yang sudah
   dipilih, bukan memutuskan isinya sendiri — `cardId` tetap string
   opak sesuai cara rumusan menyebutnya, belum pernah dipatok ke sumber
   konkret), dan jalur "lawan menutup aplikasi di tengah pertandingan"
   (butuh timer UI layar pertandingan yang belum ada).

   `firestore.rules` dapat blok baru untuk `battleMatches` + subkoleksi
   `answers`: hanya dua pemain di match itu yang boleh baca/tulis,
   `officialScore`/`result`/`status`/`players`/`turnOrder` dikunci tidak
   bisa diubah klien sama sekali (Cloud Function pakai Admin SDK yang
   melewati rules ini sepenuhnya, jadi tidak perlu pengecualian khusus),
   dan satu jawaban di `answers/{round}` cuma bisa dibuat sekali oleh
   pemilik jawabannya sendiri.

   ✅ **Update**: sudah di-deploy ke Firestore sungguhan (di-paste manual
   ke tab Rules Console, sama seperti `database.rules.json` untuk
   presence — CLI Firebase di lingkungan ini tetap macet di skrip
   sambutannya, masalah lama yang sudah dicatat di `CLAUDE.md`).

   `flutter analyze` bersih, 382 test hijau (20 test baru — 8 untuk
   `buildTurnOrder`, 4 untuk `cardTimeLimit`, 8 untuk model
   `BattleMatch`/`BattleAnswer`/`TurnOrderEntry`), `flutter build apk
   --debug` sukses.
5. ✅ **Selesai (kode) — ⚠️ satu perubahan rules lagi belum di-deploy** —
   Layar pertandingan. `BattleScreen`
   (`lib/features/battle/battle_screen.dart`) merender satu dokumen
   `battleMatches/{matchId}` dan benar-benar bisa dimainkan: kartu
   berjalan tampil, penjawab mengetik (romaji lewat keyboard bawaan HP
   untuk kartu kana, hiragana lewat `KanaKeyboard` — butir 1 — untuk
   kartu kanji), timer mundur per kartu (`cardTimeLimit`, butir 4),
   skor berjalan dihitung lokal, dan begitu babak utama (ronde 0-9)
   selesai dengan skor beda — atau ronde 19 masih imbang — layar
   "selesai" langsung tampil dengan `clientResult` (tebakan klien,
   bukan `officialScore`/`result` yang masih menunggu Cloud Function di
   butir 7).

   **Dua potongan logika murni baru, keduanya diuji terhadap dataset
   sungguhan/kasus buatan**: `buildDeckIds`/`resolveCard`
   (`lib/core/services/battle_deck_builder.dart`) menutup celah yang
   sengaja ditinggalkan di butir 4 — "`cardId` cuma string opak, belum
   dipatok ke sumber sungguhan". Sekarang dipatok: Bronze menarik
   hiragana dasar, Silver menarik katakana + bentuk gabungan hiragana
   (tenten/maru/youon), tiga tingkat kanji menarik satu contoh kata per
   kartu (bukan kanji tunggal, sesuai keputusan yang sudah dikunci),
   id-nya `"{kanjiId}|{word}"` — pola kunci yang sama persis yang sudah
   dipakai rollout terjemahan contoh-kata kanji sebelumnya, dipakai
   ulang bukan diciptakan baru. `buildDeckIds` diuji terhadap
   `KanaRepository`/`KanjiRepository` sungguhan (bukan data buatan) —
   membuktikan setiap tingkat benar-benar punya cukup kartu asli, bukan
   cuma lolos di teori. `battle_score_tally.dart` (`tallyScores`/
   `clientConclusion`) mem-fungsi-murnikan aturan "Aturan kesimpulannya"
   dari butir 4 supaya bisa diuji tanpa Firestore sama sekali.

   **Bug desain nyata ditemukan dan diperbaiki saat menyusun jalur
   timeout**: aturan `answers/{round}` dari butir 4 mensyaratkan
   `byUid == request.auth.uid` (cuma pemilik jawaban yang boleh
   menulis) — tapi rumusan "Kalau lawan menutup aplikasi di tengah
   pertandingan" secara eksplisit bilang pemain yang MENUNGGU (bukan
   yang menjawab) yang menulis transaksi begitu waktu habis. Dua aturan
   ini bertabrakan — kalau tetap dipakai, `forfeitRoundOnTimeout` yang
   baru dibangun akan selalu ditolak Firestore. Diperbaiki dengan
   melonggarkan aturan `answers/{round}` jadi "siapa saja dari dua
   pemain di match itu boleh menulis" — aman karena `byUid`/`text` di
   situ cuma kenyamanan tampilan jalur cepat, bukan sumber kebenaran;
   Cloud Function (butir 7) harus menurunkan sendiri siapa yang
   seharusnya menjawab dari `turnOrder[round]`, tidak boleh percaya
   field `byUid` begitu saja. ✅ **Perbaikan `byUid` ini sudah di-deploy
   juga** (2026-08-13) — kedua perubahan ke blok `battleMatches` di
   `firestore.rules` (versi awal butir 4, lalu pelonggaran `byUid` ini)
   sudah live di Firestore sungguhan.

   `BattleRepository` dapat dua method baru: `forfeitRoundOnTimeout`
   (dipanggil HANYA oleh pemain yang menunggu/pemilik deck ronde itu,
   dicek dari `TurnOrderEntry.deckOwnerUid`) dan `watchAllAnswers`
   (stream seluruh jawaban yang sudah masuk, dipakai untuk menghitung
   skor berjalan tanpa mengawasi tiap ronde satu-satu).

   **Sengaja disederhanakan dari rancangan penuh di satu hal**: pemain
   yang menunggu tidak dapat animasi sekilas "lawan menjawab: benar!"
   persis saat jawabannya masuk — menampilkan itu dengan benar butuh
   melacak ronde yang sudah keburu digantikan ronde berikutnya (tulisan
   yang sama yang mencatat jawaban juga langsung memajukan
   `currentRound`), kompleksitas waktu yang nyata untuk versi pertama.
   Sebagai gantinya setiap ronde yang selesai langsung masuk ke skor
   berjalan di header, jadi hasilnya tetap kelihatan, cuma bukan
   sebagai momen beranimasi.

   **`BattleTestStartScreen`** (`lib/features/battle/battle_test_start_screen.dart`)
   adalah alat uji manual untuk butir 6 di bawah — bukan alur produk
   sungguhan, sengaja **tidak** dipasang ke navigasi asli mana pun
   (belum ada sistem undangan/matchmaking, Tahap 3, jadi ini satu-
   satunya cara memasukkan dua akun sungguhan ke satu dokumen
   `battleMatches` sekarang: ketik uid akun kedua secara manual). Kedua
   deck dibangun dari tingkat akun yang sedang login saat itu untuk
   kedua pemain — satu pengecekan lebih sedikit untuk uji jalur cepat
   itu sendiri.

   `flutter analyze` bersih, 400 test hijau (18 test baru — 10 untuk
   `buildDeckIds`/`resolveCard` terhadap dataset kana/kanji sungguhan,
   8 untuk `tallyScores`/`clientConclusion`), `flutter build apk
   --debug` sukses. **Belum ada uji dua-device sungguhan** — itu
   pekerjaan butir 6 di bawah, dan baru bisa dilakukan kalau ada dua
   akun/device untuk saling menguji.
6. ✅ **Selesai — diuji sungguhan di dua device fisik/emulator berbeda**
   (2026-08-13). Device fisik (Moto G52J) + emulator Pixel 8 lokal,
   masing-masing login dengan akun anonim berbeda (uid diambil dari
   berkas `shared_prefs` FirebaseAuth via `adb shell run-as`, bukan
   dikarang). `BattleTestStartScreen` dipasang sementara ke app bar Home
   lewat satu tombol debug (⚔️) untuk mencapainya, lalu **dilepas
   kembali setelah pengujian selesai** — sesuai catatan sendiri di
   widget itu bahwa entry point-nya harus sementara. Fitur "Gabung ke
   Match" (masukkan `matchId` yang sudah dibuat perangkat lain) juga
   ditambahkan ke `BattleTestStartScreen` pada saat ini — celah nyata
   yang ketahuan begitu benar-benar dicoba: alat ujinya tadinya cuma
   bisa MEMBUAT match, tidak ada cara bagi perangkat kedua untuk
   BERGABUNG ke match yang sama, padahal keduanya jelas dibutuhkan
   untuk uji dua-device.

   **Hasil pengujian sungguhan lewat Firestore langsung** (bukan
   emulator lokal/fixture): match dibuat dari device fisik, device
   kedua bergabung lewat matchId yang sama, dan dari titik itu kedua
   layar `BattleScreen` yang berjalan independen di dua perangkat
   berbeda saling menyinkronkan giliran secara real-time — device yang
   sedang menunggu benar-benar melihat "Menunggu jawaban lawan...",
   device yang menjawab benar-benar melihat kotak jawaban, dan giliran
   berpindah dalam hitungan detik setelah salah satu sisi menulis.
   Jawaban romaji manual ("na" untuk な) berhasil dikirim dan giliran
   maju sesuai desain. **Mekanisme timeout-forfeit juga terverifikasi
   secara alami, bukan sengaja diskenariokan**: begitu device yang
   sempat berpindah layar (untuk membaca `matchId`) kembali ke
   `BattleScreen`, `_ensureTimerFor` langsung mendeteksi jatah waktu
   ronde itu sudah lewat dan otomatis memanggil
   `forfeitRoundOnTimeout` — persis perilaku yang dirancang di butir 5,
   dan pengecekan "cuma pemilik deck ronde itu yang boleh memaksa maju"
   terbukti benar (device yang bukan pemilik deck ronde itu tidak
   pernah menulis apa pun). Pertandingan lalu dibiarkan berjalan
   sendiri lewat rentetan timeout otomatis di kedua sisi (masing-masing
   perangkat memproses ronde miliknya sendiri secara independen) sampai
   ronde 19 — **dan kedua device sampai pada kesimpulan yang PERSIS
   SAMA secara independen**: "Seri!" (skor 0-0 di kedua sisi), layar
   "selesai" tampil benar dengan tombol "Selesai" di keduanya. Ini
   membuktikan `clientConclusion` (fungsi murni, deterministik) memang
   menghasilkan jawaban yang identik dari data `answers` yang sama,
   walau dihitung sepenuhnya independen di dua perangkat berbeda tanpa
   koordinasi langsung — persis prinsip "jalur cepat, tanpa Cloud
   Function sama sekali" yang jadi tujuan butir ini.

   **Satu hal yang TIDAK sempat dikonfirmasi secara bersih**: jawaban
   BENAR yang menambah skor — dua percobaan manual keburu kehabisan
   waktu ronde (karena jeda antar perintah ADB), jadi skor akhir 0-0
   berasal dari rentetan timeout, bukan jawaban benar yang tercatat.
   Jalur kodenya (`resolveCard` → bandingkan romaji → `tallyScores`)
   sudah diuji unit secara terpisah dan meyakinkan, tapi belum ada
   konfirmasi visual "skor bertambah setelah jawaban benar" di layar
   sungguhan — layak dicoba lagi kalau ada kesempatan menjawab lebih
   cepat dari batas waktu 30 detik.
7. ✅ **Selesai — dibangun, diuji, dan sudah di-deploy ke produksi**
   (2026-08-13). `functions/battle_scoring.js` menambah trigger baru
   `onBattleAnswerCreated`, terpicu tiap kali dokumen
   `battleMatches/{matchId}/answers/{round}` baru dibuat, dan menulis
   `officialScore`/`result`/`status` — satu-satunya penulis ketiga field
   itu, sesuai yang sudah dikunci di `firestore.rules`.

   **`RomajiConverter` di-porting ke JavaScript**, bukan dibangun ulang
   dari nol — logikanya (peta karakter→romaji dari `kana_data.json`,
   pencarian dua-karakter untuk youon dicoba duluan di tiap posisi,
   sokuon mengulang huruf pertama dari mora berikutnya) disalin
   sepersis mungkin dari `lib/core/services/romaji_converter.dart`,
   supaya kedua sisi tidak diam-diam beda perilaku. Sumber datanya:
   `functions/data/kana_data.json` (salinan utuh, ~70KB) dan
   `functions/data/kanji_word_readings.json` (peta ramping
   `"{kanjiId}|{word}": "reading"`, 7.274 entri — bukan salinan utuh
   `kanji_data.json` yang 3.3MB, karena penilaian cuma butuh bacaannya
   saja). Keduanya dihasilkan dari sumber Flutter yang sama lewat
   `scripts/generate_functions_battle_data.py` — **harus dijalankan
   ulang** setiap kali `kana_data.json`/`kanji_data.json` berubah,
   sama seperti pola "regenerate lalu re-apply" yang sudah berkali-kali
   didokumentasikan di `CLAUDE.md` untuk dataset lain.

   **Dua celah nyata di rumusan sendiri ditemukan dan diperbaiki saat
   membangun ini, bukan sekadar detail implementasi**:
   1. Rumusan lama bilang cek kelengkapan pemrosesan ronde dengan
      "apakah `officialScore.uidA + officialScore.uidB` sama dengan
      `round + 1`?" — ternyata **tidak valid dua kali lipat**: menjumlah
      SKOR meleset setiap kali ada jawaban SALAH yang sudah diproses
      (jawaban salah menyumbang 0 ke skor, tidak bisa dibedakan dari
      "belum diproses sama sekali"), dan bahkan sekadar menghitung
      JUMLAH ronde yang sudah diproses pun bisa kebetulan cocok dengan
      `round + 1` padahal ada ronde LEBIH AWAL yang terlewat (ronde
      lain yang lebih belakangan kebetulan sudah selesai duluan dan
      menggenapi hitungannya). Diperbaiki dengan `scoredRounds`, field
      baru (map `{"0": true, "1": true, ...}`) yang jadi penanda per-
      ronde SEKALIGUS pengaman idempoten (Cloud Function generasi ke-2
      bisa terpicu lebih dari sekali untuk event yang sama), dan
      pengecekan kelengkapannya benar-benar menelusuri ronde 0 sampai
      `round` satu per satu memastikan semuanya bertanda, bukan
      percaya satu angka agregat.
   2. `scoredRounds` sendiri butuh dikunci di `firestore.rules` seperti
      `officialScore`/`result`/`status`/`players`/`turnOrder` — kalau
      tidak, klien bisa mengubahnya dan mengacaukan pengecekan
      kelengkapan Cloud Function-nya sendiri.

   `BattleMatch` (Dart) dapat field baru `scoredRounds` (read-only dari
   sisi klien, murni untuk pembukuan internal Cloud Function — tidak
   ada kode Flutter yang membacanya untuk keperluan apa pun) dan
   `toCreateMap()` menginisialisasinya kosong.

   **Diuji dua sisi**: `functions/battle_scoring.test.js` (10 test,
   `node --test` — bawaan Node, tidak nambah dependency; ini test JS
   pertama yang pernah ada di folder `functions/`) meniru persis
   kasus-kasus `test/romaji_converter_test.dart` supaya kedua porting
   tetap sejalan, plus resolusi `cardId` kana dan kanji. `flutter
   analyze` bersih, 401 test Dart hijau (1 baru untuk parsing
   `scoredRounds`).

   **Sudah benar-benar di-deploy ke `teisou-kana-master`** (dikonfirmasi
   lewat `firebase functions:list` — `onBattleAnswerCreated` tampil di
   `asia-southeast1`, `nodejs22`), plus `firestore.rules` versi terbaru
   (dengan kunci `scoredRounds`) ikut ter-deploy di sesi yang sama.

   **Penemuan penting yang tidak berkaitan langsung tapi berharga**:
   CLI Firebase yang selama ini didokumentasikan macet
   (`CLAUDE.md`: "Firebase CLI di lingkungan ini broken — crashes on
   its own first-run welcome script") ternyata cuma masalah **binary
   bawaan** di `/c/flutter/bin/firebase` (skrip sambutannya sendiri
   error parse JSON). `npx firebase-tools@latest` — mengunduh CLI
   segar lewat npm, bukan binary snapshot itu — bekerja normal dan
   **sudah terautentikasi** ke akun yang sama (kemungkinan dari sesi
   sebelumnya). Deploy pertama sempat gagal sekali dengan timeout 10
   detik yang sama seperti yang pernah dicatat di `functions/index.js`
   ("User code failed to load"), tapi percobaan kedua berhasil normal —
   sepertinya gangguan sesaat, bukan masalah struktural pada kodenya
   (pola `initializeApp()` eager + `getFirestore()`/`getMessaging()`
   lazy yang sudah ada di `index.js` tetap dipertahankan di
   `battle_scoring.js`). **Ini artinya deploy Cloud Functions dan
   Firestore/RTDB rules ke depan bisa lewat `npx firebase-tools`
   langsung, tidak perlu lagi paste manual ke Console** — perbaikan
   yang berlaku untuk seluruh proyek, bukan cuma fitur ini.

   Satu hal kecil yang sengaja tidak diurus: peringatan "No cleanup
   policy detected for repositories in asia-southeast1" dari Artifact
   Registry (gambar container lama bisa menumpuk dan sedikit menambah
   biaya bulanan) — bisa diberesi lewat `firebase
   functions:artifacts:setpolicy` kapan saja, tidak mendesak dan tidak
   menghalangi fungsi ini berjalan.

**Tahap 3 — lawan, dari yang paling mudah diuji sendirian ke yang
paling rumit**
8. ✅ **Selesai — dibangun dan diuji, belum di-deploy ke produksi**
   (2026-08-13). `functions/battle_bot.js` (baru) menambah trigger
   kedua, `onBattleMatchWritten`, terpicu tiap kali dokumen
   `battleMatches/{matchId}` ditulis. Bentuknya persis seperti yang
   dikonfirmasi di bagian "Bentuk konkret bot" di bawah — pertandingan
   bot adalah `battleMatches` biasa, satu slot `players` diisi sentinel
   `"BOT"` (`battleBotUid` di Dart/`BOT_UID` di JS, tidak pernah bisa
   bentrok dengan uid Firebase Auth asli yang selalu 28 karakter acak)
   — begitu giliran menjawab jatuh ke bot, trigger ini langsung menulis
   jawaban ke `answers/{round}`, lalu `onBattleAnswerCreated` (butir 7)
   menilainya lewat **satu jalur penilaian yang sama** dengan lawan
   manusia — sesuai alasan yang sudah dikunci: "supaya bintang/poin/EXP
   dari lawan bot lewat SATU sumber kebenaran yang sama dengan lawan
   manusia".

   **Keputusan/temuan nyata selama membangun, bukan sekadar detail**:
   1. **Kurva kesulitan** dikunci per `cardTierContent` (lihat tabel
      "Kurva kesulitan" di bawah) — `BattleMatch` dapat field baru
      `cardTierContent` (dikirim `BattleRepository.createMatch` saat
      pertandingan dibuat, dikunci di `firestore.rules` seperti
      `officialScore`/`scoredRounds`), supaya bot tidak perlu
      menurunkan ulang tingkat kesulitan dari isi `turnOrder` di tiap
      giliran. `CardTierContentX.key`/`fromKey`
      (`card_game_rank.dart`) jadi jembatan string antara enum Dart dan
      key JS di `battle_bot.js`'s `DIFFICULTY` map — satu sumber
      penamaan, tidak ada tabel terjemahan terpisah.
   2. **`revealAt` sengaja kosmetik, bukan pengaman keamanan** — jawaban
      bot (benar/salah + teksnya) diputuskan dan ditulis SAAT ITU JUGA
      begitu giliran bot tiba; `officialScore` sudah final di titik
      itu. `revealAt` (waktu tulis + jeda acak sesuai rentang tingkat)
      cuma penanda opsional buat klien "kapan boleh menampilkan
      jawaban bot", supaya terasa seperti bot sedang berpikir. Klien
      Flutter **belum** memakai `revealAt` (masih menampilkan jawaban
      bot secepat data sampai) — sengaja ditunda, bukan lupa, karena
      menambah UI penundaan buatan bukan bagian dari "verifikasi
      penilaian bot benar", yang jadi fokus utama butir ini.
   3. **Sintesis romaji→hiragana untuk jawaban kartu kanji bot** adalah
      bagian paling rumit. Aturan baku proyek ini adalah "jangan pernah
      bangun konversi romaji→kana otomatis, ambigu secara linguistik"
      — tapi di sini dipakai sengaja dengan alasan yang berbeda: hasil
      sintesis bot **tidak perlu cocok dengan ejaan kamus yang "benar"
      secara linguistik**, cuma perlu **round-trip lewat fungsi
      `toRomaji` maju yang sama** yang sudah dipakai penilai (butir 7)
      — jadi kekhawatiran ambiguitas biasa (じ vs ぢ, お vs を) tidak
      berlaku, karena arah pembandingnya hanya satu fungsi tunggal,
      bukan "bahasa Jepang yang benar" secara umum. Dikonfirmasi lewat
      skrip Python: **tidak ada dua entri hiragana di `kana_data.json`
      yang berbagi string romaji sama**, jadi tabel pencarian
      terbaliknya tidak ambigu secara konstruksi.

      Diverifikasi bukan cuma dengan beberapa contoh tangan, tapi
      **seluruh 7.274 bacaan nyata** di
      `functions/data/kanji_word_readings.json` lewat skrip
      round-trip penuh (`hiraganaForRomaji(romaji)` lalu `toRomaji()`
      hasilnya harus kembali sama) — proses ini sendiri menemukan dan
      memperbaiki beberapa bug nyata secara berurutan:
      - Set konsonan pemicu gemination (っ) awalnya lupa memasukkan
        `'c'`, jadi "icchi" gagal terparse — set dibangun ulang dari
        pengecekan nyata semua huruf konsonan awal romaji hiragana di
        dataset, bukan tebakan.
      - 317 kegagalan sisa ternyata semuanya apostrof/strip/spasi yang
        dipakai Hepburn sebagai penanda batas suku kata ("ren'ai",
        "ken-eki", "keiken ga asai") — diperbaiki dengan memecah input
        di tiga tanda itu dulu, memparsing tiap segmen sendiri-sendiri,
        baru digabung.
      - Sempat dicoba menambah kasus khusus "tch" sebelum ち/ちゃ/ちゅ/
        ちょ (ejaan gemination Hepburn yang lebih baku untuk kata
        seperti "botchan") — **tapi ini dibatalkan lagi**, karena
        `toRomaji` (fungsi maju yang sama, hasil porting dari
        `romaji_converter.dart`) selalu meng-encode っ+ちゃ sebagai
        "ccha" (menggandakan huruf pertama dari romaji mora
        berikutnya, "cha"), tidak pernah "tcha" — menambah "tch" di
        sisi pembalik justru MERUSAK konsistensi-diri yang jadi syarat
        sebenarnya, walau lebih "benar" secara linguistik umum.
        Dibiarkan `null` untuk 2 entri ini ("botchan", "setchuu") —
        `buildBotAnswer` sudah menangani `null` dengan baik (jatuh ke
        jawaban string kosong, dinilai salah, tidak pernah crash).

      **Temuan sampingan yang berharga**: ketidakcocokan "tch" vs
      "cch" ini sebenarnya membuka celah nyata yang **sudah ada
      sebelum bot dibangun**, di `battle_scoring.js` yang sudah
      di-deploy (butir 7) — kalau ada PEMAIN MANUSIA yang mengetik
      hiragana yang benar-benar tepat untuk kata seperti 坊っちゃん
      (ぼっちゃん), `toRomaji`-nya scorer akan menghasilkan "bocchan",
      bukan "botchan" yang tersimpan sebagai `correctRomaji` — pemain
      itu akan dinilai SALAH walau jawabannya benar. Ini bukan bug
      yang diperkenalkan oleh bot, dan cuma memengaruhi 2 dari 7.274
      bacaan (0,03%) — dicatat di sini sebagai celah data/penilaian
      yang sudah ada, berprioritas rendah karena sangat jarang, bukan
      sesuatu yang diperbaiki diam-diam di sesi ini. Perbaikan yang
      tepat (mengoreksi ejaan `correctRomaji` di dataset supaya cocok
      dengan yang benar-benar dihitung `toRomaji`, bukan mengubah kode
      penilai) adalah pekerjaan koreksi data terpisah, di luar cakupan
      "bangun bot".

      4 kegagalan `null` lain yang tersisa (total jadi 6) adalah kasus
      pinggiran nyata, bukan bug: "kouhu" (kemungkinan selisih ejaan
      "hu" vs "fu" di dataset sumber), "Wang" (nama keluarga pinyin
      Tionghoa, bukan Hepburn Jepang sama sekali), dan dua "Yō .../"
      (mengandung makron non-ASCII, tidak ada di tabel romaji manapun)
      — semuanya kata benda asing/pinjaman langka, bukan kosakata
      umum, dan `buildBotAnswer` menangani semuanya dengan aman.
   4. **Pengecoh jawaban salah** meniru pola (bukan kode) yang sudah
      ada di `kanji_combo_repository.dart` — persis seperti yang
      disarankan rumusan ini sendiri: satu mora dibalik dakuten/
      handakuten-nya (か↔が dst.), atau kalau tidak ada pasangan
      dakuten, dua mora bertetangga ditukar posisinya. `mutateHiragana`
      dijamin tidak pernah mengembalikan input yang persis sama.

   **Diuji dua sisi lagi**: `functions/battle_bot.test.js` (baru, 16
   test, `node --test`) — mencakup round-trip penuh dataset (dengan 6
   pengecualian yang didaftar eksplisit, jadi kalau ada bacaan BARU
   yang gagal round-trip, test-nya gagal keras, bukan diam-diam
   ditambahkan ke daftar pengecualian), gemination, youon, ketiga
   pemisah batas suku kata, `mutateHiragana` tidak pernah no-op,
   `difficultyFor` mengetat sesuai tingkat, `buildBotAnswer` null untuk
   `cardId` yang tidak ada, rasio benar/salah kasar-kasar cocok
   `correctProbability` lewat banyak percobaan, `revealAt` selalu di
   rentang tingkatnya, dan satu kartu kanji nyata (学生, "gakusei")
   dipaksa benar untuk memastikan pipa sintesis-lalu-nilai bekerja
   ujung ke ujung. `flutter analyze` bersih, seluruh test Dart hijau
   (405 test — 2 baru: `CardTierContentX.key`/`fromKey`, dan
   `BattleMatch.cardTierContent` parse/serialize).

   **`BattleTestStartScreen`** (alat uji manual yang sama dari butir 6)
   dapat tombol kedua "Lawan Bot" di sebelah tombol buat-pertandingan
   biasa — memanggil `createMatch(opponentUid: battleBotUid)`, jalur
   yang sama persis dengan lawan manusia, cuma uid lawannya beda.

   **Sudah di-deploy ke produksi** (2026-08-13, sesi yang sama):
   `onBattleMatchWritten` tampil di `firebase functions:list`
   (`asia-southeast1`, `nodejs22`, generasi ke-2, memicu dari
   `google.cloud.firestore.document.v1.written` — beda dari
   `onBattleAnswerCreated` yang memicu dari `...created`, karena bot
   perlu bereaksi ke setiap PERUBAHAN dokumen `battleMatches`, bukan
   cuma pembuatan dokumen `answers` baru), dan `firestore.rules`
   dengan kunci `cardTierContent` sudah ter-release.

   **Sudah diverifikasi ujung-ke-ujung di perangkat fisik sungguhan**
   (Moto G52J, sesi yang sama): `main.dart`'s `_TutorialGate` diubah
   sementara supaya langsung membuka `BattleTestStartScreen` (bukan
   `HomeScreen`), APK debug dipasang, tombol "Lawan Bot" ditekan lewat
   `adb shell input tap` — pertandingan sungguhan langsung terbentuk
   di `teisou-kana-master` (uid lawan `"BOT"`). Sempat terhambat
   sebentar oleh koneksi WiFi hotspot perangkat yang putus-nyambung
   (`logcat` menunjukkan `UnknownHostException` untuk
   `firestore.googleapis.com` — dikonfirmasi lewat `dumpsys
   connectivity`/`wifi`, bukan masalah kode), tapi begitu koneksi
   pulih (dikonfirmasi lewat `ping 8.8.8.8` berhasil), pertandingan
   langsung terbentuk normal. Dimainkan sungguhan lewat keyboard fisik
   ADB (`input text "ne"` dst., bukan `KanaKeyboard` bawaan — kartu
   tier Bronze/hiragana dijawab lewat romaji apa pun caranya, jadi ini
   representatif) — tiap kali satu kartu dijawab manusia, kartu
   berikutnya (giliran bot) langsung terlewati OTOMATIS tanpa input
   apa pun dari saya, dan skor "Lawan" bertambah tiap kali — bukti
   langsung bahwa `onBattleMatchWritten` bereaksi, menulis jawaban
   bot, dan `onBattleAnswerCreated` (butir 7) menilainya lewat jalur
   yang sama persis dengan jawaban manusia. Progresi skor nyata yang
   terekam: 0-0 → 1-0 → 2-1 → 3-2, dan pertandingan berakhir wajar di
   kondisi selesai 10 kartu (bukan 20 — koreksi ke "Kondisi selesai"
   di tabel keputusan di bawah tetap benar) dengan layar **"Menang!
   Kamu: 3, Lawan: 2"** — mengonfirmasi kesimpulan pertandingan juga
   bekerja benar untuk lawan bot, bukan cuma sesi menjawab per-ronde
   saja. Perubahan sementara di `main.dart` dan seluruh file screenshot
   sisa pengujian sudah dikembalikan/dibersihkan (`git checkout --
   lib/main.dart`) sebelum sesi ini ditutup — tidak ada jejak kode uji
   coba yang ikut ter-commit.

   **Butir 8 sekarang benar-benar tuntas** — dibangun, diuji unit dua
   sisi, di-deploy ke produksi, DAN diverifikasi ujung-ke-ujung di
   perangkat fisik dengan hasil yang benar.
9. ✅ **Selesai dibangun, diuji, dan di-deploy — belum diverifikasi di
   perangkat fisik** (2026-08-14). Mengikuti persis rumusan "Cara
   mengundang teman/clan bertanding" di bawah, dengan satu penyimpangan
   sengaja dari kalimat literalnya (lihat poin 2).

   **`BattleInvite`** (`lib/data/models/battle_invite.dart`) di
   `users/{targetUid}/battleInvites/{id}` mengikuti persis bentuk
   `ClanInvite`/`FriendRequest` — `fromUid`/`fromName`/`fromPhotoUrl`/
   `fromAvatarType`/`fromAvatarValue`, `source` ("friend"|"clan"),
   `cardTierContent`, `status` ("pending"|"accepted"|"declined"),
   `createdAt`, `expiresAt` (createdAt + 2 menit, sesuai "Kenapa 2
   menit"). `BattleInviteRepository` (baru) menulis lewat `sendInvite`,
   membaca lewat `watchMyInvites` (di-filter `status == pending` di
   server, dan `expiresAt < sekarang` di sisi klien — self-heal-on-read
   yang sama seperti `backfillGlobalScore`, bukan Cloud Function
   terjadwal, persis seperti yang sudah diputuskan), dan
   `respondToInvite` (tulis status saja).

   **Satu penyimpangan sengaja dari kalimat rumusan, dan kenapa**:
   rumusan bilang "menerima memicu pertandingan mulai". Yang dibangun
   di sini justru **membuat pertandingan LEBIH DULU, sebelum undangan
   ditulis** — `BattleInvite.matchId` menunjuk ke `battleMatches` yang
   sudah ada begitu penantang menekan tombol Tantang, bukan dibuat
   nanti begitu target menerima. Alasannya: tanpa ini, si penantang
   butuh cara mengetahui matchId begitu target menerima — dan tidak ada
   jalur itu di infrastruktur yang sudah ada (`firestore.rules`nya
   `battleInvites` hanya bisa dibaca pemiliknya sendiri, yaitu target,
   bukan penantang; menambah `data` payload ke `AppNotification` untuk
   deep-link juga berarti menyentuh model/Cloud Function/layar
   notifikasi yang sudah ada, jauh di luar cakupan "kirim undangan").
   Dengan membuat match lebih dulu, "menerima" jadi sesederhana
   `BattleScreen(matchId: invite.matchId)` — jalur "Gabung ke Match"
   yang sudah ada dan sudah diverifikasi sejak Tahap 2 butir 6, dipakai
   ulang seutuhnya. **Efek sampingnya justru elegan**: kalau target
   tidak pernah menekan Terima sama sekali (menolak, atau diam saja
   sampai undangan kedaluwarsa), match yang sudah dibuat tadi tetap ada
   dan penantang tetap menunggu di dalamnya — persis skenario "lawan
   menutup aplikasi di tengah pertandingan" yang mekanisme timeout-
   forfeit-nya sudah dibangun dan diverifikasi di Tahap 2. Tidak perlu
   kode baru sama sekali untuk menangani "diundang tapi tidak
   direspons" — giliran target akan habis waktu satu per satu sampai
   penantang menang lewat forfeit, sama seperti lawan yang menghilang.

   **`rankedMatch` (baru) di `BattleMatch`**: rumusan sudah mengunci
   "bintang hanya bergerak di pertandingan publik dan lawan bot" (lihat
   "Kecuali lawan teman dan clan"). Dicek dulu ke kode: logika gerak
   bintang **belum ada sama sekali** di Cloud Function manapun (baik
   untuk publik, bot, maupun apa pun) — jadi keputusan ini saat ini
   masih 100% laten di mana-mana, bukan sesuatu yang butuh diaktifkan
   sekarang. Tetap ditambahkan field `rankedMatch: bool` (default
   `true`, ditulis `false` khusus untuk match dari undangan
   teman/clan) di titik ini karena biayanya kecil (satu field, mengikuti
   pola persis `cardTierContent`) dan menghindari jebakan yang lebih
   mahal nanti: tanpa field ini, sesi masa depan yang membangun gerak
   bintang harus membedakan match hasil antrian publik vs. match hasil
   undangan lewat *collection-group query* ke `battleInvites` semua
   user — query yang mahal dan janggal — padahal cukup satu field
   boolean yang ditulis sekali saat pembuatan. Dikunci sama seperti
   `cardTierContent` di `firestore.rules` (create-only, tidak berubah
   oleh update klien manapun).

   **Isi kartu bebas dipilih penantang** ("Kecuali lawan teman dan
   clan — di sana kartunya bebas dipilih") — `sendBattleChallenge`
   (`lib/features/battle/battle_challenge.dart`) menampilkan
   `_TierPickerSheet`, bottom sheet berisi kelima `CardTierContent`
   (Hiragana Dasar / Katakana + Gabungan / Kanji N5 / Kanji N4–N3 /
   Kanji N2–N1), bukan mengikuti tingkat akun penantang sendiri seperti
   pertandingan publik/bot. Setelah dipilih: dua deck dibangun
   (`buildDeckIds` dipanggil dua kali, sekali per pemain, dari isi yang
   sama tapi acakan berbeda), match dibuat lewat
   `battleRepository.createMatch(..., rankedMatch: false)`, undangan
   ditulis lewat `battleInviteRepository.sendInvite`, notifikasi
   dikirim lewat `notificationRepository.create` (jalur generik yang
   sudah ada, otomatis memicu push asli lewat
   `onUserNotificationCreated` — tidak ada Cloud Function baru yang
   perlu ditulis untuk fitur ini), lalu penantang langsung masuk ke
   `BattleScreen(matchId: ...)`.

   **Tombol "Tantang"** (`ChallengeButton`, juga di
   `battle_challenge.dart`, dipakai ulang oleh dua tempat) muncul di
   dua permukaan yang sudah ada: baris teman di `ChatHubScreen`'s
   daftar chat pribadi (`_PersonalChatRow`, ikon 🎮 di sebelah kanan,
   tidak menggantikan tap-untuk-chat yang sudah ada), dan baris
   anggota di `ClanMembersScreen` (dikecualikan untuk diri sendiri).
   Digerbangi status online sungguhan (`presenceProvider(targetUid)`,
   yang sudah dibangun sejak Tahap 1 butir 3 tapi baru sekarang benar-
   benar dipakai/dikonsumsi) — abu-abu dan tidak bisa ditekan kalau
   target sedang offline, sesuai "Tombol Tantang hanya aktif kalau
   target online".

   **Menerima/menolak**: `_PendingBattleInvitesStrip` (baru, di atas
   `ChatHubScreen`, terlihat di kedua mode clan/personal karena
   undangan bisa datang dari mana saja dan sensitif waktu) mengikuti
   persis bentuk `_PendingInvitesStrip`/`_InviteRow` milik `ClanTab` —
   kolaps jadi tidak ada apa-apa kalau tidak ada undangan pending.
   Menerima langsung `Navigator.push(BattleScreen(matchId:
   invite.matchId))`; penulisan status `accepted` dilakukan
   fire-and-forget (`unawaited`) di baliknya karena kegagalannya cuma
   berarti baris ini nongkrong sedikit lebih lama di daftar pending,
   bukan kegagalan bergabung ke pertandingan yang sesungguhnya.

   **`firestore.rules`**: blok baru `users/{targetUid}/battleInvites/
   {inviteId}` mengikuti pola `friendRequests` persis (siapa saja yang
   login boleh membuat di bawah koleksi milik orang lain, asalkan
   `fromUid` cocok dengan identitasnya) plus satu pengecekan tambahan
   yang tidak dimiliki `clanInvites`/`friendRequests`: `matchHasBothPlayers`
   memverifikasi lewat `get()` bahwa `matchId` yang ditulis benar-benar
   menunjuk ke `battleMatches` yang sudah punya kedua uid (pengirim dan
   target) di `players`-nya — mencegah undangan yang menggantung atau
   menunjuk ke pertandingan orang lain yang tidak terkait. Sudah
   di-deploy ke `teisou-kana-master` (2026-08-14).

   **Diuji**: `test/battle_invite_test.dart` (baru) — round-trip
   `key`/`fromKey` untuk `BattleInviteStatus`/`BattleInviteSource`,
   parsing/serialisasi `BattleInvite` penuh termasuk default saat field
   hilang, `isExpired` untuk kedua arah waktu, dan `cardTierContentLabel`
   menghasilkan label berbeda-dan-tidak-kosong untuk kelima tingkat di
   kedua bahasa. `test/battle_match_test.dart` dapat 2 kasus baru untuk
   `rankedMatch` (parsing default `true`, serialisasi eksplisit
   `false`). `flutter analyze` bersih, 416 test Dart hijau (11 baru).

   **Trade-off yang sengaja dibiarkan terbuka, bukan lupa**:
   - **Kedaluwarsa 2 menit murni kosmetik di sisi tampilan** — sama
     seperti `ClanInvite`/`FriendRequest`, tidak ada penegakan di
     server. `watchMyInvites` cuma menyaring `expiresAt < sekarang`
     setiap kali stream Firestore memancarkan sesuatu (yaitu setiap
     kali ada TULISAN baru ke koleksi itu) — kalau tidak ada tulisan
     baru sama sekali selama lebih dari 2 menit, baris yang sudah
     "kedaluwarsa" secara visual bisa saja masih tampil sampai
     pemicu berikutnya datang. Match yang sudah dibuat tetap berjalan
     dengan timer 30 detiknya sendiri terlepas dari ini, jadi tidak
     ada bug fungsional — cuma baris undangan yang bisa telat hilang
     dari daftar.
   - **Menolak tidak membatalkan match yang sudah dibuat** — match
     tetap ada dan berjalan lewat mekanisme timeout-forfeit yang sudah
     dijelaskan di atas, bukan dihentikan aktif. Ini disengaja (lihat
     alasan di atas), tapi berarti seorang penantang yang menunggu
     lawan yang sudah jelas menolak tetap harus melalui beberapa
     ronde timeout (masing-masing sampai 30 detik) sebelum menang —
     bukan langsung tahu detik itu juga bahwa lawannya menolak.
   - ✅ **SUDAH diverifikasi ujung-ke-ujung di perangkat sungguhan**
     (2026-08-14). Moto G52J (akun "Pak Panjang", ID `2KQ7PLXP`)
     melawan emulator Pixel 8 (akun "Pelajar Kana", ID `TYCTG98L`),
     dua akun Firebase berbeda, keduanya memakai APK debug dari
     `master` saat itu. Seluruh rantainya jalan: cari teman lewat ID
     → kirim permintaan → terima → tombol **Tantang muncul karena
     presence-nya benar-benar terbaca online** → pemilih tingkat
     kartu muncul (bukti nyata keputusan "lawan teman bebas memilih
     isi kartu") → pilih Hiragana Dasar → **baris undangan muncul di
     sisi target** ("Pelajar Kana menantangmu — Hiragana Dasar")
     dengan tombol Terima/Tolak → terima → **keduanya masuk match
     yang sama** → giliran benar-benar bergantian (satu sisi
     menjawab, satu sisi "Menunggu jawaban lawan...") → jawaban
     tercatat → pertandingan selesai dengan hasil yang **konsisten
     di kedua layar**: HP "Kalah, Kamu 0 Lawan 1", emulator
     "Menang!, Kamu 1 Lawan 0".
   - **Temuan nyata dari verifikasi itu: yang diundang masuk
     terlambat, dan langsung tertinggal.** Karena match dibuat saat
     undangan *dikirim* (bukan saat diterima), timernya sudah jalan
     selama undangan menunggu. Di percobaan ini yang diundang baru
     masuk di **kartu 3 dari 20** — dua kartu sudah lewat sebagai
     timeout sebelum ia sempat menyentuh apa pun. Itu konsekuensi
     langsung dari penyimpangan arsitektur yang memang dicatat
     sengaja di atas, tapi baru kelihatan biayanya di sini. Perlu
     diputuskan: mulai timer hanya setelah diterima, atau beri
     tenggang di kartu-kartu awal.
   - ~~**Timernya 20 detik, bukan 30**~~ — **catatan ini salah, dan
     dikoreksi 2026-08-14 setelah dicek langsung ke kode.**
     `cardTimeLimit` (`lib/core/services/battle_timer.dart`) memang
     30 detik untuk kartu 1-10, lalu turun 2 detik per kartu mulai
     kartu 11 — persis aturan hasil rumusan. Angka 20 detik yang
     terlihat saat pengujian adalah **tenggang jatuh-ke-bot di layar
     matchmaking**, hal yang sama sekali berbeda. Tidak ada yang perlu
     disamakan. Jumlah kartunya juga sudah benar (20 kartu total = 10
     per pemain).
   - Belum diuji: jalur **tolak** (memastikan penantang akhirnya
     menang lewat timeout, bukan macet), dan tantangan lewat clan
     (yang diuji baru lewat daftar teman).
10. ✅ **Selesai dibangun, diuji, dan di-deploy — belum diverifikasi di
    perangkat fisik** (2026-08-14). Persis mengikuti rumusan
    "Pemasangan lawan publik" di bawah: antrian RTDB per tingkat,
    Cloud Function terpicu tiap ada yang bergabung, klaim atomik lewat
    transaksi RTDB, 20 detik lalu jatuh ke bot di sisi klien.

    **`functions/battle_matchmaking.js`** (baru) — `onMatchmakingQueueJoined`,
    terpicu `onValueCreated` di `matchmakingQueue/{tier}/{uid}` (bukan
    `onValueWritten`, supaya penghapusan entri lewat klaim milik fungsi
    ini sendiri tidak memicu ulang dirinya sendiri). Isi:
    1. `claimWaitingOpponent` — transaksi RTDB pada NODE INDUK
       `matchmakingQueue/{tier}` (bukan pada entri anak satu per satu),
       supaya klaimnya benar-benar atomik terhadap SEMUA anak sekaligus:
       mencari uid lain (bukan diri sendiri) dengan `joinedAt` paling
       awal, lalu menghapus KEDUA entri dari node itu dalam satu nilai
       transaksi yang sama. Kalau tidak ada yang lain menunggu, transaksi
       cuma mengembalikan nilai yang sama tanpa perubahan (`matchedUid`
       tetap `null`) — pemain yang baru bergabung ini akan menunggu
       sampai pemain BERIKUTNYA yang bergabung memicu pemasangannya,
       persis seperti yang sudah diputuskan.
    2. Begitu klaim berhasil: `createRankedMatch` membangun `battleMatches`
       baru — lempar koin siapa duluan, dua deck dibangun via `buildDeckIds`
       (porting JS dari `battle_deck_builder.dart`), `turnOrder` lewat
       `buildTurnOrder` (porting JS dari `battle_turn_order_builder.dart`,
       algoritma selang-seling yang sama persis) — lalu menulis dokumen
       lewat Admin Firestore SDK, `rankedMatch: true`.
    3. `matchId` yang dihasilkan ditulis ke `matchmakingResults/{uid}`
       untuk KEDUA pemain — sinyal yang ditunggu masing-masing klien
       (lihat poin berikutnya).

    **Kenapa matchId ditulis ke node RTDB terpisah, bukan ke entri
    antrian yang sama**: entri antrian dihapus habis saat diklaim (bukan
    diubah isinya), supaya query `claimWaitingOpponent` berikutnya tidak
    perlu menyaring entri "sudah dipasangkan tapi belum dibersihkan".
    Konsekuensinya, klien yang menunggu tidak bisa mengandalkan
    perubahan pada entrinya sendiri sebagai sinyal — makanya ditambah
    node kecil terpisah `matchmakingResults/{uid}` yang cuma pernah
    ditulis Cloud Function ini (lewat Admin SDK, melewati semua aturan),
    dan klien mendengarkannya lewat `onValue` selagi menunggu.

    **Dua dataset baru dibundel ke `functions/data/`** — deck kanji per
    tingkat butuh tahu level JLPT tiap kanji, sesuatu yang
    `kanji_word_readings.json` (dibangun untuk penilaian, bukan untuk
    membangun deck) tidak menyimpan sama sekali; dicek dulu: 720 dari
    7.274 entri (semua N5/N4) ternyata TIDAK punya akhiran `_n{level}`
    di id-nya (cuma N3-N1 yang punya), jadi menebak level dari id semata
    tidak bisa diandalkan. `scripts/generate_functions_battle_data.py`
    diperluas menghasilkan `kanji_ids_by_level.json` (baru,
    `{n5:[...], n4:[...], n3:[...], n2:[...], n1:[...]}`, cardId penuh
    per entri) langsung dari `jlptLevel` kanji aslinya, terpisah dari
    `kanji_word_readings.json` yang sudah ada supaya `battle_scoring.js`
    (satu-satunya pemakai file itu) tidak perlu disentuh. Harus
    dijalankan ulang bersamaan dengan file lain di folder ini setiap kali
    `kanji_data.json` beregenerasi — sama seperti disiplin re-run yang
    sudah didokumentasikan berkali-kali di `CLAUDE.md` untuk dataset lain.

    **Skema `MatchmakingRepository` (Dart, baru)**: `joinQueue`/
    `leaveQueue` (tulis/hapus `matchmakingQueue/{tier.key}/{uid}`),
    `watchMatchResult`/`getMatchResult` (baca `matchmakingResults/{uid}`
    secara live/sekali), `clearMatchResult` (bersih-bersih setelah
    dipakai). `BattleMatchmakingScreen` (baru, alat uji manual — status
    sama dengan `BattleTestStartScreen`, lihat catatan di bawah) memakai
    tingkat `CardGameRank` pemain sendiri (tidak bisa dipilih bebas,
    beda dari tantangan teman/clan — sesuai "Isi kartu dikunci rank
    hanya untuk lawan publik"), menulis diri ke antrian, mendengarkan
    `watchMatchResult`, jalan timer 20 detik lokal. Kalau timer habis:
    cek sekali lagi `getMatchResult` (menutup sebagian celah balapan di
    detik terakhir — bukan menutup seluruhnya, lihat trade-off di
    bawah), kalau masih kosong keluar dari antrian dan buat pertandingan
    lawan `battleBotUid` lewat jalur yang identik dengan tombol "Lawan
    Bot" di `BattleTestStartScreen`.

    **`database.rules.json`** dapat dua blok baru — `matchmakingQueue/
    $tier/$uid` dan `matchmakingResults/$uid` — keduanya baca-tulis milik
    sendiri saja (`auth.uid === $uid`), dengan `.validate` memastikan
    bentuknya benar (`joinedAt` angka, `matchId` string). Cloud Function
    (Admin SDK) melewati aturan ini sepenuhnya, jadi tetap bisa
    menghapus entri antrian milik ORANG LAIN saat mengklaim pasangan —
    bukan celah, memang begitu cara kerjanya.

    **Gotcha deploy yang baru ditemukan sesi ini**: percobaan deploy
    pertama gagal — `onValueCreated` dipanggil dengan string path polos
    (sama seperti tiga trigger Firestore lain di folder ini memanggil
    triggernya sendiri), tapi ternyata **trigger RTDB tidak menurunkan
    region dari lokasi instans Realtime Database-nya sendiri** seperti
    yang dilakukan trigger Firestore — defaultnya jatuh ke `us-central1`,
    dan deploy gagal dengan "pattern cannot match any databases in
    region us-central1" karena instans sungguhan ada di
    `asia-southeast1`. Diperbaiki dengan memanggil `onValueCreated`
    memakai objek opsi eksplisit (`{ref, region: "asia-southeast1",
    instance: "teisou-kana-master-default-rtdb"}`) alih-alih string
    polos — berhasil di percobaan kedua,
    `onMatchmakingQueueJoined(asia-southeast1)` tampil di `firebase
    functions:list`. **Terpisah**, `firebase.json` juga belum pernah
    punya target `database` sama sekali (aturan RTDB yang sudah ada dari
    Tahap 1 dipasang manual lewat Console, bukan CLI) — ditambahkan
    sesi ini supaya `deploy --only database` bisa dipakai ke depannya,
    bukan cuma paste manual.

    **Diuji**: `functions/battle_matchmaking.test.js` (baru, 12 test) —
    `poolFor` untuk kelima isi kartu (termasuk gabungan N4+N3/N2+N1
    tanpa duplikat dan fallback ke hiragana untuk kunci tak dikenal),
    `shuffle` sebagai permutasi murni (array asli tidak tersentuh) dan
    hasil deterministik yang benar-benar dihitung tangan untuk sumber
    acak yang dipatok, `buildDeckIds` menghasilkan 20 id unik dari pool
    nyata untuk kelima tingkat, `buildTurnOrder` berselang-seling benar
    dan cuma memakai 10 kartu pertama tiap pemain. Sengaja **tidak**
    menguji `claimWaitingOpponent`/`createRankedMatch`/trigger itu
    sendiri secara unit — ketiganya butuh Firestore + Realtime Database
    sungguhan, sama seperti `battle_bot.js`'s `onBattleMatchWritten`
    sendiri yang juga tidak diuji unit, diverifikasi lewat produksi/
    perangkat fisik sebagai gantinya. `flutter analyze` bersih, 416 test
    Dart hijau (tidak ada test baru di sisi Dart — `MatchmakingRepository`
    murni Firestore/RTDB, mengikuti pola yang sama seperti
    `BattleRepository`/`FriendRepository`/`ClanRepository` yang juga
    tidak diuji unit tersendiri), 38 test JS hijau (12 baru).

    **Sudah di-deploy ke produksi** (2026-08-14): `onMatchmakingQueueJoined`
    tampil di `firebase functions:list`, `database.rules.json` dengan
    dua blok baru sudah dirilis (`teisou-kana-master-default-rtdb`).

    **Trade-off yang sengaja dibiarkan terbuka, bukan lupa**:
    - **Balapan di detik ke-20 tidak tertutup sepenuhnya** — klien
      mengecek `getMatchResult` sekali sebelum menyerah ke bot, tapi
      kalau Cloud Function mengklaim pemain ini TEPAT setelah
      pengecekan itu (sebelum pertandingan lawan bot sempat dibuat),
      pemain ini akan berakhir di DUA pertandingan sekaligus — satu
      lawan bot yang baru dibuat, satu lagi lawan manusia yang
      seharusnya dipasangkan. Peluangnya kecil (jendela balapannya
      cuma milidetik) dan konsekuensinya ringan (pertandingan lawan bot
      yang "salah" ini tetap berjalan normal, cuma jadi pertandingan
      ekstra yang tidak diminta) — dicatat di sini sebagai batasan yang
      disadari, bukan celah tersembunyi.
    - **Belum ada penanganan "berapa banyak yang sedang menunggu di
      tingkat ini"** — klien tidak tahu apakah antriannya sepi (langsung
      ke bot masuk akal) atau ramai (mungkin cuma perlu menunggu
      beberapa detik lagi). Ini bukan bug, cuma UX yang bisa
      ditingkatkan nanti kalau perlu.
    - ✅ **SUDAH diverifikasi di perangkat sungguhan** (2026-08-14).
      Moto G52J melawan emulator Pixel 8, dua akun Firebase berbeda,
      keduanya di tingkat Hiragana Dasar. "Cari Lawan" ditekan hampir
      bersamaan, dan **keduanya masuk pertandingan dalam ~12 detik —
      lebih cepat daripada ambang jatuh-ke-bot 20 detik**, jadi
      pemasangannya memang lewat Cloud Function, bukan lewat bot.
    - **Bukti keduanya di match yang sama** (bukan dua match bot
      terpisah): tangkapan layar serentak dari kedua perangkat
      menunjukkan **nomor kartu yang sama (Kartu 3/20) dan huruf yang
      sama (ふ)** pada saat yang sama, satu sisi memegang kolom
      jawaban, sisi lain menampilkan "Menunggu jawaban lawan…". Kalau
      masing-masing melawan bot, kartunya akan berbeda.
    - **Penilaiannya benar sampai akhir**: 7 jawaban dikirim
      bergantian dari kedua sisi, dan pertandingan berakhir dengan
      skor cermin sempurna — HP "Kalah, Kamu 3 Lawan 4", emulator
      "Menang!, Kamu 4 Lawan 3".
    - Belum diuji: jalur **jatuh ke bot** saat benar-benar sendirian
      (buka satu device saja, biarkan 20 detik penuh), dan bahwa dua
      tingkat berbeda **tidak** saling dipasangkan.

    **Ini menutup seluruh 10 butir "Urutan mengerjakan" di
    `NOTES_CARD_GAME_MODE.md`.** Yang masih terbuka di luar daftar
    bernomor itu (lihat "Rank pakai bintang" di bawah): logika gerak
    bintang sungguhan (naik/turun tingkat, divisi, bonus beruntun,
    pergantian musim) **belum dibangun sama sekali di mana pun** —
    dicek ulang di `functions/`, tidak ada satu baris kode pun yang
    menyentuh `cardGameRank` selain menyimpannya. `rankedMatch` (lihat
    butir 9) sudah menyiapkan fondasinya (tahu match mana yang
    seharusnya menggerakkan bintang), tapi logika penggerak bintangnya
    sendiri — dan seluruh "Papan peringkat bintang berdiri sendiri" di
    bawah — masih pekerjaan terpisah yang belum pernah masuk daftar
    bernomor "Urutan mengerjakan" sama sekali, bukan sesuatu yang lupa
    dikerjakan di butir 1-10.

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

### Bentuk konkret keyboard-nya

**Model interaksinya sebenarnya sudah tergambar dari mockup putaran
kedua dan ketiga** — tenten/maru/huruf kecil bukan tombol yang langsung
menghasilkan karakternya sendiri, tapi **pengubah karakter terakhir yang
sudah diketik**. Menekan か lalu ゛ mengubah karakter terakhir di kotak
jawaban dari か jadi が, bukan menambahkan karakter が baru. Ini sesuai
cara keyboard Jepang sungguhan bekerja, dan itu juga alasan papan
utamanya cuma 46 tombol dasar, bukan 104 — sisanya diakses lewat baris
pengubah di bawah.

- **Tenten (゛) / maru (゜)**: mengganti karakter terakhir dengan versi
  bertitik/berlingkaran-nya, kalau ada. か→が, は→ば (tenten) atau は→ぱ
  (maru). Kelompok mana yang punya pasangan ini **sudah ada di kode**,
  tidak perlu dipetakan ulang — `_dakutenGroups` di
  `kanji_combo_repository.dart` (dipakai untuk pengecoh soal bacaan)
  persis daftar yang sama yang dibutuhkan di sini.
- **ゃゅょ (huruf kecil)**: **menambahkan** karakter kecil baru setelah
  karakter terakhir (き → きゃ, dua karakter, bukan mengganti) — cuma
  berlaku kalau karakter terakhir salah satu dari 11 baris yang memang
  bisa membentuk youon (き/し/ち/に/ひ/み/り/ぎ/じ/び/ぴ). **Koreksi kecil**:
  daftar 11 ini bukan sesuatu yang bisa langsung dipakai ulang dari
  `_dakutenGroups` seperti tenten/maru di atas — isi `_dakutenGroups`
  untuk youon itu pasangan dakuten ANTAR kombinasi yang sudah terbentuk
  (きゃ↔ぎゃ), bukan daftar "huruf mana saja yang bisa dilanjutkan ゃゅょ".
  Daftar yang benar-benar dipakai di sini persis 11 baris youon yang
  sudah didefinisikan saat menyusun dataset kana
  (`generate_kana_data.py`, row 16-26) — sumbernya beda, tapi datanya
  sudah ada juga, tidak perlu dibuat baru dari nol.
- **っ (sokuon)**: beda dari tiga di atas — っ tidak mengubah/menambah
  berdasarkan karakter SEBELUMnya, dia cuma perlu karakter SESUDAHnya
  untuk berarti sesuatu (がっこう). Jadi tombol っ selalu aktif, bisa
  disisipkan kapan saja secara mekanis — apakah kombinasinya masuk akal
  secara bahasa itu urusan `RomajiConverter` saat jawabannya dibandingkan
  nanti, bukan sesuatu yang perlu dicegah keyboard-nya sendiri.
- **⌫ (hapus)**: menghapus satu karakter terakhir dari kotak jawaban.
- **Tombol pengubah yang tidak berlaku untuk karakter terakhir
  dinonaktifkan/diredupkan** (mis. menekan あ lalu mencoba tenten —
  あ tidak punya pasangan bertitik). Supaya anak tidak bingung kenapa
  ditekan tapi tidak terjadi apa-apa, bukan supaya terasa seperti bug.

### Tidak perlu tombol ー — dan ini nemu satu aturan konten kecil

Hiragana tidak pernah memakai chōonpu (ー) untuk vokal panjang — itu
konvensi katakana. Bacaan asli hiragana menuliskannya lewat pengulangan
vokal (とうきょう, bukan とーきょう), jadi keyboard yang memang dibatasi
hiragana saja tidak butuh tombol ini sama sekali.

**Tapi dicek langsung ke data, dan ketemu 2 pengecualian**: `データ分析`
dan `椅子取りゲーム` — kata majemuk yang mengandung komponen pinjaman
katakana (データ, ゲーム). Kalau kartu semacam ini tetap masuk pool untuk
tingkat Gold ke atas, "ketik bacaannya dalam hiragana" jadi tidak punya
jawaban yang bersih (bacaan データ butuh ー untuk diucapkan lengkap, dan
ー tidak ada bentuk hiragananya). **Usulan: kata yang mengandung karakter
katakana disaring keluar dari pool kartu** — pemeriksaannya murah (cek
apakah `word` mengandung karakter di rentang Unicode katakana), dan cuma
menyingkirkan 2 dari ribuan entri.

### Bentuk widget: mandiri, tidak terikat konteks pertandingan

Sesuai catatan lama ("layak dibuat sebagai widget mandiri") — antarmuka
yang masuk akal cuma butuh dua hal: nilai kotak jawaban saat ini (String)
dan sebuah callback saat berubah. Widget ini tidak perlu tahu apa pun
soal kartu, pertandingan, atau mode — cuma alat ketik hiragana biasa,
persis kenapa dia bisa dipakai ulang di modul lain nanti (mis. tempat
lain di aplikasi yang butuh input hiragana bebas).

### Tata letak — sudah selesai dari mockup putaran ketiga

Bukan lagi terbuka, sudah dikonfirmasi lewat tiga putaran perbaikan
gambar:

```
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
```

Celah kosong (baris や di kolom i/e, baris わ di kolom i/u/e)
**dipertahankan**, tidak dirapatkan — kesejajaran tiap kolom vokal itu
yang membuat papan mudah dibaca anak. Di bawahnya satu baris tombol
pengubah: ゛ ゜ ゃ ゅ ょ っ ⌫, lalu tombol "KIRIM JAWABAN" paling bawah.
Ruang keyboard dapat jatah besar (kira-kira sepertiga tinggi layar).

Hurufnya sendiri diambil langsung dari dataset kana yang sudah ada
(bukan disalin ulang dari gambar mockup — mockup cuma acuan tata letak,
bukan acuan glif, karena alat gambarnya memang tidak bisa diandalkan
menuliskan CJK dengan benar).

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
  currentRound               // 0-based; turnOrder[currentRound] bilang deck
                              // siapa + kartu apa (0-9 babak utama, 10-19 tambahan)
  turnOrder: [{round, deckOwnerUid, cardId}, ...]   // panjang 20, dibuat sekali
                                                      // saat match dibuat — lihat
                                                      // "Detail penilaian" di bawah
  turnStartedAt               // stempel waktu server, jangkar timer giliran ini
  clientResult                 // dihitung cepat di HP, buat layar "selesai" instan
  officialScore: {uidA: n, uidB: n}   // HANYA Cloud Function yang menulis
  result                        // dihitung ulang Cloud Function setelah semua kartu masuk

battleMatches/{matchId}/answers/{round}
  byUid              // yang MENJAWAB (bukan pemilik deck kartu itu)
  text, submittedAt
```

`answers` sengaja jadi subkoleksi, bukan array di dokumen induk — supaya
Cloud Function bisa `onCreate` per jawaban langsung (memicu per dokumen
baru), bukan harus membandingkan isi array sebelum/sesudah tiap kali
dokumen induk berubah.

**Penyederhanaan dari draf sebelumnya**: `currentTurnUid` sebagai field
terpisah dihapus — dulu dua kali mewakili hal yang sama (deck siapa yang
dikeluarkan), sekarang cukup dibaca dari
`turnOrder[currentRound].deckOwnerUid`. Satu sumber kebenaran, tidak ada
dua field yang bisa diam-diam beda isi.

### Alur satu giliran

1. Kartu `turnOrder[currentRound].cardId`, milik deck
   `turnOrder[currentRound].deckOwnerUid`, ditampilkan ke **pemain
   satunya** (dia yang menjawab, bukan pemilik deck).
2. Pemain penjawab mengetik jawaban, menekan kirim.
3. Klien menulis ke `answers/{currentRound}` (teks mentah saja, dengan
   `byUid` = dirinya sendiri), lalu di tulisan yang sama memajukan
   `currentRound` dan mengatur ulang `turnStartedAt`. Giliran berikutnya
   otomatis milik deck yang sesuai — `turnOrder` sudah menyelang-
   nyelingkan urutannya sejak dibuat, tidak perlu ada field yang
   "dipindahkan" secara terpisah.
4. Pemilik deck yang barusan kartunya keluar (listener Firestore)
   langsung lihat jawabannya masuk, dan menampilkan benar/salah untuk
   jawaban itu — dihitung sendiri secara lokal dari dataset yang sudah
   ada di HP-nya.
5. Cloud Function terpicu oleh dokumen `answers` baru, memvalidasi ulang
   secara independen, menulis ke `officialScore`. Begitu jumlah jawaban
   yang masuk sama dengan panjang pertandingan, Cloud Function menghitung
   `result` final dan itulah yang menggerakkan bintang.

### Detail penilaian Cloud Function

**Sumber kebenarannya**: salinan dataset bacaan (kana + kata kanji) ikut
dibundel ke folder `functions/`, dari sumber yang sama dengan yang
dipakai aplikasi Flutter — Cloud Function berjalan di Node.js, jadi tidak
bisa langsung memakai kelas Dart yang sama, cuma datanya yang disalin.

**Dikonfirmasi: `RomajiConverter` di-port ke JavaScript**, bukan
menyimpan bentuk hiragana baru di dataset. Alasannya: kartu kana
dijawab romaji, jadi Cloud Function tinggal bandingkan langsung ke
`kana.romaji` — tidak perlu konversi apa pun. Tapi kartu kanji dijawab
**hiragana**, sementara dataset menyimpan bacaannya sebagai romaji
(`{"word": "学生", "reading": "gakusei"}`, dicek langsung — tidak ada
bentuk kananya sama sekali). Jadi jawaban hiragana pemain harus diubah
ke romaji dulu sebelum dibandingkan — dan mengubah ke arah situ (kana →
romaji) itu mekanis, tidak ambigu, sudah terbukti benar lewat 7 tes yang
baru ditulis untuk `RomajiConverter`. Arah sebaliknya (menyimpan bentuk
kana lewat konversi otomatis romaji → kana) ditolak karena ambigu — "ji"
bisa berarti じ atau ぢ, "o" bisa berarti お atau を — dan berisiko
menghasilkan kunci jawaban yang salah untuk ribuan entri, kelas bug yang
sama persis dengan yang baru saja diaudit habis-habisan di sistem
furigana. Konsekuensi jujur dari pilihan ini: ada dua salinan logika
konverter di dua bahasa, jadi perbaikan di satu sisi (seperti bug youon
yang baru ditemukan) harus diingat untuk ikut diperbaiki di sisi
satunya.

**Urutan kartu ditentukan sekali, bukan diturunkan ulang tiap kali
diperlukan.** Alih-alih `cardsByPlayer` dua deck terpisah yang harus
disilangkan saat runtime untuk tahu "kartu round ke berapa milik siapa",
dokumen pertandingan menyimpan satu array gabungan yang sudah diselang-
seling begitu pertandingan dibuat:

```
battleMatches/{matchId}
  turnOrder: [
    { round: 0, deckOwnerUid, cardId },
    { round: 1, deckOwnerUid, cardId },
    ...  // sampai 19, dari 10+10 kartu tiap pemain yang sudah diacak
  ]
```

Baik klien maupun Cloud Function tinggal membaca `turnOrder[round]` yang
sama — tidak ada logika "kartu ini milik siapa" yang perlu ditulis dua
kali dan berisiko beda hasil.

**Penambahan skor lewat transaksi Firestore**, bukan baca-lalu-tulis
biasa — supaya dua jawaban yang divalidasi hampir bersamaan (bisa
terjadi karena jalur cepat/giliran tidak menunggu Cloud Function sama
sekali, jadi pemain bisa saja sudah lanjut ke beberapa giliran berikutnya
sebelum Cloud Function sempat memproses yang pertama) tidak saling
menimpa hasil.

**Menentukan kapan pertandingan selesai, tanpa terjebak jawaban yang
diproses tidak berurutan**: karena jalur cepat tidak menunggu Cloud
Function, jawaban ronde 5 bisa saja divalidasi Cloud Function *sebelum*
ronde 3 selesai diproses. Supaya pengecekan "sudah waktunya selesai
belum" tidak salah ambil kesimpulan dari data yang belum lengkap, tiap
kali `officialScore` diperbarui, Cloud Function mengecek: **apakah
jumlah `officialScore.uidA + officialScore.uidB` sama dengan
`round + 1`?** Kalau sama, berarti semua ronde dari 0 sampai ronde ini
sungguh sudah diproses (tidak ada yang terlewat), dan aman untuk
melangkah ke pengecekan kesimpulan. Kalau belum sama, ronde yang lebih
awal masih tertunda — invokasi ini berhenti di situ saja, dan begitu
ronde yang tertunda itu akhirnya diproses, transaksinya sendiri yang
akan menemukan jumlahnya sudah cocok dan melanjutkan pengecekan.
Trik ini tidak butuh penghitung urutan terpisah — cukup dari
`officialScore` yang memang sudah ada.

**Aturan kesimpulannya**, dicek tiap kali lolos pemeriksaan di atas dan
`round >= 9`:
- Skornya beda → pertandingan selesai, `result` = pemenang dengan skor
  lebih tinggi.
- `round == 19` dan masih sama → `result` = seri.
- Selain itu (masih sama, belum ronde 19) → belum selesai, lanjut ke
  babak tambahan berikutnya.

`result` inilah yang memicu pembaruan bintang — bukan `clientResult`
yang cuma untuk layar "selesai" instan di HP.

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
dibuat. Deck siapa yang masuk ke `turnOrder[0]` cukup diputuskan lewat
`Random` biasa saat dokumen ditulis.

**Kartu diambil acak, tanpa pengembalian — dan ini sebenarnya sudah
terjawab dari keputusan lama, cuma belum pernah disambungkan.** Bagian
"Kenapa deck 20 tapi main hanya 10" sudah bilang "setengah deck tidak
terpakai tiap match, jadi kartu yang keluar berbeda-beda" — itu cuma
masuk akal kalau pengambilannya acak, bukan berurutan (kalau berurutan,
10 kartu pertama akan selalu sama persis tiap pertandingan). Dan bagian
"Kalau tetap imbang, hasilnya seri" sudah bilang **10 kartu sisa dari
deck 20 itulah bahan babak tambahan** — itu juga cuma konsisten kalau 10
yang dipakai duluan adalah **10 dari 20 yang diacak**, menyisakan tepat
10 sisanya. Jadi: deck tiap pemain diacak seluruh 20 kartunya, 10
pertama dipakai untuk mengisi ronde 0-9 milik pemain itu di `turnOrder`,
10 sisanya mengisi ronde 10-19 kalau pertandingan lanjut ke babak
tambahan. **Tidak ada kartu yang dobel dalam satu pertandingan**, karena
diambil dari 20 kartu yang memang berbeda-beda, tanpa pengembalian.

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

### Tangga bintang sudah jalan (2026-08-14)

Seluruh aturan di dua bagian di atas sekarang benar-benar berjalan, bukan
rumusan lagi. Kodenya di `functions/battle_stars.js`, dipicu oleh trigger
baru `onBattleMatchConcluded` yang menyala setiap kali sebuah match punya
`result`.

**Kenapa di server, dan kenapa tidak ada salinannya di Dart.** Tangga ini
menentukan urutan papan peringkat publik, jadi kalau client boleh
menulisnya, seluruh tangganya cuma hiasan — siapa pun bisa menulis
langsung ke dokumennya sendiri dan jadi Emerald tanpa bertanding sekali
pun. Karena itu `firestore.rules` sekarang **menolak setiap penulisan
client yang mengubah `cardGameRank`**, dan Cloud Function (jalan dengan
hak Admin SDK, tidak tunduk pada rules) adalah satu-satunya penulisnya.
`ProgressRepository.setCardGameRank` ikut dihapus — tidak pernah dipanggil
siapa pun, dan sekarang hanya akan selalu gagal.

Berbeda dengan RomajiConverter yang memang harus ada di dua bahasa (Dart
dan Node sama-sama perlu mengubah kana), **tidak ada implementasi tangga
ini di Dart sama sekali** — aplikasi cuma perlu *menampilkan* peringkat
yang ditulis server, tidak perlu *memutuskan* pergerakannya, jadi salinan
kedua tidak membeli apa pun dan hanya menambah risiko melenceng.

**Dua hal yang rumusannya tidak menentukan, dan diputuskan di sini** —
keduanya ditulis di komentar kodenya juga, supaya tidak perlu ditebak
ulang nanti:
- **Bonus beruntun berlaku dari kemenangan ketiga dan seterusnya**, bukan
  cuma tepat di kemenangan ketiga. Rumusan cuma menulis "beruntun 3
  kemenangan memberi +2 bintang" tanpa menyebut kemenangan keempat
  bernilai berapa. Dibaca seperti Mobile Legends (perbandingan yang
  dipakai rumusan itu sendiri), karena alternatifnya — bonus hanya tiap
  kemenangan ketiga — membuat bonusnya nyaris tak terasa persis di tangga
  atas, tempat bonus itu ada justru untuk membuka kemacetan.
- **Seri tidak memutus rangkaian kemenangan.** Seri bukan kekalahan, dan
  format ini memang sering berakhir seri, jadi menghitungnya sebagai
  putusnya momentum akan menghukum formatnya, bukan pemainnya.

**Detail kecil yang penting**: kalah di dasar sebuah tingkat melaporkan
perubahan **0**, bukan −1. Bintangnya memang tidak berkurang (tertahan
lantai tingkat), jadi layar hasil tidak boleh mengaku ada bintang yang
hilang. Ada tesnya sendiri.

**Musimnya dihitung dari tanggal, bukan disimpan.** Season 1 = Jan-Feb
2026, dua bulan sekali. Pergantiannya "malas": baru berlaku saat pemain
main lagi, bukan tepat tengah malam. Ini disengaja — proyek ini tidak
punya Cloud Scheduler, dan dari sudut pandang pemain kedua cara itu tidak
bisa dibedakan.

**Verifikasi di perangkat sungguhan** (Moto G52J vs emulator Pixel 8, dua
akun berbeda, tiga pertandingan berturut-turut, HP selalu menang 5-0):

| | HP (menang terus) | Emulator (kalah terus) |
|---|---|---|
| awal | Bronze V, 0/3 | Bronze V, 0/3 |
| setelah menang 1 | Bronze V, **1/3** | Bronze V, 0/3 |
| setelah menang 2 | Bronze V, **2/3** + notis beruntun | Bronze V, 0/3 |
| setelah menang 3 | **Bronze IV, 1/3** | Bronze V, 0/3 |

Kemenangan ketiga menaikkan **dua** bintang sekaligus (2 → 4), melewati
batas divisi Bronze (3 bintang) dan naik dari V ke IV — jadi bonus
beruntun **dan** naik divisi terbukti dalam satu langkah. Sisi yang kalah
tiga kali berturut-turut tetap di 0/3, membuktikan perlindungan Bronze
juga jalan di jalur sungguhan, bukan cuma di unit test. `functions:log`
bersih, tanpa satu pun error.

**Yang belum diuji**: pergantian musim (butuh menunggu batas dua bulan
atau memalsukan jam server), kalah di Gold ke atas (butuh 35 kemenangan
dulu untuk sampai Gold), dan bahwa rules benar-benar menolak penulisan
`cardGameRank` dari client — rules-nya ter-deploy dan ter-compile, tapi
belum pernah dicoba ditembus sungguhan. Semua sudah tertutup unit test
(63 tes di `functions/battle_stars.test.js`, tiap aturannya dicek gigit
dengan cara sengaja merusak kodenya satu per satu), tapi tes bukan
perangkat sungguhan.

### Layar hasil menampilkan perubahan bintang (2026-08-14)

Sebelum ini bintang bergerak diam-diam: pemain menang lalu hanya melihat
"Kamu: 5, Lawan: 0", tanpa tahu naik berapa atau bahwa divisinya naik —
untuk mode yang seluruh daya tariknya mengejar peringkat, itu hadiah yang
tidak pernah diberikan. Sekarang `StarResultCard`
(`lib/features/battle/widgets/star_result_card.dart`) menampilkan
perubahannya di layar hasil.

**Angkanya datang dari server, bukan dihitung ulang di aplikasi.** Cloud
Function menulis `starResult` ke dokumen match — satu entri per pemain
berisi `delta`, tingkat/divisi/bintang sesudahnya, dan penanda
`tierChanged`/`divisionChanged`/`lossAbsorbed`. Hanya dia yang tahu
peringkat **sebelum** pertandingan, dan menghitung selisihnya di Dart
berarti menyalin aritmetika tangganya untuk kedua kali — persis duplikasi
yang file ini hindari. Ditulis di dokumen match, bukan di dokumen pemain,
karena ia menjelaskan **satu** pertandingan: pemain yang menyelesaikan
pertandingan kedua sebelum membuka hasil yang pertama akan melihat angka
yang salah kalau disimpan di profilnya.

**Tiga keadaan yang kalau dibiarkan kosong akan terbaca sebagai rusak**,
dan semuanya wajar terjadi:
- **Bintangnya belum sampai.** Hasil muncul begitu klien melihat
  pertandingan berakhir, sedangkan bintangnya digerakkan Cloud Function
  yang bereaksi pada kejadian yang sama — jadi ada satu-dua detik yang
  memang belum ada jawabannya. Kartunya bilang "Menghitung bintang...",
  lalu berganti sendiri. Kalau 12 detik tidak datang juga, ia berhenti
  menunggu dan bilang bintangnya sedang diperbarui — bukan memutar
  spinner selamanya.
- **Kalah tapi bintang tidak berkurang** (Bronze/Silver, atau tertahan
  lantai tingkat). Ditulis apa adanya plus alasannya.
- **Pertandingan teman/clan**, yang memang tidak menggerakkan bintang.
  Dikatakan langsung, bukan dibiarkan kosong.

**Cacat nyata yang ketahuan justru karena diuji di perangkat, dan sudah
diperbaiki**: percobaan pertama menampilkan "Bintangmu sedang
diperbarui" dan tidak pernah berubah. Sebabnya ada di rancangan saya
sendiri — fungsinya "mengklaim" match (menulis `starsApplied: true`)
**sebelum** menghitung, supaya pengiriman ganda tidak membayar dua kali.
Klaim duluan itu memang perlu, tapi artinya kalau ada kegagalan
**sesudah** klaim, match itu tersangkut selamanya: setiap pengiriman
ulang melihat `starsApplied` lalu berhenti, jadi bintangnya tidak pernah
dibayar dan `starResult` tidak pernah ada. Sekarang kegagalan setelah
klaim **melepas** klaimnya lagi, dibatasi penghitung `starsAttempts`
(maksimal 3 kali) — karena melepas klaim itu sendiri adalah penulisan ke
dokumen match, yang memicu ulang fungsi ini; tanpa batas, match yang
gagal terus akan mengulang selamanya. `starsApplied`/`starsAttempts`/
`starResult` ketiganya dikunci di `firestore.rules` supaya client tidak
bisa menulisnya.

**Diverifikasi di perangkat sungguhan, kedua sisinya:**
- Menang beruntun: **"+2 bintang · Bronze III · 0/3 bintang · Naik divisi
  — Bronze III!"**
- Kalah di Bronze: **"Bintang tidak berubah · Bronze V · 0/3 bintang · Di
  Bronze & Silver kamu tidak kehilangan bintang."**

`test/star_result_card_test.dart` (9 kasus) menutup semua keadaan di
atas, dan dicek benar-benar menggigit dengan merusak dua di antaranya.

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

## Pemasangan lawan publik

**Wawasan kunci: pertanyaan "dipasangkan berdasarkan apa" sebenarnya
sudah terjawab sebagian dari keputusan lama.** Karena isi deck sudah
dikunci per tingkat (Bronze→hiragana, ..., Emerald→N2-N1), memasangkan
lintas tingkat tidak masuk akal secara konten — Bronze lawan Emerald
berarti deck Emerald menanyakan kanji yang belum pernah dipelajari
pemain Bronze sama sekali (mustahil dijawab), sementara deck Bronze cuma
hiragana buat pemain Emerald (tidak ada tantangan). Jadi bukan lagi
"berdasarkan apa", tapi "seberapa ketat" — satu divisi persis, atau satu
tingkat saja lintas divisi?

**Satu tingkat saja, tidak perlu sampai divisi.** Isi kartu tidak
berbeda antar divisi dalam satu tingkat (tabelnya memetakan per
*tingkat*, bukan per divisi), jadi menyempitkan sampai divisi cuma
memperlambat antrian tanpa menambah kecocokan konten. Perbedaan skill
antar divisi biar diselesaikan tangga bintangnya sendiri secara alami.

### Antrian: Realtime Database lagi, bukan koleksi Firestore baru

Bukan menambah sistem ketiga — memakai ulang infrastruktur yang sama
yang sudah direncanakan untuk presence. Alasannya konkret: memasangkan
dua pemain yang sama-sama menunggu butuh **klaim atomik** ("ambil dua
yang paling awal menunggu, hapus keduanya dari antrian sekaligus") —
persis jenis operasi yang transaksi RTDB memang dirancang untuk. Kalau
dipaksakan ke Firestore, ada risiko dua Cloud Function yang jalan
bersamaan sama-sama mencoba memasangkan pasangan yang sama.

```
matchmakingQueue/{tier}/{uid}: { joinedAt: <server time> }
```

Begitu pemain mau lawan publik, dia menulis dirinya ke antrian
tingkatnya sendiri. Cloud Function terpicu tiap ada yang bergabung —
kalau di node tingkat itu sudah ada penunggu lain (bukan dirinya
sendiri), klaim keduanya dalam satu transaksi RTDB, hapus dari antrian,
lalu buat `battleMatches/{matchId}` (kartu diacak per pemain, giliran
awal dilempar koin — persis seperti yang sudah diputuskan di bagian
arsitektur pertandingan). Kalau belum ada yang lain, dia cuma menunggu —
pemain **berikutnya** yang bergabung ke tingkat yang sama nanti yang
memicu pemasangannya.

### Ini juga menutup pertanyaan bot dari bagian sebelumnya

Kalau setelah beberapa detik menunggu (usulan: 20 detik) tidak ada yang
bergabung, klien sendiri yang menyerah menunggu, menghapus dirinya dari
antrian, dan memanggil Cloud Function pembuat pertandingan yang sama
tapi dengan lawan `"BOT"` — pakai jalur pembuatan `battleMatches` yang
identik dengan matchmaking publik, cuma bedanya siapa pemain keduanya.

**Sengaja tidak melebar ke tingkat tetangga saat menunggu** — menghindari
pertanyaan tanpa jawaban bersih "kalau lintas tingkat, deck siapa yang
dipakai". Cukup tunggu dalam tingkat sendiri, lalu jatuh ke bot.

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
langsung sebagai jenis lawan sendiri. Titik pastinya sekarang sudah
terjawab di bagian "Pemasangan lawan publik" di atas — 20 detik
menunggu di antrian tingkat sendiri, lalu klien menyerah dan memanggil
jalur pembuatan pertandingan yang sama dengan lawan `"BOT"`.

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

**Catatan (2026-08-13)**: judul bagian ini sudah tidak seluruhnya akurat
— #1, #4, dan #5 sudah terjawab lewat diskusi arsitektur pertandingan/
bot/matchmaking di bagian lain dokumen ini, ditandai di tempatnya
masing-masing di bawah. Dibiarkan di sini apa adanya (bukan dihapus)
supaya jejak "kenapa ini pernah jadi masalah" tetap ada.

### 1. Bacaan di dataset disimpan sebagai romaji, bukan kana — **terjawab**

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

**Jalannya sekarang sudah dirinci penuh** di bagian "Detail penilaian
Cloud Function" — termasuk keputusan untuk mem-port `RomajiConverter`
ke JavaScript alih-alih menyimpan bentuk kana baru di dataset.

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

### 4. Kalau tidak ada lawan, fiturnya mati — **terjawab**

Ini risiko paling praktis dan belum dibahas sama sekali. Mode PvP serentak
menuntut **dua pemain online di saat yang sama**, sementara aplikasi ini
baru di tahap internal testing. Antrean yang kosong membuat "Mencari
Lawan…" berputar selamanya, dan fitur yang tidak pernah berhasil dimulai
akan ditinggalkan.

Perlu rencana untuk keadaan sepi — misalnya lawan bot, atau lawan "hantu"
yang memainkan ulang rekaman jawaban pemain lain.

**Jawabannya: bot**, bukan lawan hantu — dirinci penuh di bagian "Lawan
bot saat sepi" dan "Pemasangan lawan publik" (antrian per tingkat, 20
detik menunggu, lalu jatuh ke bot lewat jalur pembuatan pertandingan
yang sama).

### 5. Klien tidak boleh mengirim vonis, hanya teks jawaban — **terjawab**

Ini turunan dari aturan skor dihitung di server, tapi belum pernah ditulis
tegas. Kalau HP mengirim "aku benar", curang jadi sepele — tinggal selalu
mengirim benar. Yang dikirim harus **teks jawabannya**, dan server yang
memutuskan benar atau salah.

Konsekuensinya: kunci jawaban harus ada di sisi server juga.

**Ternyata tertegakkan secara struktural, bukan cuma konvensi** — lihat
bagian "Bentuk konkret jalurnya" di "Penilaian di server, bukan di HP".
Klien memang tidak pernah punya alasan mengirim vonis sama sekali:
giliran maju berdasarkan teks jawaban mentah, benar/salahnya dihitung
independen di kedua sisi (tampilan lokal di HP, resmi di Cloud
Function) dari dataset yang sama — tidak ada field "vonis" yang bisa
dikirim bahkan kalau mau.

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

**Dibersihkan (2026-08-13)** — daftar ini sudah lama tidak diperbarui,
dan sebagian besar isinya ternyata sudah terjawab di bagian lain
dokumen sepanjang diskusi arsitektur pertandingan/bot/matchmaking/
keyboard. Yang tersisa di bawah ini genuinely belum dibahas sama sekali:

- **Rumus poin per pertandingan** — `officialScore` sejauh ini murni
  jumlah jawaban benar per ronde. Apakah kecepatan menjawab ikut jadi
  faktor (mis. bonus kalau jauh di bawah batas waktu), atau memang
  murni benar/salah tanpa bobot kecepatan? Belum pernah dibahas.
- **Iklan banner di layar pertandingan** — mode ini gratis, jadi iklan
  tetap tampil di bagian lain aplikasi. Perlu dipastikan tidak
  mengganggu khususnya di layar pertarungan yang sudah padat (kartu,
  keyboard, timer).

Semua pertanyaan lain yang dulu ada di sini sudah terjawab, dicatat di
bagian masing-masing: 10 kartu = 10 ronde/20 jawaban (bagian mockup),
isi deck dikunci rank untuk publik/bebas dipilih untuk teman-clan
(bagian "Isi kartu ditentukan oleh rank"), giliran bergantian (tabel
keputusan paling atas), siapa duluan + kartu diambil acak (bagian
"Tiga pertanyaan yang tersisa"), lawan menutup aplikasi (bagian "Kalau
lawan menutup aplikasi di tengah pertandingan"), lawan publik
dipasangkan berdasarkan tingkat (bagian "Pemasangan lawan publik"),
peringkat berdiri sendiri (bagian "Papan peringkat bintang berdiri
sendiri"). "Mode pertarungan" sebagai pertanyaan sendiri sudah tidak
relevan lagi — begitu isi kartu dikunci rank, tidak ada lagi "mode"
yang dipilih terpisah.

**Reconnect ke pertandingan yang sama**: sebenarnya sudah terjawab
secara implisit dari bentuk arsitekturnya, cuma belum pernah ditulis
tegas — karena seluruh state pertandingan hidup di `battleMatches`
(Firestore), bukan di memori HP, pemain yang tersambung ulang cukup
berlangganan ulang ke dokumen yang sama dan langsung melihat keadaan
terkini. Tidak ada "sesi" yang bisa hilang di sisi klien. Satu-satunya
cara pertandingan benar-benar berakhir untuknya adalah forfeit
timeout+offline yang sudah dirancang di bagian lawan terputus.

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
