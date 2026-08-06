# Prompt gambar maskot Teisou

Satu berkas per ekspresi, disimpan di `assets/mascot/{mood}.png`.
Nama berkas **harus** persis sama dengan nama mood di
`lib/core/widgets/mascot_widget.dart` — kalau tidak, aplikasi diam-diam
jatuh ke emoji dan tidak ada yang error.

---

## Baca ini dulu — dua kesalahan yang sudah pernah terjadi

**1. Jangan minta latar transparan.** Generator gambar hampir semuanya
tidak bisa menghasilkan alpha. Kalau diminta transparan, mereka
*menggambar* kotak-kotak abu-abu yang melambangkan transparansi sebagai
piksel biasa — filenya kelihatan benar di pratinjau, lalu kotak-kotak itu
ikut masuk ke aplikasi. Gemini melakukan persis itu pada percobaan
pertama.

Karena itu semua prompt di bawah meminta **latar magenta rata `#FF00DC`**.
Warna itu tidak ada di mana pun pada artwork (kucing putih, palet pastel),
jadi bisa dipotong bersih setelahnya:

```bash
python scripts/prepare_mascot.py "C:/Teisou asset/mascot/encouraging.png" encouraging
```

Skrip itu membaca sendiri warna latar tiap gambar (hasil generator tidak
pernah persis hex yang diminta — enam gambar lalu keluar antara `#F002DC`
dan `#F906EE`), membuang bercak nyasar, lalu memusatkan dan menyamakan
ukuran karakter supaya tinggi badannya tidak berubah-ubah antar ekspresi.

**2. Gaya harus mengikuti maskot yang sudah ada, bukan tebakan.** Deskripsi
di bawah diturunkan dari `happy.png` dan `sad.png` yang sudah dipakai —
bukan dari ingatan. Selalu lampirkan satu gambar lama sebagai referensi
kalau generatornya menerima gambar.

---

## Character sheet — tempel di setiap prompt

> A chibi cartoon cat mascot, full body, standing upright on two hind legs,
> facing the viewer. Roughly two heads tall: the head is as large as the
> whole body, cheeks round and wide.
>
> Fur is pure white with very soft pale grey-lavender cel shading. The
> entire character is drawn with a thick, even outline in a dark plum /
> maroon colour (not black), including the inner details.
>
> Face: two very large glossy dark-brown almond eyes, each with two white
> highlights; a tiny pink upside-down-triangle nose; a small simple curved
> mouth; a soft pink oval blush on each cheek. Ears are triangular with
> pale pink inner ears.
>
> It wears a crimson-red bandana / neckerchief tied around its neck with a
> small white five-petal flower on it. **The bandana is the signature and
> must appear in every drawing.**
>
> Style: kawaii sticker illustration, clean flat vector-like shapes, soft
> cel shading, no gradient mesh, no texture, no line-weight variation,
> friendly and suitable for young children.
>
> Background: solid flat magenta `#FF00DC`, completely uniform, no
> gradient, no shadow, no checkerboard, no pattern, no vignette.
>
> Composition: character centred, full body visible including both feet,
> small even margin on all sides, square 1024×1024 image. No text, no
> letters, no watermark, no border, no frame, no extra objects unless the
> pose below asks for one.

---

## Ekspresi yang sudah ada (jangan digambar ulang)

`happy`, `excited`, `sleepy`, `proud`, `sad`, `cheering` — sudah ada di
`assets/mascot/`.

---

## Ekspresi baru

Setiap poin di bawah menggantikan kalimat terakhir character sheet.
Tulisan miring menjelaskan kapan aplikasi memakainya — itu yang menentukan
pose harus terbaca sebagai apa.

### 1. `encouraging`
*Muncul setiap kali murid menjawab salah. Ini ekspresi yang paling sering
dilihat anak setelah gagal, jadi tidak boleh terbaca sebagai kasihan atau
menggurui.*

> Pose: standing with one front paw held out, palm open and turned upward
> in a gentle "it's alright" gesture, the other paw resting at its side.
> Head tilted very slightly. Eyes soft and warm with a small closed-mouth
> smile — kind and reassuring, not laughing, not pitying.

