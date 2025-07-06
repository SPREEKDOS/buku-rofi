# buku-rofi

A simple integration of [buku](https://github.com/jarun/buku) with [rofi](https://github.com/davatorium/rofi) to quickly search, edit, delete, and open your bookmarks from a rofi launcher interface.

## Features

- 🚀 Fuzzy search your `buku` bookmarks with the speed of `rofi`
- 🔗 Open bookmarks directly in your browser
- 🎨 Minimal, highly customizable interface via `rofi`
- 🧩 Robust dependency and version checks for trouble-free setup
- 🛠️ Graceful error messages and portable across major Linux distros

## Prerequisites

Make sure the following tools are installed and available in your `$PATH`:

- [`buku`](https://github.com/jarun/buku) — command-line bookmark manager
- [`rofi`](https://github.com/davatorium/rofi) — window switcher/launcher
- [`notify-send`](https://man7.org/linux/man-pages/man1/notify-send.1.html) — for desktop notifications
- [`awk`](https://www.gnu.org/software/gawk/) — for text processing
- [`fish`](https://fishshell.com/) — Version **2.7.0 or higher** recommended (some features require Fish 3+)

To install dependencies on popular distributions:

- **Debian/Ubuntu**:
  ```sh
  sudo apt install buku rofi notify-send awk fish
  ```
- **Arch Linux/Manjaro**:
  ```sh
  sudo pacman -S buku rofi libnotify gawk fish
  ```
- **Fedora**:
  ```sh
  sudo dnf install buku rofi libnotify gawk fish
  ```

## Installation

1. **Clone this repository:**
   ```fish
   git clone https://github.com/SPREEKDOS/buku-rofi.git
   cd buku-rofi
   ```

2. **Symlink the script for easier access in Fish shell** (required, as the script expects `buku-rofi.rasi` to be in the same directory):
   ```fish
   ln -s (pwd)/buku-rofi.fish ~/.config/fish/functions/buku-rofi.fish
   ```

## Usage

Launch the bookmark search interface with:

```fish
buku-rofi
```

- Type to search bookmarks.
- <kbd>Enter</kbd> to open the selected bookmark.
- All required dependencies and your Fish shell version will be checked automatically before launch.
- If a dependency is missing, you'll get a clear error and install suggestion based on your OS.

---

> **💡 TIP: Add a keybinding in your window manager to launch `buku-rofi` for instant access!**

---

## Keybindings

These are defined in `buku-rofi.rasi` and used by the script:

| Key                | Action                      |
|--------------------|----------------------------|
| <kbd>Alt+w</kbd>   | Show matching options      |
| <kbd>Alt+a</kbd>   | Add bookmark               |
| <kbd>Alt+q</kbd>   | Hide/show results          |
| <kbd>Delete</kbd>  | Delete bookmark            |
| <kbd>Insert</kbd>  | Edit bookmark              |
| <kbd>Alt+f</kbd>   | Auto filter                |
| <kbd>Alt+c</kbd>   | Copy bookmark URL          |
| <kbd>Alt+t</kbd>   | Search tags                |

You can customize these in `buku-rofi.rasi`.

## Import/Export

- Export: `buku-rofi --export` (defaults to `~/buku_export.json` if not set)
- Import: `buku-rofi --import` (defaults to `~/buku_export.json` if not set)

## Portability Notes

- Script checks and warns if your Fish version is below 2.7.0.
- Platform-aware install suggestions for missing dependencies.
- Most major Linux distros supported out-of-the-box.

## Example Demo

![buku-rofi-demo](docs/demo.gif)

## Troubleshooting

- Ensure all prerequisites are installed and working independently.
- If you see a missing dependency error, follow the suggested install command.

## Contributing

Pull requests, issues, and suggestions are welcome! Please open an issue to discuss your idea or bug.

## License

[MIT License](LICENSE)

---

Inspired by the productivity of the Linux CLI community. Happy bookmarking!
