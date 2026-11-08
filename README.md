<p align="center"><img src="share/icons/hicolor/scalable/apps/lumen.svg" width="112" alt="lumen logo"></p>

# lumen

A lightweight desktop for **bspwm on X11**, built with [Quickshell](https://quickshell.outfoxxed.me).
One theme — seven accent colours in light and dark — applied to the shell, GTK 3, GTK 4/libadwaita, Qt and KDE apps, kitty and bspwm.

> **Status: stage 3 of 4.** Session, login and lock screens, installer, theme system, bar with
> quick settings, notifications, app launcher and Settings app. Coming next: shortcut viewer.

## Goals

- **Arch and Arch-based only, official repositories only.** No AUR helper needed.
- **Few dependencies.** Every package has a reason to be there (see [`packages/`](packages)).
- **Nothing breaks your system.** Replaced files are backed up; a dry run shows the plan first.

## Install

```sh
git clone https://github.com/spidtzz/lumen.git
cd lumen
./install.sh --dry-run     # see what will happen
./install.sh               # install
```

Reboot to reach the SDDM login screen and pick the **bspwm** session (lumen's; the
bspwm package's plain entry is hidden on lumen's login screen).
Without SDDM (`--dm none`), log in on tty1 (the installer can start the desktop automatically) or run `startx`.

| Option | Meaning |
| --- | --- |
| `--profile core\|recommended\|full` | Package set. `recommended` is the default. |
| `--fm dolphin\|nautilus\|none` | Also install a second file manager (Thunar is always installed). |
| `--dm sddm\|none` | Login screen. `sddm` by default, `none` with the core profile. |
| `--autostart` / `--no-autostart` | Without SDDM: start X automatically on tty1. |
| `--link` | Symlink configs to the repo instead of copying (for development). |
| `--no-packages` | Install config files only. |
| `-y`, `--yes` | Don't ask questions. |

Backups of anything replaced go to `~/.local/state/lumen/backups/<date>/`.

Apps included: **Thunar** for files (with thumbnails; trash and USB drives via gvfs in
the recommended profile), **Ristretto** for pictures and **mpv** for videos and music.
The installer makes them the default apps for those file types, unless you've already
chosen others in `~/.config/mimeapps.list`.

## Shortcuts

| Keys | Action |
| --- | --- |
| `super + Return` | Terminal (kitty) |
| `super + space` | App launcher |
| `super + v` | Clipboard history |
| `super + /` | Keyboard shortcuts (read from your sxhkdrc) |
| `Print` | Screenshot and recording panel |
| `super + shift + s` | Screenshot of a selection |
| `super + shift + r` | Start / stop recording the screen |
| `super + n` | Quick settings |
| `super + c` | Calendar |
| `super + shift + l` | Lock the screen |
| `super + p` | Session menu: lock, log out, suspend, restart, shut down |
| `super + i` | Settings |
| `super + e` | File manager (Thunar) |
| `super + q` | Close window |
| `super + 1…9, 0` / `super + shift + 1…9, 0` | Go to / send to desktop 1–10 |
| `super + h j k l` | Focus window in a direction |
| `super + a` / `super + d` | Previous / next desktop |
| `super + w` / `super + s` | Previous / next desktop with windows |
| `super + Tab` | Last desktop you used |
| `super + t` | Float the window, or tile it again |
| `super + f` | Fullscreen, or back again |
| `super + m` | Monocle layout |
| Volume, mute, mic, brightness, play/pause, next/previous keys | Work as labelled; volume and brightness show their level on screen |
| `super + Escape` | Reload shortcuts |
| `super + alt + r` / `super + alt + q` | Restart bspwm / log out |

The full list is in [`config/sxhkd/sxhkdrc`](config/sxhkd/sxhkdrc).

## The bar

`[launcher] app name ........ [workspaces] ........ [tray] [EN] [time] [quick settings]`

- **App name** — the class of the focused window, next to the launcher.
- **Launcher** — the lumen logo. Opens a Spotlight-style search: five apps at a time,
  smooth scrolling with the mouse, one row per arrow key, Enter to open. Apps you open
  often come first.
- **Workspaces** — a page at a time (5 by default): go to 7 and the bar shows 6–10.
- **Tray** — grouped like Windows (pinned icons on the bar, the rest behind an arrow) or
  every icon on the bar like GNOME and Plasma (Settings › Bar). Right-click an icon for
  **Pin to bar** and the app's own menu. Custom icons per app are in Settings › Bar.
- **Keyboard layout** — shows the active layout (EN, FA, ...). Click for the next one,
  right-click for the list. Hidden when only one layout is set up.
- **Time** — click for a calendar. Month and day names follow your regional settings.
- **Quick settings** — your picture, Settings, and a power menu (lock, log out, restart,
  shut down); toggles for Wi-Fi, Bluetooth, dark style, Do Not Disturb, performance
  mode and keep awake (no screen blanking or idle lock until you turn it off);
  right-click a toggle for its settings; volume and screen brightness; media controls
  for whatever is playing (MPRIS: music apps, browsers, mpv; can be turned off in
  Settings › Bar); and your notifications. Visual effects are in Settings › Performance.

The bar stays above windows (a small helper, `lumen-stack`, puts it back on top when
bspwm restacks), except over a fullscreen window. Popups and notifications are drawn
above all windows. Click elsewhere, or the same
button again, to close them. Notifications can appear in any corner or edge centre
(Settings › Notifications).
Scrolling over the workspaces switches desktops.

lumen is its own notification server, so no dunst or mako is needed.

## Screenshots and recording

`Print` opens a small panel: screenshot or recording, of the whole screen, the focused
window or a selection (drag, or click a window). Screenshots have an optional delay and
are copied to the clipboard; recordings can include sound. Files go to
`~/Pictures/Screenshots` and `~/Videos/Recordings`; a red dot in the bar shows a
recording in progress — click it to stop. Direct shortcuts: `super + shift + s`
(selection), `ctrl + Print` (screen), `alt + Print` (window), `super + shift + r`
(record). Uses maim, slop and gpu-screen-recorder, which falls back to CPU encoding
when there's no hardware encoder (for example in a VM).

## Keyboard shortcuts viewer

`super + /` lists the shortcuts from your own `~/.config/sxhkd/sxhkdrc`, grouped and
searchable, and updates when you save the file. A comment line directly above a binding
is its description; `# @group Name` starts a group. Bindings without a comment show
their command.

## Clipboard history

`super + v` opens your recent copies, text and images, with a full preview of the
selected one. Enter copies it back, Delete removes it. The newest 60 are kept in
`~/.cache/lumen/clipboard` (readable only by you); copies from password managers are
never kept, and history can be turned off in Settings › Users. Uses `clipnotify` and
`xclip` from the official repositories.

## Lock screen

Same design as the login screen, as a separate process from the bar. While it's up,
a small helper (`lumen-lock-grab`, using python-xlib) takes the whole keyboard and mouse
with an X grab: no shortcut, click or other window gets any input, and the bar and
notifications are hidden. Type your password and press Enter (Ctrl+U or
Ctrl+Backspace clears it; the layout switch keys work). If the lock screen ever stops
without your password, or can't take the keyboard, `i3lock` locks the screen instead.
It locks after the idle time set in Settings › Users and before suspend (via `xss-lock`).

```sh
lumen-lock --test     # try it safely: Esc closes it
```

## Keyboard layouts

Switching works like Windows: press and release **Alt+Shift** (or Ctrl+Shift, or Caps
Lock — your choice in Settings) without another key. Left or right keys, in any layout.
Because a third key cancels the switch, AltGr shortcuts such as Persian's half-space
(ZWNJ) and AltGr+Shift characters keep working. A small watcher (`lumen-settings
kbswitch`, using `xinput`) handles this instead of XKB's `grp:` options, which break
in layouts that use Right Alt for extra characters. The same watcher tells the shell
about mouse clicks while a bar popup is open, so clicking elsewhere closes it.

## Settings

| Page | What you can change | Uses |
| --- | --- | --- |
| Network | wired and Wi-Fi, connect with password | NetworkManager (nmcli) |
| Bluetooth | on/off, find, pair, connect, forget devices | BlueZ |
| Appearance | light/dark, accent, rounded or square corners, rounded screen corners, text size, focused window highlight, title-bar buttons | lumen-theme |
| Wallpaper | pictures from `~/Pictures/Wallpapers` (optionally its subfolders), system wallpapers or anywhere, or the theme colour; fill, fit, centre, tile, stretch | hsetroot |
| Bar | workspace style (pills, boxes, dots, numbers), floating or edge to edge (curved into rounded screen corners), black bar, edge, workspaces per page, clock, media controls, tray grouping, pinned and custom tray icons | |
| Displays | resolution, refresh rate, rotation, primary, arrangement — undone after 15 s unless kept | xrandr |
| Sound | output and input device, volume, mute, volume key step | PipeWire (built into Quickshell) |
| Keyboard & Mouse | up to four layouts (e.g. English + Persian) in order, switch keys, key repeat, focus follows mouse, pointer speed, natural scrolling, tap to click | setxkbmap, xset, xinput, bspwm |
| Date & Time | time zone, network time, 24-hour clock | timedatectl |
| Notifications | pop-up position, Do Not Disturb, clear history, test notification | |
| Performance | power mode, compositor, animations (shell and windows: open/close, switching desktops, moving/resizing), full speed for fullscreen apps, live processor and memory use | power-profiles-daemon, picom |
| Users | profile picture, password, lock after idle, test the lock screen, clipboard history | lumen-avatar, passwd, xss-lock |
| About | system details, copy to clipboard | |

Everything is stored in `~/.config/lumen/settings.conf` and applied again at login.
Settings is also in the app launcher. From a terminal:

```sh
lumen settings                           # open Settings (lumen settings display: a page)
lumen help                               # everything the lumen command can open
lumen-settings keys                      # every setting and its allowed values
lumen-settings set kb_layouts us,ir
lumen-settings set kb_switch alt_shift
qs -c lumen ipc call settings open display
```

System changes (time zone, login-screen picture) show a password prompt (polkit-gnome).

## Login screen and profile picture

The SDDM theme uses the same design and follows your theme: when you change the
accent or mode, the login screen matches it the next time it appears.
At the bottom: the session and user menus (with **Other user…** to type a user name
that isn't listed) on the left, and a power menu (suspend, hibernate, restart, shut down)
on the right. Caps Lock is shown under the password.

```sh
lumen-avatar set ~/Pictures/me.jpg   # desktop bar + login screen (asks for sudo once)
lumen-avatar clear                   # back to your initial in an accent circle
```

The picture is stored as `~/.face`. SDDM can't read your home folder, so a copy goes to
`/usr/share/sddm/faces/<user>.face.icon`.

Preview the login screen without logging out:

```sh
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/lumen
```

If another login manager is already enabled, the installer asks before replacing it.

## Theming

Your choices live in `~/.config/lumen/settings.conf`. Change them in Settings (Appearance, Bar) or:

```sh
lumen-theme set accent teal      # blue violet teal green orange pink mono
lumen-theme set mode light       # light dark
lumen-theme set bar_position left
lumen-theme set corners square   # rounded square
```

**Square corners** apply to the shell, GTK 3/4 and libadwaita apps (through `gtk.css`),
windows (picom) and the login screen. Qt apps use Qt's Fusion style, whose corners are
already nearly square, and there's no global setting to change them further.

The focused window is highlighted in the accent colour (Settings › Appearance › Windows):
with square corners by bspwm's outline, with rounded corners by a soft glow from picom
(bspwm's outline is a square frame picom can't round, so it would look cut at the
corners). Turned off, windows you're not using are slightly dimmed instead. picom runs
with `~/.local/state/lumen/picom.conf`, which includes your `~/.config/picom/picom.conf`
and adds these window rules.

File pickers (Open/Save dialogs) come from `xdg-desktop-portal-gtk` for every app
(`GTK_USE_PORTAL=1`), so they follow light/dark even in Firefox and Thunderbird.

`lumen-theme` writes:

| Target | How | Live? |
| --- | --- | --- |
| Quickshell | reads settings + palette files | yes |
| GTK 3 / plain GTK 4 | adw-gtk3 + named-colour overrides in `gtk.css` | yes, via xsettingsd |
| libadwaita (GTK 4) | same colours as CSS variables; light/dark and accent via the settings portal | light/dark yes, colours on next launch |
| Qt 6 | Qt's GTK3 theme (follows the GTK colours, reports light/dark to apps) | yes |
| KDE apps (Dolphin…) | `kdeglobals` colour scheme | on next launch |
| kitty | `theme.conf` | yes |
| bspwm | border colours | yes |
| SDDM | `theme.conf.user` in the theme folder (owned by you) | next time it appears |

Files it generates are marked at the top; if one existed before, it's kept once as `<file>.pre-lumen`.

Palettes are generated from the original oklch design values by `tools/gen-palettes.py`
(development only — Python isn't needed to use lumen).

## Layout

```
install.sh              installer
packages/               package lists per profile
bin/lumen               open Settings, the launcher, files... from a terminal
bin/lumen-settings      settings storage, validation and appliers
bin/lumen-theme         theme engine (bash)
bin/lumen-lock          lock screen launcher with i3lock fallback
bin/lumen-lock-grab     takes the keyboard and mouse while locked
bin/lumen-stack         keeps the bar above windows (not over fullscreen ones)
bin/lumen-clipboard     clipboard history
bin/lumen-capture       screenshots and recordings
bin/lumen-avatar        profile picture
bin/lumen-session       session start-up (SDDM and startx)
config/                 → ~/.config  (bspwm, sxhkd, picom, kitty, quickshell, portals)
home/xinitrc            → ~/.xinitrc
share/palettes/         → ~/.local/share/lumen/palettes
share/applications/     → ~/.local/share/applications (Settings in the launcher)
system/                 → system-wide: SDDM theme and config, session entry
assets/fonts/           Space Grotesk (OFL), fetched by tools/fetch-fonts.sh
tools/                  development helpers
```

## License

MIT. Space Grotesk is under the SIL Open Font License (see `assets/fonts/OFL.txt`).
