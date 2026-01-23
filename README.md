# VLC Logo Remover - Windows Batch Script

## Description
Windows batch script that automates logo/overlay removal from videos using FFmpeg's delogo filter. Optimized for NotebookLM "Overview" videos but customizable for any video source.

## Features
- Dynamic logo removal for logos that change position during playback
- Flexible configuration with adjustable coordinates and timing
- Smart duplicate handling (overwrite, create numbered version, or cancel)
- VLC integration for automatic result preview
- Interactive command-line interface
- Edge correction for smooth results

## Requirements
- **FFmpeg** - must be installed and in system PATH
- **VLC Media Player** (optional, for automatic playback)

## Installation
1. Clone or download this repository
2. Ensure FFmpeg is installed: `ffmpeg -version`
3. Place `vlc-logo.cmd` in a directory in your PATH or use it directly

## Usage

### Basic Command
```batch
vlc-logo "path\to\video.mp4"
```

### Parameters
```
TEXT FILE INPUT          Video file path (use quotes for paths with spaces)
/CORR value              Pixel correction offset (default: 3)
/T1 seconds              Time when logo changes position (default: 23.5)

COORDINATE PARAMETERS (optional - override defaults):
/X1, /Y1, /W1, /H1       Initial area (from 0 to T1 seconds)
/X2, /Y2, /W2, /H2       Final area (from T1 seconds onward)
```

### Examples

**Standard usage with default values:**
```batch
vlc-logo "C:\Videos\presentation.mp4"
```

**With 1-pixel correction:**
```batch
vlc-logo "video.mp4" /CORR 1
```

**Custom time and coordinates:**
```batch
vlc-logo "video.mp4" /T1 15.0 /X1 800 /Y1 600
```

**Full parameter specification:**
```batch
vlc-logo "C:\video.mp4" /T1 23.5 /CORR 0 /X1 862 /Y1 626 /W1 227 /H1 31 /X2 1102 /Y2 661 /W2 133 /H2 16
```

## Default Configuration
The script comes pre-configured for NotebookLM "Overview" videos:
- **From 0 to 23.5 seconds**: Logo at position (862,626) with size 227×31
- **After 23.5 seconds**: Logo moves to (1102,661) with size 133×16
- **Correction offset**: 3 pixels (expands area for better coverage)

## How It Works
1. **Input validation** - Checks for FFmpeg and input file
2. **Duplicate handling** - Interactive menu if output exists
3. **Area calculation** - Applies offset correction to coordinates
4. **FFmpeg processing** - Uses delogo filter with time-based enable conditions
5. **Optional preview** - Opens result in VLC if requested

## Technical Details
The script creates an FFmpeg command similar to:
```bash
ffmpeg -i "input.mp4" -vf "delogo=x=859:y=623:w=233:h=37:enable='between(t,0,23.5)',delogo=x=1099:y=658:w=139:h=22:enable='gt(t,23.5)'" -c:a copy -y "output.mp4"
```

## Troubleshooting

### Common Issues
1. **"FFmpeg not found"**  
   Solution: Install FFmpeg and add to PATH

2. **"File not found"**  
   Solution: Use full paths and quotes for paths with spaces

3. **Poor logo removal quality**  
   Solution: Adjust `/CORR` value (try 1-5) and check coordinates

4. **Incorrect timing**  
   Solution: Use `/T1` to set the exact time the logo changes position

### Finding Coordinates
Use a screen capture tool or video editor to:
1. Pause video at logo appearance
2. Note the X,Y coordinates of the logo's top-left corner
3. Measure the width (W) and height (H) of the logo

## License
MIT License - see LICENSE file for details

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Support
For issues or questions:
1. Check the troubleshooting section
2. Open a GitHub issue with:
   - Command used
   - Error messages
   - System information

---

**Note**: Always test on copies of original videos. Results may vary depending on video quality and logo characteristics.
