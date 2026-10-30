# CapCut Video Editing Rules & Conventions (Adaptasi Aturan Concat)

Panduan standar pembuatan video meme, short-form konten (TikTok/Reels/Shorts), dan percakapan karakter di **CapCut Desktop Windows** melalui **CapCut MCP Server** dan **VectCutAPI** di lingkungan WSL2.

---

## 1. Project & Canvas Defaults
- **Resolusi Kanvas:** `1080 x 1920` (Format vertikal 9:16 untuk Shorts, TikTok, dan Reels).
- **Frame Rate:** `30 fps` (default stabil dan universal).
- **Multi-Platform Path Reference:**
  - **Windows Host (CapCut Desktop):**
    - Projects Directory: `C:\Users\Han\AppData\Local\CapCut\User Data\Projects\com.lveditor.draft\<ProjectName>`
    - Media Assets: `D:\Godek\Bahan Video\` (e.g. `Kucing\`, `Gambar\`, `Meme\`)
    - Asset Catalog: `D:\Godek\Bahan Video\Kucing\README.md`
  - **WSL2 (Linux Environment):**
    - Projects Directory: `/mnt/c/Users/Han/AppData/Local/CapCut/User Data/Projects/com.lveditor.draft/<ProjectName>`
    - Media Assets: `/mnt/d/Godek/Bahan Video/`
    - Asset Catalog: `/mnt/d/Godek/Bahan Video/Kucing/README.md`
- **Asset Auto-Staging:** VectCutAPI secara transparan menyalin file media lokal Windows ke dalam subfolder `assets/` di direktori proyek draft CapCut.

---

## 2. Multi-Track Hierarchy & Fixed Size Lanes (Anti-Tumpang Tindih)

Klip meme kucing memiliki variasi resolusi sumber yang berbeda (16:9 landscape `1920x1080` vs 9:16 portrait `720x1280`). Untuk mencegah klip saling tumpang tindih (*overlap*) di tengah kanvas, gunakan standarisasi **Fixed Size & Safe-Zone Positioning**:

| Track ID | Nama Track | Tipe | Stacking (`relative_index`) | Koordinat & Skala Fixed | Deskripsi & Peran |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **T1** | `background` | Image / Video | `0` | `scale: 1.0 - 1.8`, `x: 0.0, y: 0.0` | Latar belakang visual (`bg-*.jpg`, `bg-trotoar.png`). Berkelanjutan (*continuous*) sepanjang scene. |
| **T2** | `cat_left` | Video | `1` | `x: -0.50 s.d. -0.55`, `y: -0.30`<br>`scale_x: 0.58, scale_y: 0.58` | **Karakter Utama Kiri (Oren):** 1 klip = 1 objek per beat. Skala wajib `0.58` agar tidak meluber ke tengah layar. Menghadap kanan. |
| **T3** | `cat_right` | Video | `2` | `x: 0.50 s.d. 0.55`, `y: -0.30`<br>`scale_x: 0.58, scale_y: 0.58` | **Karakter Pendukung Kanan (Hitam):** 1 klip = 1 objek per beat. **Wajib `flip_horizontal: true`** agar saling berhadapan. Skala wajib `0.58`. |
| **T4** | `speech_dialogue` | Text | `3` | `x: -0.45` (kiri) / `0.45` (kanan)<br>`y: 0.08 s.d. 0.12` | Floating Speech Dialogue tepat di atas kepala karakter penutur. **Wajib Multiline Wrap (`\n`)**. |
| **T5** | `headline_pov` | Text | `4` | `x: 0.0, y: 0.75` | Headline POV pill box rounded di bagian atas kanvas. **Wajib Multiline Wrap (`\n`)**. |
| **T6** | `audio_bgm` | Audio | - | `volume: 0.15 - 0.25` | Backsound musik suasana latar (stabil tanpa dipotong/dimute). |
| **T7** | `audio_sfx` | Audio | - | `volume: 1.0` | Sound effect punchline atau transisi beat (Vine boom, Among us, Huh sound, Snap). |

> [!IMPORTANT]
> **Larangan Skala Besar:** DILARANG menggunakan `scale: 0.75 - 0.85` untuk footage meme kucing 16:9 (`1920x1080`). Skala 0.8 akan membuat lebar klip mencapai 864px sehingga kedua kucing bertabrakan hampir 400px di tengah layar. Gunakan selalu **`scale: 0.55 - 0.58`** dan posisikan di `transform_x: ±0.52`.

---

## 3. Background Removal: Kalibrasi Chroma Key Bersih (Anti-Bocor Hijau)

Untuk footage kucing berlayar hijau (`D:\Godek\Bahan Video\Kucing\*.mp4`), gunakan kalibrasi parameter kroma berikut agar tepian bulu kucing bersih tanpa garis hijau (*green spill/fringing*):

- **Target Warna (`chroma_color`):** `#00fe00` (kunci warna hijau murni). Jangan dikosongkan.
- **Intensitas (`chroma_intensity`):** `0.40` s.d. `0.45` (40% - 45%). Nilai `0.20` terlalu tipis dan meninggalkan sisa hijau.
- **Pembersih Pantulan Hijau (`spill_value`):** Wajib aktif di nilai `0.55` (55%) untuk menyapu pantulan hijau di bulu kucing.
- **Pemulihan Bayangan (`shadow_value`):** Wajib aktif di nilai `0.50` (50%) agar bulu kucing hitam/gelap tidak ikut tembus pandang (*hollowed out*).
- **Penghalus Tepi (`edge_smooth_value`):** `0.05` s.d. `0.10` untuk tepian yang halus natural.

