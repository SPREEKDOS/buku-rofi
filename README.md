# buku-rofi

A simple integration of [buku](https://github.com/jarun/buku) with [rofi](https://github.com/davatorium/rofi) to quickly search, edit, delete, and open your bookmarks from a rofi launcher interface.

## Features

- 🚀 Fuzzy search your `buku` bookmarks with the speed of `rofi`
- 🔗 Open bookmarks directly in your browser
- 🎨 Minimal, highly customizable interface via `rofi`
## Prerequisites

Make sure the following tools are installed and available in your `$PATH`:

- [`buku`](https://github.com/jarun/buku) — command-line bookmark manager
- [`rofi`](https://github.com/davatorium/rofi) — window switcher/launcher
- [`notify-send`](https://man7.org/linux/man-pages/man1/notify-send.1.html) — for desktop notifications
- [`awk`](https://www.gnu.org/software/gawk/) — for text processing

You can install these on Debian/Ubuntu via:

```fish
sudo apt install buku rofi notify-send awk
```

## Installation

1. **Clone this repository:**
   ```fish
   git clone https://github.com/SPREEKDOS/buku-rofi.git
   cd buku-rofi
   ```

2. **Make the script executable:**
   ```fish
   chmod +x buku-rofi.fish
   ```

3. **(Optional) Copy or symlink for easier access in Fish shell:**
   symlink `buku-rofi.fish` into your Fish functions directory so you can run it as a command from anywhere:
   ```fish
   ln -s (pwd)/buku-rofi.fish ~/.config/fish/functions/buku-rofi.fish
   ```

## Usage

Run the following command to launch the bookmark search interface:

```fish
./buku-rofi.fish
# or, if symlinked
buku-rofi
```

- Type to search bookmarks.
- <kbd>Enter</kbd> to open the selected bookmark.

---

> **💡 TIP: For instant access, add a keybinding to your window manager to launch `buku-rofi`!**
>
> This lets you open your bookmarks launcher from anywhere with a single keyboard shortcut.

---

## Keybindings

- <kbd>Alt+W</kbd>: Show options
- <kbd>Alt+A</kbd>: Add bookmark
- <kbd>Alt+Q</kbd>: Hide listview
- <kbd>Delete</kbd>: Delete bookmark
- <kbd>Insert</kbd>: Edit bookmark

## Example Demo

![buku-rofi-demo](docs/demo.gif)

## Troubleshooting

- Ensure all prerequisites are installed and working independently.

## Contributing

Pull requests, issues, and suggestions are welcome! Please open an issue to discuss your idea or bug.

## License

[MIT License](LICENSE)

---

Inspired by the productivity of the Linux CLI community. Happy bookmarking!
