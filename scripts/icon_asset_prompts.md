# Prompt ikon & aset kartu XP — Teisou

Satu berkas per ikon, disimpan sementara di mana saja lalu diserahkan ke
Claude untuk dipasang. Ini menggantikan **emoji polos** yang sekarang
dipakai di kartu-kartu Home dan kartu Level/XP — bukan mengganti karakter
Jepang (あ/ア/字/文/を/読/聴), yang memang harus tetap teks asli, sudah
sama persis dengan mockup.

---

## Baca ini dulu — pelajaran dari maskot (`scripts/mascot_prompts.md`)

**1. Latar magenta rata `#FF00DC`, bukan transparan.** Generator gambar
menggambar kotak-kotak transparansi sebagai piksel sungguhan kalau
diminta latar transparan. Magenta tidak ada di palet ikon manapun di
bawah, jadi aman dipotong bersih sesudahnya.

**2. Satu gaya, dipakai berulang di setiap prompt.** Character sheet di
bawah ditempel di depan setiap prompt ikon supaya seluruh set terlihat
seperti dibuat oleh satu orang, bukan tempelan dari sumber berbeda-beda.

**3. Ukuran kanvas 512×512**, bukan 1024 seperti maskot — ini ikon kecil
(dipakai di dalam lingkaran ~44-52px di aplikasi), bukan ilustrasi besar,
jadi detail berlebih justru hilang saat diperkecil.

---

## Character sheet ikon — tempel di setiap prompt di bawah

> Flat vector icon illustration, single main subject centred, filling
> about 65% of the frame with even margin on all sides. Soft cel-shaded
> style with two tone levels per colour (base + one soft shadow shade),
> no gradient mesh, no texture, no outer drop shadow. Every shape has a
> clean, even outline in dark plum/maroon `#5A2A3A` (matching this app's
> mascot outline colour), never pure black.
>
> Colour palette restricted to: coral red `#F4667A`, sky blue `#4F97F4`,
> warm amber `#E8B84B`, soft pink `#FCE9EC`, soft blue `#E8F0FE`, cream
> `#FCEEDB`, white, and the outline plum. Pick 1-2 of the accent colours
> per icon as instructed below — never use all of them in one icon.
>
> Kawaii-adjacent but not a character — an object/symbol only, no eyes,
> no face, no limbs, unless the icon description below explicitly asks
> for one. Suitable for a children's Japanese-learning app.
>
> Background: solid flat magenta `#FF00DC`, completely uniform, no
> gradient, no shadow, no pattern. Square 512×512 image, no text, no
> letters, no watermark, no border, no frame.

---

## Set A — ikon modul & bagian Home

Setiap ikon di bawah menggantikan satu emoji yang sekarang dipakai
mentah-mentah di `lib/features/home/widgets/modules_section.dart`.
Warna aksen yang disebut harus dipakai sebagai warna utama bentuknya
(bukan warna latar lingkaran — itu sudah digambar kode, ikon ini yang
disisipkan di dalamnya).

### 1. `icon_kosakata` — pengganti 📚 (Kosakata, warna aksen biru `#4F97F4`)
> Subject: a small stack of two-three flashcards, slightly fanned, with
> one visible Japanese character (お) on the top card rendered in the
> outline colour. Accent colour: sky blue.

### 2. `icon_kaiwa_latihan` — pengganti 💬 (dipakai untuk kartu Kaiwa *dan*
untuk header bagian "Latihan" — satu ikon, dua tempat, warna aksen coral
`#F4667A`)
> Subject: a rounded speech bubble with a small second, smaller speech
> bubble overlapping behind it (a conversation between two people, not
> one bubble alone). Accent colour: coral red.

### 3. `icon_alat` — pengganti 🔧 (header "Alat", warna aksen abu-abu
netral `#9AA3AF`)
> Subject: a single wrench, angled diagonally, simple and iconic — no
> other tools alongside it. Accent colour: neutral grey, slightly darker
> outline than usual for contrast against light backgrounds.

### 4. `icon_segera_hadir` — pengganti ⏳ (header "Segera Hadir", warna
aksen abu-abu netral `#9AA3AF`)
> Subject: a small sand hourglass, upright, with visible falling sand
> grains mid-fall inside it. Accent colour: neutral grey.

