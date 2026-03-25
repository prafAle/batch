# 🎧 extractMP3Adv — Advanced MP4 → MP3 Audio Extractor (Batch Script)

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Windows](https://img.shields.io/badge/Platform-Windows_10/11-blue)
![FFmpeg](https://img.shields.io/badge/Requires-FFmpeg-green)
![Status](https://img.shields.io/badge/Status-Stable-brightgreen)

`extractMP3Adv.cmd` is an **advanced Windows batch script** designed to extract MP3 audio from MP4 files, either by merging multiple files into a single MP3 or by splitting each MP4 into its own MP3 file.

The script includes:

✅ Automatic bitrate optimization with **smart presets**  
✅ Merge or split mode  
✅ Support for both **single input file** and **entire folders**  
✅ Optional **output directory**  
✅ ANSI‑enhanced colorful UI + CMD color fallback  
✅ Built‑in validation and FFmpeg/FFprobe detection  
✅ Multi‑thread FFmpeg auto‑optimization  
✅ Dynamic file size target (199 MB)  
✅ Professional logging and error handling

This tool is ideal for:

- Audio merging workflows  
- Podcast creation from video fragments  
- Video-to-audio extraction  
- Normalizing large MP4 groups into a single MP3 file  
- Automated high-volume processing

---

# 📦 Features

### 🔹 **Two operation modes**
- **Merge (default)** → combine multiple MP4 videos into one MP3  
- **Split** → extract one MP3 per input MP4

### 🔹 **Smart Bitrate Engine**
Bitrate is dynamically calculated based on:
- total MP4 duration
- target max size (199 MB)
- preset multiplier (HQ / MED / LOW)

### 🔹 **Presets**
Preset Mode | Behavior | Description
------------|----------|------------
`HQ` | ×1.5 bitrate (max 320 kbps) | Highest quality
`MED` | ×1.0 | Balanced (default)
`LOW` | ×0.6 | Smaller files
`SIZE` | Uses base algorithm | Prioritizes final size

### 🔹 **Input modes**
- Single MP4 file  
- Folder containing multiple MP4 files

### 🔹 **Output directory support**
Optional `/out:"C:\path"` parameter.

### 🔹 **Colorized output**
- Modern ANSI escape sequences  
- Fallback to `color` for legacy support

### 🔹 **Environment validation**
The script **checks** for:
- `ffmpeg.exe`
- `ffprobe.exe`

If missing → stops with clear instructions.

---

# ✅ Requirements

| Component | Version |
|----------|---------|
| **Windows** | 10 or 11 |
| **FFmpeg suite** | Any recent build (ffmpeg & ffprobe required) |
| **Batch/Console** | ANSI-capable (Windows Terminal recommended) |

Download FFmpeg:  
➡ https://ffmpeg.org/download.html

---

# 🚀 Installation

1. Download the script:  
   `extractMP3Adv.cmd`

2. (Optional) Create a custom launcher icon  
   using the included `CreateLauncher.cmd`

3. Install FFmpeg and ensure it's available in `%PATH%`.

4. Run the script from any location.

---

# 🧠 Usage

### **Basic syntax**
```cmd
extractMP3Adv.cmd <input_path> [/mode:merge|split] [/preset:HQ|MED|LOW|SIZE] [/out:"folder"]
