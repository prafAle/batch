# 🎧 extractMP3Adv — Advanced MP4 → Audio Extractor (Windows Batch Script)

`extractMP3Adv.cmd` is an **advanced Windows batch script** designed to extract high‑quality audio from MP4 video files and convert it to **MP3, AAC, or OPUS**.

The script supports **single-file extraction**, **folder-based split**, and **merge operations**, with a strong focus on **speech‑oriented content** such as meetings, calls, interviews, and podcasts.

This version is an **evolution of the original tool**, preserving proven legacy features (dynamic bitrate calculation for merge operations, presets, validation) and integrating modern, speech‑optimized behavior such as automatic silence removal.

---

## ✨ Key Highlights

- Automatic mode detection (SINGLE / SPLIT / MERGE)
- Speech‑optimized silence removal (SINGLE & SPLIT)
- Dynamic bitrate engine for MERGE (target size ~199 MB)
- Quality presets: HQ / MED / LOW / SIZE
- Codec‑aware bitrate selection (MP3 / AAC / OPUS)
- Explicit multi‑threaded encoding (`-threads 0`)
- Built‑in FFmpeg and FFprobe validation
- Optional output directory support
- ANSI‑colored console UI
- Detailed runtime summary with file size and duration

> **Note:** Logging is console‑only. No log files are created.

---

## 🎯 Ideal Use Cases

- Meeting and conference recordings  
- Podcast creation from video sources  
- Interview and spoken‑word archiving  
- Bulk MP4 → audio extraction  
- Size‑constrained audio merging  

---

## 📦 Features

### 🔹 Operating Modes

| Mode   | Description |
|-------|-------------|
| SINGLE | One MP4 → one audio file (auto‑selected) |
| SPLIT  | Folder → one audio file per MP4 |
| MERGE  | Folder → all MP4 files merged into one audio file |

The mode is **automatically resolved** based on the input, but can be overridden with `/mode`.

---

### 🔹 Silence Removal (Speech‑Optimized)

- Enabled **by default**
- Automatically applied in:
  - SINGLE
  - SPLIT
- Not applied in:
  - MERGE

Silence trimming removes long pauses while preserving natural speech flow, making the output ideal for listening and transcription.

---

### 🔹 Audio Codecs

| Codec | Description |
|------|-------------|
| mp3  | Universal compatibility (default) |
| aac  | Better quality at lower bitrates (output `.m4a`) |
| opus | Best efficiency for speech |

---

### 🔹 Presets & Bitrate Logic

#### SINGLE / SPLIT (Static, Speech‑Optimized)

| Preset | Behavior |
|-------|----------|
| LOW   | Smaller files, lower bitrate |
| MED   | Balanced quality (default) |
| HQ    | Higher quality |
| SIZE  | Treated as MED |

Bitrates are **codec‑aware** (e.g. OPUS uses much lower values than MP3 for similar perceived quality).

---

#### MERGE (Dynamic Bitrate Engine)

In **MERGE mode only**, bitrate is calculated dynamically to keep the final file close to **~199 MB**, based on:

- total duration of all input MP4 files (via `ffprobe`)
- selected preset multiplier

| Preset | MERGE Behavior |
|-------|----------------|
| LOW   | Dynamic bitrate × 0.6 |
| MED   | Dynamic bitrate × 1.0 |
| HQ    | Dynamic bitrate × 1.5 (capped at 320 kbps) |
| SIZE  | Pure size‑optimized dynamic bitrate (ignores others) |

This ensures predictable output size for long merged recordings.

---

## ✅ Requirements

| Component | Requirement |
|----------|------------|
| Operating System | Windows 10 or Windows 11 |
| FFmpeg | Required |
| FFprobe | Required |
| Console | ANSI‑capable (Windows Terminal recommended) |

Download FFmpeg from:  
https://ffmpeg.org/download.html

Both `ffmpeg.exe` and `ffprobe.exe` must be available in the system `PATH`.

---

## 🚀 Usage

### Basic Syntax

```cmd
extractMP3Adv.cmd <input_path> [/mode:merge|split] [/preset:HQ|MED|LOW|SIZE] [/codec:mp3|aac|opus] [/out:"folder"]
`<input_path>` can be:
- a single MP4 file
- a folder containing MP4 files

---

### Examples

#### Single file

```cmd
extractMP3Adv video.mp4
extractMP3Adv video.mp4 /preset:LOW
extractMP3Adv video.mp4 /codec:opus
Split mode
BATextractMP3Adv D:\Videos /mode:splitextractMP3Adv D:\Videos /mode:split /preset:HQextractMP3Adv D:\Videos /mode:split /codec:aac /out:"D:\Audio"Mostra più linee
Merge mode (dynamic bitrate)
BATextractMP3Adv D:\Videos /mode:mergeextractMP3Adv D:\Videos /mode:merge /preset:HQMostra più linee
Size‑optimized merge
BATextractMP3Adv D:\Videos /mode:merge /preset:SIZEextractMP3Adv D:\Videos /mode:merge /preset:SIZE /codec:opusMostra più linee

📊 Runtime Summary
At the end of execution, the script prints a detailed summary including:

resolved mode
selected codec and preset
effective bitrate
output directory
generated files with:

final file size
audio duration



Example:
[53,5MB 01:04:00] 20260421_152110_MeetingAudio.mp3


🧠 Design Notes

Uses explicit multi‑threaded encoding (-threads 0)
Dynamic merge bitrate uses integer‑safe arithmetic
ffprobe is required for duration analysis
Long silence removal is disabled in MERGE mode to avoid timeline distortion
No background services or persistent temporary files are used
Console output is the only logging mechanism


📄 License
MIT License — free for personal and commercial use.
