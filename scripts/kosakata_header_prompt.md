# Prompt header Kosakata — Teisou

Header `_KosakataHeaderBanner` yang sekarang (langit gradasi kode + torii/
gunung digambar lewat `CustomPaint`) kelihatan kasar dibanding banner
modul lain yang sudah pakai gambar asli (`bg_module_header.png`). Ini
prompt buat gambar pengganti yang benar-benar dirancang, **satu file**,
bukan kombinasi kode+gambar seperti sekarang.

**Bukan aset ter-isolasi** — sama seperti `bg_module_header.png` di
`module_frame_asset_prompts.md`, ini scene utuh (langit sampai ke tepi
kanvas), jadi **tidak perlu** latar magenta atau instruksi isolasi.

---

## Character sheet — tempel di depan prompt di bawah

> Soft cel-shaded flat illustration style, matching a children's Japanese-
> learning app. Every shape uses a clean, even outline in dark plum/maroon
> `#5A2A3A`, never pure black. No gradient mesh, no photographic texture,
> no drop shadow outside the art itself. Gentle Japanese motifs only:
> torii gates, gentle mountain silhouettes, soft clouds — kawaii-adjacent,
> warm, welcoming, never scary or ornate/cluttered. No text, no letters,
> no watermark, no characters/mascot in the scene — those are placed on
> top of this art separately afterward.

---

## `bg_kosakata_header` — banner header modul Kosakata

Beda dari `bg_module_header.png` (yang lebar, dipakai di semua modul lain
dan berwarna coral/pink), yang ini **biru**, khusus layar Kosakata, dan
proporsinya lebih persegi karena dipasang penuh selebar layar HP (bukan
strip lebar seperti modul lain).

> Canvas: 1200×700. Composition: a soft pastel sky gradient from pale sky
> blue `#E8F0FE` (top) into near-white (bottom), completely flat and
> uniform — no visible band edges. On the **left third** of the canvas: a
> single soft torii gate silhouette in a slightly deeper blue `#4F97F4` at
> low opacity, standing on a gentle rolling hill silhouette in the same
> blue tone, both quiet enough to read as a backdrop rather than a busy
> scene. Scatter a handful of small four-petal flower/snowflake shapes
> (simple, symmetrical, like a stylised plum blossom) in pale blue across
> the upper-right two-thirds of the canvas, varying in size, all at low
> opacity. Leave the **entire right third of the canvas empty** (just sky)
> — that's where a mascot character is placed on top of this art
> afterward, so nothing should be drawn there. Leave the **top-center
> strip empty** too (just sky, no flowers crossing it) — that's where a
> screen title and a short accent underline sit on top of this art. Keep
> every shape pastel/low-contrast enough that dark navy title text stays
> easily readable on top of any part of this image.

---

## Setelah gambarnya jadi

1. Simpan sebagai `bg_kosakata_header.png`.
2. Kirim ke saya — saya potong secukupnya lalu pasang lewat
   `Image.asset('assets/module_frames/bg_kosakata_header.png', fit:
   BoxFit.cover)` menggantikan `_BlueSkylinePainter` yang sekarang, tanpa
   mengubah posisi maskot/judul/tombol kembali (itu tetap kode, cuma
   latarnya yang diganti gambar asli).
