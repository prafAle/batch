# Batch Script Collection

A professional collection of automation tools for media processing, optimized for Windows environments using FFmpeg.

---

## 📂 Project Overview

This repository contains specialized scripts for video and audio manipulation. Each tool is self-contained in its own directory with specific documentation.

## 🛠 Global Prerequisites

### 1. [🎵 MP3extract](./MP3extract/)
**Quick batch conversion from MP4 to MP3.**
- **Primary Use**: Merges multiple video files into a single optimized audio track.
- **Key Feature**: Automatic bitrate calculation to stay under 200MB.
- **Status**: Stable / Production Ready.
- [Read full documentation →](./MP3extract/README.md)

### 2. [🎬 ffmpegLogoRemover](./ffmpegLogoRemover/)
**Automated watermark and logo removal from video files.**
- **Primary Use**: Cleaning videos by applying delogo filters via FFmpeg.
- **Key Feature**: Batch processing of entire directories with a single command.
- **Status**: Active Development.
- [Read full documentation →](./ffmpegLogoRemover/README.md)

## 🛠 Global Prerequisites

To use any of the scripts in this repository, ensure you have:

1.  **Windows 10/11**
2.  **FFmpeg** (Added to your system PATH)
    - Verify with: `ffmpeg -version`
3.  **PowerShell 7** (Recommended for advanced terminal features)

## 🚀 How to use this Repo

1.  **Clone the repository**:
    ```bash
    git clone [https://github.com/YourUsername/batch.git](https://github.com/YourUsername/batch.git)
    ```
2.  Navigate to the specific tool folder you need.
3.  Follow the instructions in the local `README.md` of that folder.

---

---

**Author**: prafAle
**License**: MIT