---

## 4. Typography & Subtitle Standards: Multiline Wrapping Protocol (`\n`)

Tampilan vertikal 9:16 (1080px) sangat rentan membuat teks panjang terpotong di tepi kiri/kanan layar. **Wajib menggunakan Enter / Line Break (`\n`)** pada setiap teks:

### A. Headline POV / Judul Pembuka Kanvas:
- **Dilarang Teks 1 Baris Panjang:** Judul seperti `"POV: Diajak Temen Jalan Sore di Trotoar"` DILARANG ditulis dalam satu baris karena ujung kiri ("POV") dan ujung kanan ("Trotoar") pasti terpotong keluar layar!
- **Wajib Multiline (`\n`):** Pecah judul menjadi 2 baris proporsional:
  ```text
  POV: Diajak Temen
  Jalan Sore di Trotoar
  ```
- **Ukuran & Gaya:**
  - `font_size: 8.0 - 8.5`, tebal (`bold: true`), hitam pekat (`font_color: "#000000"`).
  - Posisi: `transform_x: 0.0, transform_y: 0.75` (bagian atas kanvas).
- **Container Pill:**
  - `background_color: "#FFFFFF"`, `background_alpha: 1.0` (putih solid).
  - `background_round_radius: 0.45` (rounded pill box).
  - `background_width: 0.65 - 0.75`, `background_height: 0.16 - 0.20` (sesuai teks 2 baris).

### B. Floating Speech Dialogue (Percakapan Kucing):
- **Konsep:** Teks melayang di atas kepala kucing penutur, bukan subtitle film di bawah layar.
- **Dilarang Teks 1 Baris Melebar:** Karena posisi kucing berada di samping (`x: -0.52` atau `0.52`), teks 1 baris panjang (misal *"Bro, temenin jalan sore yuk..."*) pasti membuat huruf depannya terpotong di tepi kanvas (menjadi *"ro, temenin..."*).
- **Aturan Maksimal 2–3 Kata per Baris (Wajib Enter `\n`):**
  - **Salah:** `"Bro, temenin jalan sore yuk..."`
  - **Benar:**
    ```text
    Bro, temenin
    jalan sore yuk...
    ```
  - **Salah:** `"HUH?! Ogah ah, panas begini bro!"`
  - **Benar:**
    ```text
    HUH?! Ogah ah,
    panas banget bro!
    ```
- **Koordinat Penempatan:**
  - Kucing Kiri: `transform_x: -0.45 s.d. -0.50`, `transform_y: 0.08 s.d. 0.12`.
  - Kucing Kanan: `transform_x: 0.45 s.d. 0.50`, `transform_y: 0.08 s.d. 0.12`.
- **Gaya Visual:**
  - `font_size: 7.0 - 7.5` (ringkas, padat, tidak menabrak batas layar).
  - `font_color: "#FFFFFF"`, `bold: true`.
  - `border_color: "#000000"`, `border_width: 0.08` (outline tegas).
  - `shadow_enabled: true`, `shadow_color: "#000000"`.
  - `background_alpha: 0.0` (tanpa kotak pembungkus).

---

## 5. Turn-Taking Dialogue & Object Rules

1. **1 Video = 1 Objek Karakter Tunggal:**
   - Setiap klip video green screen mewakili 1 entitas objek karakter tertentu di timeline.
   - Dilarang memasukkan klip yang salah peran/konteks (misal memasukkan `cat-happy-happy-happy` saat adegan kucing sedang berbicara santai).