### 2. `thinking`
*Ditampilkan saat soal masih belum dijawab.*

> Pose: one front paw raised to touch its chin, head tilted upward and to
> one side, eyes looking up and to the corner as if working something out.
> Mouth a small flat line. A small dark-plum question mark floats near the
> top of its head.

### 3. `explaining`
*Untuk balon yang menerangkan cara kerja layar, bukan menanggapi jawaban.*

> Pose: standing with one front paw pointing forward and slightly to the
> side, the other paw held near its chest. Eyes open and attentive, mouth
> open in a small friendly "explaining" shape, eyebrows slightly raised.

### 4. `surprised`
*Skor sempurna — hasil paling langka di aplikasi.*

> Pose: both front paws raised near the cheeks, body leaning back a
> little. Eyes very wide and round with large highlights, mouth open in a
> small round "oh". Three short dark-plum motion lines radiating outward
> above the head.

### 5. `curious`
*Saat murid pertama kali membuka sebuah modul.*

> Pose: head tilted markedly to one side, one ear perked higher than the
> other, one front paw lifted slightly off the ground. Eyes wide and
> interested, mouth a tiny curious "o". Tail curled into a question-mark
> shape behind it.

### 6. `determined`
*Awal ujian, dan salah satu balasan untuk jawaban salah — "ayo coba
lagi". Sama dengan tag `semangat` di Kaiwa.*

> Pose: both front paws clenched into small fists, one raised up beside
> the head in a "let's go" gesture, body leaning slightly forward. Eyes
> bright and focused with eyebrows angled down in determination, mouth in
> a confident open grin. A small flame-free energy sparkle beside the
> raised fist.

### 7. `waving`
*Sapaan di layar Home saat belum ada yang sedang dikerjakan.*

> Pose: one front paw raised high and open, mid-wave, the other paw at its
> side. Body turned very slightly. Eyes happy crescents, mouth a wide open
> friendly smile. Two small dark-plum motion arcs beside the waving paw.

### 8. `bowing`
*Tag `sopan` dan `minta_maaf` di Kaiwa.*

> Pose: bowing forward from the waist at about thirty degrees, both front
> paws held together flat in front of its body, head lowered. Eyes closed
> in two gentle downward curves, mouth a small polite closed smile. Ears
> folded slightly back.

### 9. `relaxed`
*Tag `santai` di Kaiwa.*

> Pose: standing loosely, weight on one leg, both front paws relaxed at
> its sides, shoulders low. Eyes closed in two calm upward curves, mouth a
> small contented smile. Tail resting in a soft gentle curve.

### 10. `worried`
*Tag `khawatir` di Kaiwa, dan level yang masih terkunci.*

> Pose: both front paws held together in front of its chest, shoulders
> drawn in slightly. Eyebrows angled upward in the middle in concern, eyes
> looking slightly to the side, mouth a small wavy uncertain line. Ears
> drooping downward. A single small sweat-drop shape near one temple.

### 11. `reading`
*Layar bacaan dan pelajaran.*

> Pose: sitting upright, holding an open book with both front paws in
> front of its chest, looking down into it. The book is plain cream with a
> soft coral cover and no text on the pages. Eyes lowered and focused,
> mouth a small content smile.

### 12. `writing`
*Layar urutan goresan kanji.*

> Pose: standing, holding a traditional Japanese calligraphy brush upright
> in one front paw, the other paw resting on a small blank sheet of cream
> paper in front of it. The brush has a light bamboo handle and a dark
> plum tip. Eyes focused downward on the paper, tongue tip just poking out
> of the corner of the mouth in concentration.

---

## Setelah gambarnya jadi

```bash
python scripts/prepare_mascot.py "C:/Teisou asset/mascot/encouraging.png" encouraging
python scripts/prepare_mascot.py "C:/Teisou asset/mascot/"*.png
```

Bentuk kedua mengambil nama mood dari nama berkas, jadi simpan tiap gambar
dengan nama mood-nya.

Skrip akan memperingatkan kalau hasilnya kurang dari 5% berpiksel padat —
itu tandanya warna latar salah terbaca, bukan tandanya gambarnya jelek.
Cek hasilnya di `assets/mascot/` sebelum menjalankan aplikasi.
