# MP4 to MP3 Batch Converter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform: Windows](https://img.shields.io/badge/Platform-Windows-blue.svg)

A robust Windows batch script that merges multiple MP4 files into a single MP3 audio file with automatic bitrate optimization to fit specific size constraints.

## ✨ Features

* **Automatic Bitrate Calculation**: Dynamically calculates the optimal bitrate to target a ~199MB output (ideal for platforms with file size limits).
* **Smart Merging**: Concatenates multiple MP4 files while preserving audio quality.
* **Timestamp Organization**: Output files are automatically named with a timestamp (`YYYYMMDD_hhmmss`) for easy versioning.
* **Error Handling**: Comprehensive checks for dependencies, directory existence, and file validity.
* **Debug Mode**: Optional verbose output for troubleshooting internal logic.

## 📋 Prerequisites

1.  **FFmpeg & FFprobe**: [Download from ffmpeg.org](https://ffmpeg.org/).
    * The folder must include both `ffmpeg.exe` and `ffprobe.exe`.
    * **Important**: Add the FFmpeg `bin` folder to your system **PATH** for global access.

## 🚀 Installation

1.  Download the script `mp4-to-mp3.cmd` to your preferred directory.
2.  Create a folder named `mp4b` in the same directory as the script.
3.  Place all MP4 files you wish to merge inside the `mp4b` folder.

## 🛠 Usage

### Basic Execution
Simply double-click the script or run it from the terminal:
```bash
mp4-to-mp3.cmd

```

### The Process

1. **File Analysis**: Scans the `mp4b` folder for valid MP4 files.
2. **Duration Calculation**: Uses `ffprobe` to calculate the total duration of all clips.
3. **Bitrate Optimization**: Automatically scales bitrate between **32kbps** and **128kbps**.
4. **File Merging**: Concatenates all files into a single high-quality MP3.
5. **Output**: Generates a timestamped file (e.g., `20240123_143022_source.mp3`) in the root directory.

## ⚙️ Configuration

### Directory Logic

* **Source Folder**: Default is `mp4b`. Ensure this folder exists next to the script.
* **Target Size**: The script targets ~199MB. Bitrate is adjusted based on total duration.

### Debug Mode

To troubleshoot, enable debug mode by changing line 8 in the `.cmd` file:

```batch
set "debugging=true"

```

## 🔍 Technical Details

### Bitrate Formula

The script uses the following logic to determine audio quality:


* **Max Bitrate**: 128 kbps
* **Min Bitrate**: 32 kbps

### Core FFmpeg Command

```bash
ffmpeg -f concat -safe 0 -i "filelist.txt" -b:a [calculated_bitrate]k output.mp3

```

## ❓ Troubleshooting

| Issue | Solution |
| --- | --- |
| **FFmpeg not found** | Verify FFmpeg is in your system PATH. Restart the terminal. |
| **No MP4 files found** | Ensure the folder is named exactly `mp4b` and contains `.mp4` files. |
| **Merge fails/Empty file** | Verify that the MP4 files actually contain an audio stream. |
| **Output too large** | Adjust the target size constant in the script (line with `target_bitrate`). |

## 📂 Project Structure

```text
mp4-to-mp3-converter/
├── mp4-to-mp3.cmd      # Main script
├── mp4b/               # Source MP4 files folder
├── README.md           # Documentation
├── LICENSE             # MIT License
└── .gitignore          # Version control exclusions

```

## 🤝 Contributing

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

**Note:** *Always test with backup copies of your original files. The script is provided "as is" without warranty.*

```

---

### Cosa è stato migliorato per GitHub:
1.  **Badge**: Aggiunti badge per licenza e piattaforma (rendono il progetto più professionale).
2.  **Emoji**: Usate con moderazione per guidare l'occhio tra le sezioni (`✨`, `🚀`, `📋`).
3.  **LaTeX**: Ho formattato la formula del bitrate usando i tag `$$` per una resa matematica perfetta su GitHub.
4.  **Tabelle**: Sostituito il testo del troubleshooting con una tabella, molto più leggibile.
5.  **Blocchi di codice**: Specificato il linguaggio (`bash`, `batch`, `text`) per abilitare l'evidenziazione della sintassi (syntax highlighting).
6.  **Gerarchia dei titoli**: Sistemati i livelli `h1`, `h2`, `h3` per generare correttamente l'indice automatico di GitHub.

**Desideri che aggiunga anche una sezione "Changelog" o dei suggerimenti su come automatizzare ulteriormente lo script?**

```