2. **Pembagian Peran per Giliran (Beat):**
   - **Pembicara Aktif (Active Speaker):**
     - Gunakan klip video ekspresi berbicara yang relevan (`cat-talking-1.mp4`, `cat-huh.mp4`, `cat-screaming.mp4`).
     - Volume suara wajib aktif (`volume: 1.0`).
     - Floating speech dialogue muncul tepat di atas kepala penutur (dengan format multiline `\n`).
   - **Pendengar Pasif (Passive Listener):**
     - Gunakan klip video mendengarkan/reaksi (`cat-black-zoning-out.mp4`, `cat-annoyed-orange.mp4`, `cat-bored.mp4`).
     - Volume suara **wajib dimatikan (`volume: 0.0`)** agar audionya tidak bertabrakan dengan pembicara aktif.
     - Karakter kanan wajib `flip_horizontal: true` agar saling berhadapan.
3. **Pacing Durasi Alami:**
   - Beat pendek (ngajak/tanya): `2.5s - 3.5s`
   - Beat respons/reaksi: `3.0s - 4.0s`
   - Total durasi skit 2 beat: `6.0s - 7.5s`

---

## 6. Pre-Production Storyboard Protocol (WAJIB SEBELUM EKSEKUSI)

Sebelum membuat atau memodifikasi timeline CapCut, susun terlebih dahulu tabel storyboard adegan:

| Beat & Waktu | Objek 1: Kiri (Oren) | Objek 2: Kanan (Hitam) | Headline POV & Floating Speech (`\n`) | Suasana, SFX & Audio |
| :--- | :--- | :--- | :--- | :--- |
| **Beat 1**<br>`0.0s - 3.5s` | **Aktif (`cat_left`):**<br>- Klip: `cat-talking-1.mp4`<br>- Vol: `1.0` | **Pasif (`cat_right`):**<br>- Klip: `cat-black-zoning-out.mp4`<br>- Vol: `0.0`<br>- `flip_horizontal: true` | **POV (2 Baris):**<br>"POV: Diajak Temen\nJalan Sore di Trotoar"<br>**Speech Oren (2 Baris):**<br>"Bro, temenin\njalan sore yuk..." | Suara meong ngomong aktif, BGM santai sore |
| **Beat 2**<br>`3.5s - 6.5s` | **Pasif (`cat_left`):**<br>- Klip: `cat-annoyed-orange.mp4`<br>- Vol: `0.0` | **Aktif (`cat_right`):**<br>- Klip: `cat-huh.mp4`<br>- Vol: `1.0`<br>- `flip_horizontal: true` | **Speech Hitam (2 Baris):**<br>"HUH?! Ogah ah,\npanas banget bro!" | Suara kaget "HUH?!" kencang |

---

## 7. Eksekusi Standar via CapCut MCP Server

Gunakan urutan pemanggilan API berikut:
1. `capcut_create_draft` (`width: 1080`, `height: 1920`, `fps: 30`)
2. `capcut_add_image` (`image_url`: latar belakang, `start: 0`, `end: TotalDurasi`, `track_name: "background"`, `relative_index: 0`)
3. `capcut_add_video` untuk Karakter Kiri per beat:
   - `track_name: "cat_left"`, `relative_index: 1`
   - `transform_x: -0.52`, `transform_y: -0.30`, `scale_x: 0.58`, `scale_y: 0.58`
   - `chroma_key: true`, `chroma_color: "#00fe00"`, `chroma_intensity: 0.40`
   - `volume: 1.0` jika aktif, `0.0` jika pasif.
4. `capcut_add_video` untuk Karakter Kanan per beat:
   - `track_name: "cat_right"`, `relative_index: 2`
   - `transform_x: 0.52`, `transform_y: -0.30`, `scale_x: 0.58`, `scale_y: 0.58`
   - `flip_horizontal: true`
   - `chroma_key: true`, `chroma_color: "#00fe00"`, `chroma_intensity: 0.40`
   - `volume: 1.0` jika aktif, `0.0` jika pasif.
5. `capcut_add_text` untuk Headline POV:
   - `text: "Baris 1\nBaris 2"`, `transform_x: 0.0, transform_y: 0.75`
   - `background_alpha: 1.0`, `background_color: "#FFFFFF"`, `background_round_radius: 0.45`
   - `font_color: "#000000"`, `bold: true`, `font_size: 8.5`
6. `capcut_add_text` untuk Floating Speech Dialogue per beat:
   - `text: "Maks 2-3 kata\nper baris"`, `font_size: 7.5`
   - Posisi Kiri: `transform_x: -0.45, transform_y: 0.10`
   - Posisi Kanan: `transform_x: 0.45, transform_y: 0.10`
   - `font_color: "#FFFFFF"`, `border_color: "#000000"`, `border_width: 0.08`, `shadow_enabled: true`
7. `capcut_add_audio` untuk BGM & SFX.
8. `capcut_save_draft` (`project_name: "NamaProyek"`).
