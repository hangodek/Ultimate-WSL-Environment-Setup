# Concat Video Editing Rules & Conventions

## 1. Project & Canvas Defaults
- **Resolution:** 1080x1920 (9:16 Vertical untuk Shorts, TikTok, dan Reels), 30 fps kecuali diminta khusus.
- **Multi-Platform Path Reference:**
  - **Windows (Prioritas Utama):**
    - Project Directory: `C:\Users\icyfa\Desktop\Concat\<ProjectName>`
    - Asset Source: `E:\Godek\Bahan Video\` (misal `Kucing/`, `Gambar/`, `Meme/`)
    - Asset Catalog: `E:\Godek\Bahan Video\Kucing\README.md`
  - **WSL (Windows Subsystem for Linux):**
    - Project Directory: `/mnt/c/Users/icyfa/Desktop/Concat/<ProjectName>`
    - Asset Source: `/mnt/e/Godek/Bahan Video/`
    - Asset Catalog: `/mnt/e/Godek\Bahan Video/Kucing/README.md`
  - **Linux Native:**
    - Project Directory: `~/Concat/<ProjectName>`
    - Asset Source: `~/Bahan Video/`
    - Asset Catalog: `~/Bahan Video/Kucing/README.md`
  - *Catatan Lingkungan:* Concat membatasi penyimpanan hanya di dalam home user atau root yang diizinkan. Deteksi OS sebelum membentuk path.

## 2. Track Hierarchy (Lanes)
- **Track T1 (Background):** Gambar latar (misal `Park.jpg`) atau video background. Durasi disesuaikan dengan total scene.
- **Track T2 (Foreground Left / Character 1):** Karakter utama / kiri (`offsetX: -0.22`, `offsetY: 0.18 - 0.25`).
- **Track T3 (Foreground Right / Character 2):** Karakter pendukung / kanan (`offsetX: 0.22`, `offsetY: 0.18 - 0.25`).
  - Wajib dibalik horizontal dengan `flipH: true` via `updateClip` dalam objek `patch` agar saling berhadapan.
- **Track T4 (Overlays / Props / Text):** Floating speech dialogue, headline POV, prop PNG transparan, dan efek layer.

## 3. Background Removal: Greenscreen vs AI Cutout
- **Greenscreen Chroma Key Standar:**
  Terapkan pada klip foreground berlatar hijau via `updateClip` di `patch.videoEffects`:
  ```json
  {
    "id": "concat.chroma-key",
    "params": {
      "similarity": 40.0,
      "softness": 12.0,
      "spill": 65.0
    }
  }
  ```
- **Non-Greenscreen AI Cutout (Fitur Bawaan Offline Concat):**
  Untuk footage tanpa kain hijau (misal latar putih atau ruangan biasa), gunakan operasi bawaan Concat:
  ```json
  {
    "op": "setClipCutout",
    "clipId": "<clipId>",
    "cutout": {
      "mode": "auto",
      "subject": "auto"
    }
  }
  ```

## 4. Typography & Subtitle Standards
- **Headline POV / Judul Pembuka:**
  - Teks: Hitam bersih (`color: "#000000"`).
  - Font: Standar sans (`Arial`, `Cabinet Grotesk`), ketebalan proporsional dan tidak tebal berlebih (`fontWeight: 700`, `fontSize: 0.055`).
  - Container Pill: Balutan rounded fill putih (`background: "#ffffff"`, `backgroundRadius: 0.015`, `backgroundPaddingX: 0.025`, `backgroundPaddingY: 0.012`).
  - Posisi: Bagian atas kanvas (`offsetY: -0.40`, `offsetX: 0.0`).
- **Floating Speech Dialogue (Kucing):**
  - Konsep: Melayang dekat posisi kucing, bukan subtitle film di bawah layar.
  - Kucing Kiri: `offsetX: -0.22`, `offsetY: -0.05` s.d. `0.02` (tepat di atas kepala kucing kiri).
  - Kucing Kanan: `offsetX: 0.22`, `offsetY: -0.05` s.d. `0.02` (tepat di atas kepala kucing kanan).
  - Kucing Bertingkat / Tangga: Sesuaikan sumbu Y mengikuti posisi visual kucing masing-masing.
  - Teks: Putih bersih (`color: "#ffffff"`), font standar terbaca (`fontWeight: 600 - 700`, `fontSize: 0.045 - 0.05`).
  - Stroke & Shadow: Outline hitam tipis (`strokeColor: "#000000"`, `strokeWidth: 0.008`) dan soft shadow (`shadow: true`).
  - Background: Tanpa kotak pembungkus (`background: ""`).

## 5. Pre-Production Storyboard Protocol (WAJIB SEBELUM EKSEKUSI)
Agen AI **DILARANG KERAS** langsung membuat proyek atau memodifikasi timeline Concat sebelum menyajikan tabel Storyboard Visual dan disetujui pengguna.

### Alur Kerja 4 Langkah:
1. **Tahap 1 (Input Cerita Pengguna):** Pengguna memberikan ide cerita, naskah kasar, atau konsep video.
2. **Tahap 2 (Penyusunan Storyboard AI):** AI mencari aset di katalog index (`README.md` pada folder bahan), menghitung durasi realistis, dan memetakan adegan ke dalam tabel storyboard terstruktur.
3. **Tahap 3 (Konfirmasi Visual):** AI berhenti sejenak dan meminta konfirmasi ringkas dari pengguna (*"Apakah susunan adegan dan aset di atas sudah pas, atau ada yang mau ditukar sebelum dieksekusi ke Concat?"*).
4. **Tahap 4 (Eksekusi Batch Concat):** Setelah pengguna menyetujui, AI langsung merakit adegan ke Concat via perintah `batch` sesuai detik dan aset yang ada di storyboard.

### Format Standar Tabel Storyboard:
| Scene & Waktu | Aksi Visual & Konteks | Track T1 (Background) | Track T2 (Kucing Kiri) | Track T3 (Kucing Kanan) | Track T4 (Teks & Props) | Audio & Suasana |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Scene 1 (Teras)**<br>`0.0s - 4.5s` | Oren mulai ngomong santai, hitam nyimak | `teras_rumah.jpg` | `cat-talking-orange.mp4`<br>- *Source:* `1.0s - 5.5s`<br>- *Volume:* `1.0` | `cat-bored.mp4`<br>- *Posisi:* Kanan (`flipH: true`)<br>- *Volume:* `0.0` (nyimak) | **Headline POV:**<br>"POV: Ngayal Bareng Bro"<br>**Speech (Kiri):**<br>"Bro, bayangin kalo kita..." | Suara vokal oren ngeong, BGM santai |

## 6. Turn-Taking Dialogue & Natural Pacing Rules
Percakapan kucing bukan monolog cepat yang dipukul rata 2.5 detik. Percakapan berjalan bergantian (*turn-taking*), di mana satu kucing berbicara dan kucing lawannya mendengarkan.

### A. Pembagian Peran per Giliran (Beat):
1. **Pembicara Aktif (Active Speaker):**
   - Klip video kucing berbicara / berekspresi aktif (`cat-talking-*`, `cat-screaming-*`).
   - Volume suara wajib aktif (`volume: 1.0`).
   - Teks floating dialogue muncul tepat di atas kepala penutur.
2. **Pendengar Pasif (Passive Listener):**
   - Klip video kucing mendengarkan / bengong / datar (`cat-bored`, `cat-sleepy`, `cat-waiting`, `cat-black-zoning-out`).
   - Volume suara wajib dibisukan (`volume: 0.0`) agar audio tidak bertabrakan.
   - Wajib menghadap pembicara (`flipH: true` jika berada di sebelah kanan).
3. **Kontinuitas Background (Track T1):**
   - Latar belakang di Track T1 tetap menyambung dan tidak perlu dipotong atau diganti selama adegan masih berada di lokasi yang sama.

### B. Rumus Pacing Durasi Alami (Berdasarkan Kata):
Penonton membutuhkan waktu untuk membaca teks dan mencerna audio:
- **Kalimat Pendek (3–5 kata):** `2.5s - 3.5s`
- **Kalimat Sedang (6–10 kata):** `4.0s - 6.0s`
- **Kalimat Panjang / Ocehan Ngegas:** `6.0s - 8.5s`
- **Total Durasi Video Shorts / Reels:** Umumnya berkisar antara **30 detik sampai 60 detik** mengalir alami.

## 7. Storyboard Examples: Fantasy & Comedy Sketches
Untuk cerita absurd, nyeleneh, atau khayalan bertingkat (*POV Ngayal Bareng Bro*), susun transisi latar tempat dan perubahan emosi kucing secara dramatis.

### Contoh Kasus: "Ngayal Bareng Bro Lawan Naga di Cina"
Prompt Pengguna:
> *"Bikinin video shorts ngayal bareng sohib: Kiri kucing oren, kanan kucing hitam. Awalnya lagi nongkrong di teras, si oren ngajak ngayal kalo mereka ke Cina jadi pendekar kungfu, lawan naga si oren sok jago tapi hitam nangis, lawan raja iblis si oren joget santai. Endingnya balik ke teras, si hitam bengong nagih utang seblak."*

Tabel Storyboard yang Wajib Dihasilkan AI:
| Scene & Waktu | Penutur Aktif (Suara ON & Teks) | Lawan Bicara (Mute & Nyimak) | Background (T1) | Suasana, Musik & SFX |
| :--- | :--- | :--- | :--- | :--- |
| **Scene 1 (Teras)**<br>`0.0s - 4.5s` | **Kiri (Oren):**<br>"Bro, bayangin kalo kita berdua dikirim ke negeri Cina..." | **Kanan (Hitam):**<br>Planga-plongo nyimak santai (`volume: 0.0`) | `teras_rumah.jpg` | Suasana sore tenang, vokal ngomong santai |
| **Scene 1 (Teras)**<br>`4.5s - 8.5s` | **Kanan (Hitam):**<br>"Ngapain ke Cina? Mau jualan bakpao lu di sana?" | **Kiri (Oren):**<br>Tampang datar mendengarkan (`volume: 0.0`) | `teras_rumah.jpg` | Suara nyindir sinis |
| **Scene 2 (Cina)**<br>`8.5s - 13.5s` | **Kiri (Oren):**<br>"BUKAN BAKPAO! KITA JADI PENDEKAR KUNGFU PALING SAKTI!" | **Kanan (Hitam):**<br>Kucing salute jenderal (`cat-saluting.mp4`, `volume: 0.0`) | `tembok_cina.jpg` | **Transisi Lokasi:** Masuk BGM musik tradisional Cina epik |
| **Scene 3 (Sarang Naga)**<br>`13.5s - 19.5s` | **Kiri (Oren):**<br>"MAJU LU NAGA OMPONG, SINI GUA JADIIN ABON!" | **Kanan (Hitam):**<br>Banana cat nangis kejer (`banana-cat-crying.mp4`, `volume: 1.0`) | `volcano_cave.jpg` | Suara raungan naga menggelegar, naga sembur api, teriakan panik |
| **Scene 4 (Istana Iblis)**<br>`19.5s - 25.5s` | **Kiri (Oren):**<br>"Raja iblis doang mah enteng, gua tabok pake sendal!" | **Kanan (Hitam):**<br>Natap curiga kaget (`cat-eyebrow-vine-boom.mp4`) | `demon_castle.jpg` | Musik orkestra boss battle memuncak + sound vine boom |
| **Scene 5 (Realita Teras)**<br>`25.5s - 31.0s` | **Kanan (Hitam):**<br>"Ngayal mulu lu... bayar dulu utang seblak gua kemarin." | **Kiri (Oren):**<br>Cengar-cengir tanpa dosa (`cat-smiling-camera.mp4`) | `teras_rumah.jpg` | **Musik epik mati mendadak (*awkward silence*).**<br>Suara jangkrik malam + Vine Boom penutup |

### Panduan Cara Prompt untuk Pengguna (User Prompting Guide):
Pengguna cukup mengirimkan 3 elemen santai:
1. **Ide / Situasi:** *"Lagi nongkrong di teras terus ngayal petualangan epik"*
2. **Karakter & Dialog Kasar:** *"Oren sok jagoan, hitam penakut tapi nagih utang"*
3. **Poin Khusus (Opsional):** *"Di sarang naga banana cat nangis, endingnya musik mati mendadak"*

## 8. Audio Rules & Anti-Popping Standards
- **Anti-Popping Wajib:**
  Setiap micro-cut wajib menyertakan `fadeIn: 0.05` dan `fadeOut: 0.05` pada objek `patch` di `updateClip` untuk mencegah bunyi klik atau pop audio pada batas potongan.
- **Pertahankan Audio / Sound Effect Asli (`volume: 1.0`):**
  - Dialog / Vokal: `cat-talking-*`, `cats-talking-*`, `cat-i-go-meow`.
  - Reaksi Suara Iconic: `cat-laughing-*`, `cat-huh`, `cat-happy-happy-happy`, `cat-oi-oi-oi`, `cat-eyebrow-vine-boom`, `cat-screaming-*`, `cat-crunchy-luna`, `cat-pop`, `banana-cat-crying`, `cat-sad-meowing-*`.
  - Pengecualian Khusus User (BGM / Audio Tetap ON):
    - `cat-sleeping.mp4`
    - `cat-black-zoning-out.mp4` (lagu bengong / dimarahin)
    - `cat-reading-book.mp4`
    - `banana-cat-spinning.mp4`
    - `cat-clapping.mp4`
- **Otomatis Mute (`volume: 0.0`):**
  - Klip reaksi visual pasif yang audionya bertabrakan saat karakter menjadi pendengar atau penyimak:
    `cat-smiling-camera`, `cat-dilated-pupils`, `cat-bored`, `cat-sleepy`, `cat-lying-thinking`, `cat-in-sock`, `cat-ginger-waiting`, `cat-wet-staring`, `cat-orange-looks-around`, `cat-dancing-wop`, dll.

## 9. Granular Clip Trimming & Dynamic Expressions
- **Hindari klip greenscreen utuh:** Potong durasi panjang yang memuat gerakan kamera atau zoom-in bawaan kreator.
- **Micro-Cuts 1–3 Detik:** Ambil hanya bagian ekspresi yang stabil dan bersih menggunakan `sourceStart` dan `trimClip`.
- **Variasikan Reaksi (Multi-cut per Adegan):** Buat pergantian reaksi (misal 2 detik buang muka lalu cut ke 2 detik melotot tajam).
- **Karakterisasi Dinamis:** Gunakan momen internal klip sesuai emosi adegan (misal detik awal bingung, detik tengah marah).

## 10. Dynamic Keyframe Motion & Animation Standards (Anti-Slideshow)
- **Larangan Karakter Statis:** Dilarang membiarkan karakter diam kaku seperti slide presentasi saat melakukan aksi dinamis (berjalan, berpetualang, kedinginan, atau merayakan sesuatu).
- **Concat Keyframing Engine (`op: "setClipKey"`):**
  Concat mendukung animasi kurva Bézier penuh dengan parameter:
  `property`: `"offsetX"`, `"offsetY"`, `"scale"`, `"rotation"`, `"opacity"`, `"volume"`.
  `at`: Posisi normalisasi waktu di dalam klip (`0.0` s.d. `1.0`).
  `ease`: `"linear"`, `"in"`, `"out"`, atau `"inOut"`.

### Preset Animasi Wajib:
1. **Animasi Berjalan & Melangkah (`anim_walk`):**
   - Pergerakan linier horizontal: `setClipKey` pada `offsetX` dari titik awal ke titik akhir (misal `-0.40` ke `-0.20`).
   - Langkah naik-turun (*walking bob*): 4-8 keyframe pada `offsetY` berosilasi `0.22 -> 0.19 -> 0.22` dengan `ease: "inOut"` untuk menghasilkan ilusi hentakan langkah kaki.
2. **Animasi Menggigil / Gemetar Kedinginan (`anim_shiver`):**
   - Osilasi cepat pada `rotation` (`-5.0` s.d. `+5.0` derajat) atau jitter `offsetX` untuk adegan kedinginan di salju atau teriak histeris.
3. **Animasi Mengapung Ombak Air (`anim_water_bob`):**
   - Osilasi sinusoidal lembut pada `offsetY` (`0.22` s.d. `0.26`) untuk adegan menyeberang danau atau samudra.
4. **Animasi Lompat Girang / Selebrasi (`anim_bounce`):**
   - Hentakan lompat tinggi pada `offsetY` (`0.22` melonjak ke `0.08` lalu kembali ke `0.22`) dipadukan dengan denyut zoom `scale` (`0.65` ke `0.72`).
5. **Kamera Parallax Background Pan (`anim_pan_bg`):**
   - Berikan `scale: 1.10` pada gambar latar Track T1, lalu gerakkan `offsetX` perlahan dari `0.03` ke `-0.03` untuk menciptakan ilusi pergerakan kamera pemandangan (*cinematic parallax pan*).


## 11. JSON-RPC Execution Architecture & Atomic Batching
- **Penting Mengenai `flipH`:**
  Jangan masukkan `flipH` ke dalam `setClipTransform`. Parameter tersebut hanya didukung di dalam `updateClip` pada objek `patch`.
- **Atomic Batching (`op: "batch"`):**
  Gabungkan semua operasi pembuatan adegan dalam satu payload batch agar dieksekusi secara instan dan atomik tanpa overhead IPC.

### Format Payload Batch Lengkap (Adegan 2 Karakter Berdialog)
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "edit.apply",
  "params": {
    "path": "<ProjectPath>",
    "command": {
      "op": "batch",
      "commands": [
        {
          "op": "addClip",
          "trackId": "T1",
          "mediaId": "m_bg",
          "start": 0.0
        },
        {
          "op": "addClip",
          "trackId": "T2",
          "mediaId": "m_cat_left",
          "start": 0.0
        },
        {
          "op": "setClipTransform",
          "clipId": "c2",
          "offsetX": -0.22,
          "offsetY": 0.20,
          "scale": 1.0
        },
        {
          "op": "updateClip",
          "clipId": "c2",
          "patch": {
            "fadeIn": 0.05,
            "fadeOut": 0.05,
            "volume": 1.0,
            "videoEffects": [
              {
                "id": "concat.chroma-key",
                "params": {
                  "similarity": 40.0,
                  "softness": 12.0,
                  "spill": 65.0
                }
              }
            ]
          }
        },
        {
          "op": "addClip",
          "trackId": "T3",
          "mediaId": "m_cat_right",
          "start": 0.0
        },
        {
          "op": "setClipTransform",
          "clipId": "c3",
          "offsetX": 0.22,
          "offsetY": 0.20,
          "scale": 1.0
        },
        {
          "op": "updateClip",
          "clipId": "c3",
          "patch": {
            "flipH": true,
            "fadeIn": 0.05,
            "fadeOut": 0.05,
            "volume": 0.0,
            "videoEffects": [
              {
                "id": "concat.chroma-key",
                "params": {
                  "similarity": 40.0,
                  "softness": 12.0,
                  "spill": 65.0
                }
              }
            ]
          }
        },
        {
          "op": "addTextClip",
          "trackId": "T4",
          "start": 0.0,
          "duration": 4.5,
          "offsetY": -0.40,
          "style": {
            "content": "POV: Ngayal Bareng Bro",
            "fontFamily": "Arial",
            "fontSize": 0.055,
            "fontWeight": 700.0,
            "color": "#000000",
            "background": "#ffffff",
            "backgroundRadius": 0.015,
            "backgroundPaddingX": 0.025,
            "backgroundPaddingY": 0.012,
            "shadow": false,
            "strokeWidth": 0.0
          }
        },
        {
          "op": "addTextClip",
          "trackId": "T4",
          "start": 0.0,
          "duration": 4.5,
          "offsetY": -0.02,
          "style": {
            "content": "Bro, bayangin kalo kita berdua...",
            "fontFamily": "Arial",
            "fontSize": 0.048,
            "fontWeight": 700.0,
            "color": "#ffffff",
            "strokeColor": "#000000",
            "strokeWidth": 0.008,
            "shadow": true,
            "background": ""
          }
        },
        {
          "op": "setClipTransform",
          "clipId": "c5",
          "offsetX": -0.22,
          "offsetY": -0.02
        }
      ]
    }
  }
}
```