### 5. `icon_kosakata_kanji_header` — pengganti 📖 (header "Kosakata &
Kanji", warna aksen biru `#4F97F4`)
> Subject: an open book viewed from a slight top-down angle, pages
> visible and blank (no text on the pages), with a single small Japanese
> character (字) printed on the visible left page in the outline colour.
> Accent colour: sky blue.

### 6. `icon_dasar_kurikulum` — pengganti 🌸 (dipakai untuk header "Dasar"
*dan* "Kurikulum" — satu ikon, dua tempat, warna aksen coral `#F4667A`)
> Subject: a single five-petal sakura blossom viewed face-on, simple and
> symmetric, with a small yellow-amber centre dot. Accent colour: coral
> pink petals, amber centre.

### 7. `icon_belajar_gambar` — pengganti 🖼️ (kartu "Belajar dari Gambar",
warna aksen abu-abu netral, ini kartu "Segera Hadir" jadi warnanya
sengaja diredam)
> Subject: a simple framed picture/photo icon — a rectangle frame with a
> small mountain-and-sun landscape glyph inside it. Accent colour:
> neutral grey (this icon renders muted/desaturated in the app, so keep
> the linework the strongest part, not the fill colour).

### 8. `icon_belajar_video` — pengganti 🎬 (kartu "Belajar dari Video",
sama alasan warna redam seperti di atas)
> Subject: a rounded rectangle video-frame shape with a simple triangular
> play button centred inside it. Accent colour: neutral grey, same muted
> treatment as the picture icon above.

---

## Set B — kartu XP/Level (yang paling kamu keluhkan)

Ini mengganti **dua** hal sekaligus di `lib/features/home/widgets/level_card.dart`:
lencana level yang sekarang cuma emoji 🌸 di lingkaran polos, dan tombol
hadiah yang sekarang cuma emoji 🎁. Keduanya diganti supaya terasa
"dibuat", bukan emoji sistem yang dipinjam.

### 9. `xp_level_badge` — lencana level (ukuran ~48px di aplikasi, jadi
detail harus tetap terbaca kecil)
> Subject: a circular medallion/seal badge, edge lined with a wreath of
> small sakura blossoms and leaves running around the rim like a school
> achievement badge. The centre of the medallion is empty/blank — no
> number, no text, no character — because the app draws the level number
> as real text on top of this art. Accent colour: coral red wreath on a
> soft pink medallion face.

### 10. `xp_reward_omamori` — tombol klaim hadiah (ukuran ~44px, dan
harus terbaca jelas juga saat 35% opacity/pudar di state "belum ada
hadiah")
> Subject: a traditional Japanese omamori charm — a small rectangular
> brocade pouch with a drawstring cord knotted at the top and a tassel
> hanging from the knot, no text/kanji printed on the pouch face (keep it
> plain so it doesn't imply a specific wish). This replaces a generic
> Western gift-box icon with something that actually belongs in this
> app's world. Accent colour: coral red pouch body, amber/gold cord and
> tassel.

### 11. `xp_reward_omamori_glow` (opsional, kalau mau versi kedua untuk
efek "hadiah siap diambil" — badge merah kecil yang sekarang cuma angka
polos bisa tetap teks, tapi omamori-nya sendiri bisa dapat versi ini)
> Same omamori as above, but with three small sparkle shapes (four-point
> stars) floating around it — top-left, top-right, and directly above —
> suggesting it's glowing/ready to be claimed. Accent colour: same coral
> and gold, sparkles in warm amber.

---

## Setelah gambarnya jadi

1. Simpan semua 10-11 file dengan nama persis seperti judul di atas
   (`icon_kosakata.png`, `xp_level_badge.png`, dst).
2. Kirim ke saya (chat ini atau folder yang sama seperti mockup
   sebelumnya, `C:\Teisou asset\...`) — saya yang potong latar magenta,
   pasang ke kode, dan verifikasi di device seperti biasa (analyze, test,
   build, screenshot).
3. Kalau ada icon yang hasilnya kurang pas (proporsi, warna terlalu
   ramai, dll), sebutkan nomornya saja — saya bisa revisi prompt itu
   sendiri tanpa mengulang semuanya.

**Belum termasuk di sini, sengaja**: ikon menu Profil (Daftar Belajar,
Bahasa App, Tema App, Notifikasi, dst.) — itu juga emoji polos, tapi
kamu belum menyinggungnya secara eksplisit. Bilang saja kalau itu mau
ikut dirombak juga, saya susulkan promptnya di batch berikutnya.
