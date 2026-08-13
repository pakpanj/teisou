# Mode Game Card

Catatan rumusan untuk mode permainan kartu di Teisou — Kana Master.

**Status: rumusannya sudah menutup seluruh alur (undangan → arsitektur
pertandingan → penilaian Cloud Function → bot → matchmaking publik →
keyboard kana). Implementasi kode sungguhan sudah jalan jauh — seluruh
Tahap 1 (keyboard kana, field rank minimal, presence RTDB) sudah
selesai DAN sudah hidup** (instans Realtime Database sudah dibuat lewat
Firebase Console 2026-08-13, `asia-southeast1`/Singapore, rules-nya
sudah dipasang, `databaseURL` sudah masuk ke `firebase_options.dart`,
dan tulisan `presence/{uid}` sudah dikonfirmasi muncul sungguhan di
Console setelah aplikasi dibuka di device fisik). **Tahap 2 SELESAI
SEPENUHNYA (butir 4-7), dan semuanya sudah hidup di produksi** —
pertandingan bisa benar-benar dimainkan kartu demi kartu, disinkronkan
real-time lewat Firestore antara dua akun berbeda di dua perangkat
berbeda (device fisik + emulator), lengkap dengan timer, keyboard kana
untuk kartu kanji, skor lokal, mekanisme timeout-forfeit, kesimpulan
pertandingan yang dihitung identik dan independen di kedua sisi (jalur
cepat), dan sekarang juga penilaian resmi lewat Cloud Function
(`onBattleAnswerCreated`, sudah ter-deploy dan tampil di
`firebase functions:list`) — lihat "Tahap 2" di bawah untuk detail
lengkapnya. **Penemuan penting di sesi ini**: CLI Firebase yang
sebelumnya dicatat "broken" ternyata cuma masalah binary bawaan —
`npx firebase-tools` bekerja normal dan sudah terautentikasi, jadi
deploy Cloud Functions/Firestore/RTDB rules ke depan tidak perlu lagi
paste manual ke Console. Sisanya: bot, matchmaking, undangan di
Tahap 3 — belum ada kode.
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
8. **Bot dulu**, bukan publik atau teman — pakai kembali seluruh pipa
   Tahap 2, bisa diuji sendirian tanpa koordinasi dengan orang lain.
   Kalau ada yang salah di penilaian/skor/bintang, ketahuan di sini
   dulu, sebelum ada pemain sungguhan terdampak.
9. Undangan teman/clan — butuh presence (#3), dan `FriendRepository`/
   `ClanRepository` memang sudah jalan dari fitur lain.
10. Matchmaking publik — sengaja terakhir, butuh semuanya sudah berdiri
    (tingkat, pembuatan pertandingan, bot sebagai jalan keluar antrian
    sepi) dan paling rumit (antrian RTDB, klaim atomik).

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