## 12. Execution Speed & One-Shot Production Protocol
- **Dilarang Screenshot Loop di Tengah Jalan:** AI dilarang memanggil `preview.frame` secara berulang-ulang untuk menginspeksi setiap adegan di tengah proses pembuatan. Hal ini menyebabkan penundaan bermenit-menit akibat roundtrip token multimodal LLM.
- **Deterministic One-Shot Assembly:** Seluruh timeline, posisi transform, dan keyframe Bézier wajib dirakit secara matematis dalam satu kali jalan (One-Shot) menggunakan rumus koordinat kanvas pasti:
  - Karakter Kiri: `offsetX: -0.22`, `offsetY: 0.22` (skala 0.65)
  - Karakter Kanan: `offsetX: 0.22`, `offsetY: 0.22` (skala 0.65, `flipH: true`)
  - Running / Chase: Masuk dari `offsetX: -0.65`, keluar di `offsetX: 0.65`
  - Headline POV: `offsetY: -0.40` | Floating Dialogue: `offsetY: -0.08`
- **Instant Live Preview di Concat Editor GUI:** Begitu timeline selesai dirakit (< 0.1 detik), segera panggil `project.open` untuk langsung menampilkan proyek di jendela Concat Editor pengguna. Pengguna dapat langsung menekan `Spacebar` untuk memutar video secara real-time tanpa menunggu render.
- **On-Demand Video Export:** Ekspor hardware MP4 (`export.run`) hanya dijalankan apabila pengguna secara eksplisit meminta ekspor video final atau ingin menguji hasil matang, guna menghemat waktu render di setiap iterasi ide.
