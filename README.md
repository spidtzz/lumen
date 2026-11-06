# lumen

A lightweight desktop for **bspwm on X11**, built with [Quickshell](https://quickshell.outfoxxed.me).
One theme — seven accent colours in light and dark — applied to the shell, GTK 3, GTK 4/libadwaita, Qt and KDE apps, kitty and bspwm.

> **Status: stage 1 of 4.** Session, login screen, installer, theme system and a basic bar work.
> Coming next: app launcher, notifications, shortcut viewer, Settings app.

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

Reboot to reach the SDDM login screen and pick the **lumen** session.
Without SDDM (`--dm none`), log in on tty1 (the installer can start the desktop automatically) or run `startx`.

| Option | Meaning |
| --- | --- |
| `--profile core\|recommended\|full` | Package set. `recommended` is the default. |
| `--fm dolphin\|nautilus\|none` | Install and theme a file manager. |
| `--dm sddm\|none` | Login screen. `sddm` by default, `none` with the core profile. |
| `--avatar <image>` | Profile picture (PNG or JPEG). Asked for when interactive. |
| `--autostart` / `--no-autostart` | Without SDDM: start X automatically on tty1. |
| `--link` | Symlink configs to the repo instead of copying (for development). |
| `--no-packages` | Install config files only. |
| `-y`, `--yes` | Don't ask questions. |

Backups of anything replaced go to `~/.local/state/lumen/backups/<date>/`.

## Shortcuts

| Keys | Action |
| --- | --- |
| `super + Return` | Terminal (kitty) |
| `super + q` | Close window |
| `super + 1…9` / `super + shift + 1…9` | Go to / send to desktop |
| `super + h j k l` | Focus window in a direction |
| `super + t / s / f` | Tiled / floating / fullscreen |
| `super + m` | Monocle layout |
| `super + shift + d` | Light ↔ dark |
| `super + shift + a` | Next accent colour |
| `super + shift + arrows` | Move the bar to that edge |
| `super + Escape` | Reload shortcuts |
| `super + alt + r` / `super + alt + q` | Restart bspwm / log out |

The full list is in [`config/sxhkd/sxhkdrc`](config/sxhkd/sxhkdrc).

## Login screen and profile picture

The SDDM theme uses the same design and follows your theme: when you change the
accent or mode, the login screen matches it the next time it appears.
It offers user and session pickers, Caps Lock warning, and suspend/restart/shut down.

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

Your choices live in `~/.config/lumen/settings.conf`. Change them with the shortcuts above or:

```sh
lumen-theme set accent teal      # blue violet teal green orange pink mono
lumen-theme set mode light       # light dark
lumen-theme set bar_position left
```

`lumen-theme` writes:

| Target | How | Live? |
| --- | --- | --- |
| Quickshell | reads settings + palette files | yes |
| GTK 3 / plain GTK 4 | adw-gtk3 + named-colour overrides in `gtk.css` | yes, via xsettingsd |
| libadwaita (GTK 4) | same colours as CSS variables; light/dark and accent via the settings portal | light/dark yes, colours on next launch |
| Qt 6 | qt6ct palette (Fusion style) | on next launch |
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
bin/lumen-theme         theme engine (bash)
bin/lumen-avatar        profile picture
bin/lumen-session       session start-up (SDDM and startx)
config/                 → ~/.config  (bspwm, sxhkd, picom, kitty, quickshell, portals)
home/xinitrc            → ~/.xinitrc
share/palettes/         → ~/.local/share/lumen/palettes
system/                 → system-wide: SDDM theme and config, session entry
assets/fonts/           Space Grotesk (OFL), fetched by tools/fetch-fonts.sh
tools/                  development helpers
```

## License

MIT. Space Grotesk is under the SIL Open Font License (see `assets/fonts/OFL.txt`).
