# Concat Video Editing Rules & Conventions

## 1. Project & Canvas Defaults
- **Resolution:** 1080x1920 (9:16 Vertical for Shorts/TikTok/Reels), 30 fps unless requested otherwise.
- **Project Directory:** `C:\Users\icyfa\Desktop\Concat\<ProjectName>`
- **Asset Source:** `E:\Godek\Bahan Video\` (e.g. `Kucing/`, `Gambar/`, `Meme/`).
- **Asset Catalog:** Gunakan index `E:\Godek\Bahan Video\Kucing\README.md` untuk memilih nama file video kucing berdasarkan emosi (marah, sedih, senang, ngomong, dll).

## 2. Track Hierarchy
- **Track T1 (Background):** Gambar latar (e.g. `Park.jpg`) atau video background. Durasi disesuaikan dengan total durasi scene.
- **Track T2 (Foreground Left / Character 1):** Karakter utama / kiri.
- **Track T3 (Foreground Right / Character 2):** Karakter pendukung / kanan.
  - Jika dua karakter berinteraksi, karakter kanan otomatis `flipH: true` agar saling berhadapan.
- **Track T4 (Overlays / Text):** Subtitle, judul, atau efek layer di atas video.

## 3. Green Screen (Chroma Key) Standards
Setiap klip greenscreen WAJIB menggunakan parameter ini agar tidak ada artefak hijau:
```json
{
  "id": "concat.chroma-key",
  "params": {
    "similarity": 40,
    "softness": 12,
    "spill": 65
  }
}
```

## 4. Execution Workflow
1. Buka atau buat project dengan `project.open` / `project.create`.
2. Probe media yang dibutuhkan dan import via `media.import`.
3. Susun di timeline (`addClip`, `trimClip`, `setClipSpeed`).
4. Atur posisi (`setClipTransform`):
   - Karakter kiri: `offsetX: -0.22`, `offsetY: 0.18 - 0.25` (pijakan realistis).
   - Karakter kanan: `offsetX: 0.22`, `offsetY: 0.18 - 0.25`, `flipH: true`.
5. Terapkan `concat.chroma-key` standar pada semua klip foreground.
6. Simpan otomatis dengan `project.save`.
7. Render frame preview (`preview.frame`) untuk inspeksi visual sebelum final export.

## 5. Granular Clip Trimming & Dynamic Expressions (PENTING)
- **Hindari pakai video greenscreen dari awal sampai habis (full length):**
  Banyak video meme memiliki zoom-in/out mendadak atau gerakan kamera bawaan kreator aslinya.
- **Ambil potongan spesifik (Micro-cuts 1–3 detik):**
  Gunakan `sourceStart` dan `trimClip` untuk memotong HANYA bagian ekspresi yang stabil, bersih, dan sesuai emosi adegan.
- **Variasikan Reaksi (Multi-cut per Adegan):**
  Alih-alih 1 video monoton selama 5 detik, buat variasi cut-to-cut (misal 2 detik buang muka -> cut ke 2 detik natap tajam/melotot).
- **Karakterisasi Dinamis berdasarkan Momen Klip:**
  Perhatikan perubahan emosi di dalam satu file (contoh: `Black cat shaking its head` awal = bengong/bingung, tengah/akhir = marah/ngegas). Gunakan detik awal saat butuh reaksi bodoh/blank, dan detik tengah saat butuh reaksi marah.

## 6. Audio Rules & Volume Handling (PENTING)
- **Pertahankan Audio / Sound Effect Asli (`volume: 1.0`):**
  - Klip vokal/dialog: `cat-talking-*`, `cats-talking-*`, `cat-i-go-meow`.
  - Klip reaksi suara iconic: `cat-laughing-*`, `cat-huh`, `cat-happy-happy-happy`, `cat-oi-oi-oi`, `cat-eyebrow-vine-boom`, `cat-screaming-*`, `cat-crunchy-luna`, `cat-pop`, `banana-cat-crying`, `cat-sad-meowing-*`.
  - **Pengecualian khusus permintaan user (BGM/Suara tetap ON):**
    - `cat-sleeping.mp4`
    - `cat-black-zoning-out.mp4` (lagu bengong/dimarahin iconic)
    - `cat-reading-book.mp4`
    - `banana-cat-spinning.mp4`
    - `cat-clapping.mp4`
- **Otomatis Mute (`volume: 0.0`):**
  - Klip reaksi visual pasif lainnya yang punya suara noise/BGM bertabrakan saat jadi karakter pendengar/nyimak:
    `cat-smiling-camera`, `cat-dilated-pupils`, `cat-bored`, `cat-sleepy`, `cat-lying-thinking`, `cat-in-sock`, `cat-ginger-waiting`, `cat-wet-staring`, `cat-orange-looks-around`, `cat-dancing-wop`, dll.
  - Setiap kali klip ini dipakai sebagai pendengar/reaksi pasif yang tidak butuh audio bawaannya, wajib di-set `volume: 0.0`.
