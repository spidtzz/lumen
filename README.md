<p align="center"><img src="share/icons/hicolor/scalable/apps/lumen.svg" width="112" alt="lumen logo"></p>

# lumen

A lightweight desktop for **bspwm on X11**, built with [Quickshell](https://quickshell.outfoxxed.me).
One theme — fourteen accent colours in light, dark and black, or picked from your
wallpaper — across the shell, GTK, libadwaita, Qt and KDE apps, kitty, the login and
lock screens, and optionally Firefox, LibreWolf, Discord, Telegram, Heroic, btop, fastfetch, fish and zathura.

- Arch and Arch-based distributions, **official repositories only**
- Few dependencies; every package is listed in [`packages/`](packages) with a reason
- Replaced files are backed up, and a dry run shows the plan first

## Install

```sh
git clone https://github.com/spidtzz/lumen.git
cd lumen
./install.sh --dry-run     # see what will happen
./install.sh
```

Reboot and pick the **bspwm** session on the login screen. Without SDDM
(`--dm none`), log in on tty1 or run `startx`.

| Option | Meaning |
| --- | --- |
| `--profile core\|recommended\|full` | Package set (default: `recommended`) |
| `--fm dolphin\|nautilus\|none` | A second file manager next to Thunar |
| `--dm sddm\|none` | Login screen (default: `sddm`) |
| `--autostart` / `--no-autostart` | Without SDDM: start X on tty1 automatically |
| `--link` | Symlink configs to the repo (for development) |
| `--no-packages` | Config files only |
| `-y`, `--yes` | Don't ask questions |

Backups go to `~/.local/state/lumen/backups/<date>/`. Thunar, Ristretto and mpv are
set as the default apps for files, pictures and media unless you've chosen others.

## Shortcuts

| Keys | Action |
| --- | --- |
| `super + Return` | Terminal |
| `super + x` | App launcher |
| `super + .` | Emoji picker |
| `super + e` | Files |
| `super + i` | Settings |
| `super + n` / `super + c` | Quick settings / calendar |
| `super + v` | Clipboard history |
| `super + shift + s`, `Print` | Screenshot and recording tool |
| `super + shift + r` | Start / stop recording the screen |
| `super + l` | Lock |
| `super + p` | Lock, log out, suspend, restart, shut down |
| `super + /` | All shortcuts |
| `super + q` | Close window |
| `super + 1…9, 0` / `+ shift` | Go to / move window to desktop |
| `super + a` / `super + d` | Previous / next desktop |
| `super + w` / `super + s` | Previous / next desktop with windows |
| `super + Tab` | Last desktop |
| `super + ← ↓ ↑ →` | Focus a window in that direction |
| `super + t` / `super + f` / `super + m` | Float, fullscreen, monocle |
| Media and brightness keys | Work as labelled, with an on-screen level |

`super + /` shows everything in your [`sxhkdrc`](config/sxhkd/sxhkdrc), grouped and
searchable. The comment above a binding is its description; `# @group Name` starts a group.

## Your own autostart, rules and shortcuts

Three files in `~/.config/lumen/` are yours. They start out as commented examples,
and lumen updates never change them:

| File | What it's for | Apply with |
| --- | --- | --- |
| `autostart` | programs to start at login | log in again |
| `rules` | which desktop an app opens on, tiled or floating, bspwm settings | `super + alt + r` |
| `keys` | your own shortcuts; one on lumen's keys replaces lumen's | `super + Escape` |

```sh
# in rules
bspc rule -a firefox desktop=^2 follow=on
bspc rule -a mpv state=floating center=on

# in keys
super + b
	firefox
```

## The bar

Launcher and focused app · workspaces · tray, keyboard layout, clock, quick settings.

- **Launcher**: search apps; the ones you open often come first.
- **Workspaces**: pills, boxes, dots or numbers; scroll to switch desktops.
- **Tray**: grouped behind an arrow like Windows, or all on the bar. Right-click an
  icon to pin it; custom icons per app in Settings › Bar.
- **Quick settings**: Wi-Fi, Bluetooth, dark style, Do Not Disturb, performance mode,
  keep awake, volume, brightness, media controls, notifications, and the battery on
  laptops. Right-click a tile for its settings.

The bar can sit on any edge, floating or edge to edge, and hides over fullscreen apps.
lumen is its own notification server.

## Screenshots and recording

`super + shift + s` (or `Print`) opens the capture tool. Pick **Area**, **Window** or
**Screen** and **photo or video** in the toolbar, then press the shutter or `Enter`.
Drag to select an area, drag inside it to move it and the corners to resize it; click a
window or the screen to take it. `Esc` cancels.

Screenshots always go to the clipboard. In the options choose **Copy** (clipboard only)
or **Copy & save** (also saved to `~/Pictures/Screenshots`), plus a delay and the mouse
pointer. Recordings go to `~/Videos/Captures`, with sound if you like; a red dot in the
bar shows a recording and stops it. The tool opens the way you left it.

## Laptops

The bar and quick settings show the battery charge and the time left. In
**Settings › Power** you choose what closing the lid does — on battery, plugged in, or
with an external monitor. lumen saves this as a system setting (after asking for your
password), so it applies on the login screen too.

## Settings

| Page | What you can change |
| --- | --- |
| Network, Bluetooth | connections and devices |
| Appearance | mode, accent (or from the wallpaper), corners, text size, window highlight, other apps |
| Wallpaper | pictures from `~/Pictures/Wallpapers` and its subfolders, or a colour |
| Bar | position, style, workspaces, clock, media controls, tray |
| Displays | resolution, refresh rate, rotation, arrangement |
| Sound | devices, volume, volume key step |
| Keyboard & Mouse | layouts and switch keys, key repeat, pointer, touchpad |
| Date & Time | time zone, network time, 24-hour clock |
| Notifications | position, Do Not Disturb |
| Power | battery, laptop lid, power mode, visual effects, usage |
| Users | profile picture, password, lock after idle, clipboard history |
| About | system details |

Everything is stored in `~/.config/lumen/settings.conf`. From a terminal:

```sh
lumen help                          # what the lumen command can open
lumen-settings keys                 # every setting and its allowed values
lumen-settings set accent teal
lumen-settings set mode light       # light, dark, black
lumen-settings set kb_layouts us,ir
```

## Theming other apps

Settings › Appearance › Other apps (experimental) writes a lumen theme for each app you
turn on, and removes it again when you turn it off:

- **Firefox, LibreWolf**: toolbar, tabs, menus and the new tab page; restart the browser.
- **Discord** through Vesktop, Vencord, Equicord or Equibop; updates live.
- **Telegram Desktop**: press **Open**, then **Apply** in Telegram; repeat after
  changing colours.
- **Heroic Games Launcher**: pick **lumen** in Heroic › Settings › Accessibility › Theme.
- **fish** (kitty opens it): lumen's prompt and colours. **fastfetch**: the lumen logo and your system details, shown each time a terminal opens. Both are on by default.
- **btop**, **zathura**: reopen them to see changes.

GTK, libadwaita, Qt and KDE apps, kitty and file pickers follow the theme on their own.

## Lock and login screens

The lock screen takes the whole keyboard and mouse while it's up, and falls back to
`i3lock` if anything goes wrong. It locks after the idle time from Settings › Users and
before suspend. Try it safely with `lumen-lock --test` (`Esc` closes it).

The SDDM login screen has the same design and colours, a user switcher with
**Other user…**, and session and power menus.

```sh
lumen-avatar set ~/Pictures/me.jpg   # profile picture for the bar and the login screen
```

## Keyboard layouts

Switch layouts like on Windows: press and release **Alt+Shift** (or Ctrl+Shift, or Caps
Lock), or use **Super+Space** or a shortcut of your own (Settings › Keyboard & Mouse). AltGr characters, such as the Persian half-space, keep working.

## Fonts

**IBM Plex Sans** for the interface and **JetBrains Mono** for the terminal, both from the
Arch repositories (`ttf-ibm-plex`, `ttf-jetbrains-mono`). Noto covers other scripts.

## Quickshell won't start

`quickshell: symbol lookup error ... Qt_6_PRIVATE_API` means Quickshell was built for a
different Qt version than the one installed. It uses Qt's private API, so it must be
rebuilt for every Qt update. First update everything with `sudo pacman -Syu`. If it still
fails, your repository hasn't rebuilt it yet (this happens on CachyOS); rebuild Arch's
package yourself:

```sh
sudo pacman -S --needed base-devel git
git clone https://gitlab.archlinux.org/archlinux/packaging/packages/quickshell.git
cd quickshell && makepkg -si
```

If Quickshell came from the AUR (`quickshell-git`), rebuild that instead, e.g.
`paru -S --rebuild quickshell-git`.

## Layout

```
install.sh      installer
packages/       package lists per profile
bin/            lumen, lumen-settings, lumen-theme, lumen-capture, lumen-lock, ...
config/         → ~/.config (bspwm, sxhkd, picom, kitty, quickshell)
share/          → ~/.local/share (palettes, launcher entry, icon)
system/         SDDM theme and session entry (installed system-wide)
tools/          development helpers
```

## License

MIT.
