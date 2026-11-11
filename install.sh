#!/usr/bin/env bash
# lumen installer — Arch Linux and Arch-based distributions.
#
#   ./install.sh --dry-run          show what would happen, change nothing
#   ./install.sh                    install (recommended profile)
#
# Options:
#   --profile core|recommended|full   package set (default: recommended)
#   --fm dolphin|nautilus|none        a second file manager (Thunar is always installed)
#   --dm sddm|none                    login screen (default: sddm, none for core)
#   --autostart / --no-autostart      without SDDM: start X automatically on tty1
#   --link                            symlink configs to this repo (for development)
#   --no-packages                     only install config files
#   --dry-run                         print the plan without changing anything
#   -y, --yes                         don't ask questions; use defaults
#   -h, --help                        show this help
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NAME=lumen
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
BACKUP=$STATE_HOME/$NAME/backups/$(date +%Y%m%d-%H%M%S)

PROFILE=recommended FM=none DM=auto AUTOSTART=ask LINK=0 PACKAGES=1 DRY=0 YES=0

# ---------------------------------------------------------------- helpers
c_blue=$'\e[1;34m' c_yellow=$'\e[1;33m' c_red=$'\e[1;31m' c_dim=$'\e[2m' c_off=$'\e[0m'
[[ -t 1 ]] || c_blue='' c_yellow='' c_red='' c_dim='' c_off=''
log() { printf '%s::%s %s\n' "$c_blue" "$c_off" "$*"; }
warn() { printf '%s!!%s %s\n' "$c_yellow" "$c_off" "$*" >&2; }
die() { printf '%serror:%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }
run() {
	if ((DRY)); then printf '   %s[dry-run]%s %s\n' "$c_dim" "$c_off" "$*"; else "$@"; fi
}
ask() { # ask "question" default(y/n)
	local reply def=$2
	((YES)) || [[ ! -t 0 ]] && { [[ $def == y ]]; return; }
	read -rp "$1 [$([[ $def == y ]] && echo Y/n || echo y/N)] " reply
	reply=${reply:-$def}
	[[ ${reply,,} == y* ]]
}
usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

# ---------------------------------------------------------------- arguments
while (($#)); do
	case $1 in
		--profile) PROFILE=${2:-}; shift ;;
		--profile=*) PROFILE=${1#*=} ;;
		--fm) FM=${2:-}; shift ;;
		--fm=*) FM=${1#*=} ;;
		--dm) DM=${2:-}; shift ;;
		--dm=*) DM=${1#*=} ;;
		--autostart) AUTOSTART=yes ;;
		--no-autostart) AUTOSTART=no ;;
		--link) LINK=1 ;;
		--no-packages) PACKAGES=0 ;;
		--dry-run) DRY=1 ;;
		-y | --yes) YES=1 ;;
		-h | --help) usage ;;
		*) die "unknown option: $1 (see --help)" ;;
	esac
	shift
done
[[ $PROFILE =~ ^(core|recommended|full)$ ]] || die "--profile must be core, recommended or full"
[[ $FM =~ ^(thunar|dolphin|nautilus|none)$ ]] || die "--fm must be dolphin, nautilus or none"
[[ $FM == thunar ]] && FM=none   # always installed
[[ $DM =~ ^(auto|sddm|none)$ ]] || die "--dm must be sddm or none"
[[ $DM == auto ]] && { [[ $PROFILE == core ]] && DM=none || DM=sddm; }

# ---------------------------------------------------------------- checks
preflight() {
	[[ $EUID -ne 0 || -n ${LUMEN_ALLOW_ROOT:-} ]] || die "run as your normal user; sudo is used only for pacman"
	if [[ -z ${LUMEN_SKIP_OS_CHECK:-} ]]; then
		[[ -r /etc/os-release ]] || die "can't read /etc/os-release"
		# Read os-release in a subshell: it defines NAME, ID, VERSION... which
		# would otherwise overwrite this script's own variables.
		local os_id os_like os_pretty
		# shellcheck disable=SC1091
		IFS='|' read -r os_id os_like os_pretty < <(. /etc/os-release && printf '%s|%s|%s\n' "${ID:-}" "${ID_LIKE:-}" "${PRETTY_NAME:-unknown}")
		[[ $os_id == arch || " $os_like " == *" arch "* ]] ||
			die "lumen supports Arch Linux and Arch-based distributions (found: $os_pretty)"
		command -v pacman >/dev/null || die "pacman not found"
	fi
	((PACKAGES == 0)) && [[ $DM == none ]] || command -v sudo >/dev/null || die "sudo is required (packages and login screen)"
	if ((DRY)); then log "Dry run: nothing will be changed."; fi
	if command -v git >/dev/null && git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
		log "Installing lumen $(git -C "$REPO" log -1 --format='%h (%cd)' --date=short)"
		local changed
		changed=$(git -C "$REPO" status --porcelain 2>/dev/null)
		if [[ -n $changed ]]; then
			warn "this folder has local changes that differ from GitHub:"
			printf '%s\n' "$changed" | head -10 >&2
			warn "to match GitHub exactly: git fetch && git reset --hard origin/main"
		fi
	fi
}

read_list() { # read_list core -> package names, comments stripped
	local line
	while read -r line || [[ -n $line ]]; do
		line=${line%%#*}
		line=${line//[[:space:]]/}
		[[ -n $line ]] && printf '%s\n' "$line"
	done <"$REPO/packages/$1.txt"
}

# ---------------------------------------------------------------- packages
install_packages() {
	((PACKAGES)) || { log "Skipping packages (--no-packages)."; return 0; }
	local pkgs=()
	mapfile -t pkgs < <(read_list core)
	[[ $PROFILE == core ]] || mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list recommended)
	[[ $PROFILE == full ]] && mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list full)
	case $FM in
		dolphin) pkgs+=(dolphin breeze-icons) ;;
		nautilus) pkgs+=(nautilus) ;;
	esac
	[[ $DM == sddm ]] && pkgs+=(sddm)
	# Only a fallback: skip it when an emoji font is already installed
	# (Apple Color Emoji, Twemoji, JoyPixels...).
	if command -v fc-list >/dev/null && [[ -n $(fc-list ':charset=1f600' family 2>/dev/null) ]]; then
		local p kept=()
		for p in "${pkgs[@]}"; do [[ $p == noto-fonts-emoji ]] || kept+=("$p"); done
		pkgs=("${kept[@]}")
	fi
	if command -v systemd-detect-virt >/dev/null && systemd-detect-virt -q; then
		log "Virtual machine detected: adding spice-vdagent."
		pkgs+=(spice-vdagent)
	fi

	local missing=()
	if command -v pacman >/dev/null; then
		mapfile -t missing < <(pacman -T "${pkgs[@]}" 2>/dev/null || true)
	else
		missing=("${pkgs[@]}")
	fi
	log "Profile '$PROFILE': ${#pkgs[@]} packages, ${#missing[@]} to install."
	if ((${#missing[@]})); then
		printf '   %s\n' "${missing[*]}"
		# -Syu, never -S alone: installing a newer package on a system that
		# isn't up to date is a partial upgrade, and Quickshell (built against
		# Qt's private API) then fails with "undefined symbol ... Qt_6_PRIVATE_API".
		log "Updating the system first (pacman -Syu), so the new packages match it."
		local flags=(-Syu --needed)
		((YES)) && flags+=(--noconfirm)
		run sudo pacman "${flags[@]}" "${missing[@]}"
	fi

	if [[ " ${pkgs[*]} " == *" spice-vdagent "* ]]; then
		run sudo systemctl enable --now spice-vdagentd.socket ||
			run sudo systemctl enable --now spice-vdagentd.service ||
			warn "couldn't enable spice-vdagentd; clipboard sharing may not work"
	fi

	# Bluetooth and power profiles (Quick Settings), when installed.
	local svc
	for svc in bluetooth power-profiles-daemon; do
		if [[ " ${pkgs[*]} " == *" ${svc/bluetooth/bluez} "* ]] || systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
			systemctl is-enabled -q "$svc.service" 2>/dev/null ||
				run sudo systemctl enable --now "$svc.service" || warn "couldn't enable $svc"
		fi
	done
}

# ---------------------------------------------------------------- files
# Move an existing path into the backup folder, keeping its layout.
backup() {
	local dst=$1 rel
	[[ -e $dst || -L $dst ]] || return 0
	rel=${dst#"$HOME"/}
	run mkdir -p "$(dirname "$BACKUP/$rel")"
	run mv "$dst" "$BACKUP/$rel"
	BACKED_UP=1
}

# Install one file (copy mode) or one path (link mode).
place() {
	local src=$1 dst=$2
	if ((LINK)); then
		[[ -L $dst && $(readlink "$dst") == "$src" ]] && return
		backup "$dst"
		run mkdir -p "$(dirname "$dst")"
		run ln -s "$src" "$dst"
	else
		[[ -f $dst && ! -L $dst ]] && cmp -s "$src" "$dst" && return
		backup "$dst"
		run mkdir -p "$(dirname "$dst")"
		run cp -p "$src" "$dst"
	fi
}

# Copy mode installs each file; link mode links each top-level folder so new
# files from `git pull` appear without reinstalling.
place_tree() {
	local srcroot=$1 dstroot=$2
	local entry f
	for entry in "$srcroot"/*; do
		[[ -e $entry ]] || continue
		if ((LINK)) && [[ -d $entry && ${entry##*/} == quickshell ]]; then
			place_tree "$entry" "$dstroot/quickshell" # don't take over other shells
		elif ((LINK)) || [[ -f $entry ]]; then
			place "$entry" "$dstroot/${entry##*/}"
		else
			while IFS= read -r -d '' f; do
				place "$f" "$dstroot/${f#"$srcroot"/}"
			done < <(find "$entry" -type f -print0)
		fi
	done
}

# The fonts (IBM Plex Sans, JetBrains Mono) come from the Arch repositories.
# Older lumen versions downloaded Space Grotesk into ~/.local/share/fonts/lumen
# and set it in settings.conf: switch those over.
migrate_fonts() {
	if [[ -d $DATA_HOME/fonts/$NAME ]]; then
		run rm -rf "$DATA_HOME/fonts/$NAME"
		command -v fc-cache >/dev/null && run fc-cache -f "$DATA_HOME/fonts" >/dev/null || true
	fi
	local conf=$CONFIG_HOME/$NAME/settings.conf
	if [[ -f $conf ]] && grep -qx 'font=Space Grotesk' "$conf"; then
		run sed -i 's/^font=Space Grotesk$/font=IBM Plex Sans/' "$conf"
	fi
}

install_files() {
	log "Installing configuration ($( ((LINK)) && echo "linked to $REPO" || echo copied))..."
	BACKED_UP=0
	place_tree "$REPO/config" "$CONFIG_HOME"
	run chmod +x "$REPO/config/bspwm/bspwmrc"
	place_tree "$REPO/bin" "$HOME/.local/bin"
	place_tree "$REPO/share/palettes" "$DATA_HOME/$NAME/palettes"
	place_tree "$REPO/share/fastfetch" "$DATA_HOME/$NAME/fastfetch"   # fastfetch logo
	place_tree "$REPO/share/applications" "$DATA_HOME/applications"   # Settings in the app launcher
	place_tree "$REPO/share/icons" "$DATA_HOME/icons"                 # its icon
	place "$REPO/home/xinitrc" "$HOME/.xinitrc"
	migrate_fonts

	# Default cursor for the X root window and apps that don't read XSETTINGS
	# (both places apps look). Without this, distributions that ship another
	# default (CachyOS) show a different pointer over some windows.
	local d
	for d in "$HOME/.icons/default" "$DATA_HOME/icons/default"; do
		if [[ $(cat "$d/index.theme" 2>/dev/null) != $'[Icon Theme]\nInherits=Adwaita' ]]; then
			[[ -f $d/index.theme ]] && backup "$d/index.theme"
			run mkdir -p "$d"
			if ((DRY)); then run write "$d/index.theme"; else
				printf '[Icon Theme]\nInherits=Adwaita\n' >"$d/index.theme"
			fi
		fi
	done

	# User settings are created once and never overwritten.
	if [[ ! -e $CONFIG_HOME/$NAME/settings.conf ]]; then
		run mkdir -p "$CONFIG_HOME/$NAME"
		if ((DRY)); then run write "$CONFIG_HOME/$NAME/settings.conf"; else
			printf '# lumen settings — edited by lumen-theme and the Settings app.\nmode=dark\naccent=blue\nbar_position=top\nfont=IBM Plex Sans\nfont_size=10\nmono_font=JetBrains Mono\n' \
				>"$CONFIG_HOME/$NAME/settings.conf"
		fi
	fi
	# Settings > Wallpaper looks here.
	[[ -d $HOME/Pictures/Wallpapers ]] || run mkdir -p "$HOME/Pictures/Wallpapers"
	setup_default_apps
	((BACKED_UP)) && log "Replaced files were backed up to $BACKUP"
	return 0
}

# Thunar for folders, Ristretto for pictures, mpv for videos and music.
# Only types you haven't chosen an app for yourself are set.
setup_default_apps() {
	local f=$CONFIG_HOME/mimeapps.list mime line add=()
	local -A want=([inode/directory]=thunar.desktop)
	for mime in image/png image/jpeg image/gif image/webp image/bmp image/tiff image/svg+xml image/avif; do
		want[$mime]=org.xfce.ristretto.desktop
	done
	for mime in video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg video/ogg \
		audio/mpeg audio/flac audio/ogg audio/x-wav audio/mp4 audio/opus; do
		want[$mime]=mpv.desktop
	done
	# Only [Default Applications] counts ([Added Associations] just lists
	# apps that can open a type).
	defaults_has() {
		[[ -f $f ]] && awk -F= -v m="$1" '/^\[/ { sect = $0 } sect == "[Default Applications]" && $1 == m { found = 1 } END { exit !found }' "$f"
	}
	# The file manager: you install lumen for Thunar, so offer to replace
	# another default (KDE's Dolphin on CachyOS, say).
	local fm
	fm=$(awk -F= '/^\[/ { sect = $0 } sect == "[Default Applications]" && $1 == "inode/directory" { print $2; exit }' "$f" 2>/dev/null)
	if [[ -n $fm && ${fm%%;*} != thunar.desktop ]] && ask "Your default file manager is ${fm%%;*}. Make Thunar the default?" y; then
		if ((DRY)); then run edit "$f"; else
			sed -i "s|^inode/directory=.*|inode/directory=thunar.desktop|" "$f"
		fi
		log "Thunar is now the default file manager."
	fi
	for mime in "${!want[@]}"; do
		defaults_has "$mime" && continue
		add+=("$mime=${want[$mime]}")
	done
	((${#add[@]})) || return 0
	log "Default apps: Thunar, Ristretto and mpv for ${#add[@]} file types."
	((DRY)) && { run write "$f"; return 0; }
	mkdir -p "$CONFIG_HOME"
	[[ -f $f ]] || printf '[Default Applications]\n' >"$f"
	grep -q '^\[Default Applications\]' "$f" || printf '\n[Default Applications]\n' >>"$f"
	# Insert right after the [Default Applications] header.
	local out=() done=0
	while IFS= read -r line || [[ -n $line ]]; do
		out+=("$line")
		if ((!done)) && [[ $line == '[Default Applications]' ]]; then
			out+=("${add[@]}")
			done=1
		fi
	done <"$f"
	printf '%s\n' "${out[@]}" >"$f"
}

# ---------------------------------------------------------------- system
# SDDM can't read your home folder, so its theme, the session entry and a copy
# of lumen-session are installed system-wide (always copied, even with --link).
# Monitor brightness over DDC/CI (ddcutil) needs the i2c-dev kernel module.
setup_ddc() {
	command -v ddcutil >/dev/null || return 0
	[[ -f /etc/modules-load.d/i2c-dev.conf || -f /etc/modules-load.d/lumen-i2c-dev.conf ]] && return 0
	log "Loading i2c-dev at boot, for monitor brightness (ddcutil)."
	if ((DRY)); then run sudo tee /etc/modules-load.d/lumen-i2c-dev.conf; else
		echo i2c-dev | sudo tee /etc/modules-load.d/lumen-i2c-dev.conf >/dev/null
	fi
	run sudo modprobe i2c-dev || true
}

install_system() {
	setup_ddc
	[[ $DM == sddm ]] || return 0
	local theme=/usr/share/sddm/themes/$NAME f
	log "Installing the login screen (SDDM)..."
	run sudo install -d -m 755 "$theme"
	for f in Main.qml metadata.desktop theme.conf; do
		run sudo install -m 644 "$REPO/system/sddm/$NAME/$f" "$theme/$f"
	done
	# (older versions copied a font in here; IBM Plex Sans is installed system-wide)
	[[ -d $theme/fonts ]] && run sudo rm -rf "$theme/fonts"
	# Owned by you so lumen-theme can recolour the login screen without sudo.
	if [[ ! -O $theme/theme.conf.user ]]; then
		run sudo install -m 644 -o "$(id -un)" -g "$(id -gn)" /dev/null "$theme/theme.conf.user"
	fi
	# Named to sort last: SDDM reads /etc/sddm.conf.d/ in order, later files win.
	[[ -f /etc/sddm.conf.d/$NAME.conf ]] && run sudo rm -f "/etc/sddm.conf.d/$NAME.conf"
	run sudo install -D -m 644 "$REPO/system/sddm/$NAME.conf" "/etc/sddm.conf.d/zz-$NAME.conf"
	# /etc/sddm.conf wins over that folder; some distributions (CachyOS) pick
	# their own theme there.
	if [[ -f /etc/sddm.conf ]] && grep -qE '^[[:space:]]*Current[[:space:]]*=' /etc/sddm.conf &&
		! grep -qE "^[[:space:]]*Current[[:space:]]*=[[:space:]]*$NAME[[:space:]]*$" /etc/sddm.conf; then
		local cur
		cur=$(grep -E '^[[:space:]]*Current[[:space:]]*=' /etc/sddm.conf | tail -n 1 | tr -d ' ')
		if ask "/etc/sddm.conf chooses another login theme ($cur). Use lumen's instead? (a copy is kept as /etc/sddm.conf.pre-lumen)" y; then
			run sudo cp -n /etc/sddm.conf /etc/sddm.conf.pre-lumen
			run sudo sed -i -E 's/^([[:space:]]*Current[[:space:]]*=.*)$/# \1   # replaced by lumen (zz-lumen.conf)/' /etc/sddm.conf
		else
			warn "kept it; the login screen stays $cur"
		fi
	fi
	run sudo install -D -m 644 "$REPO/system/xsessions/$NAME.desktop" "/usr/share/xsessions/$NAME.desktop"
	run sudo install -D -m 755 "$REPO/bin/lumen-session" /usr/local/bin/lumen-session
	enable_dm
}

enable_dm() {
	local link=/etc/systemd/system/display-manager.service cur=""
	[[ -L $link ]] && cur=$(basename "$(readlink "$link")")
	case $cur in
		sddm.service) log "SDDM is already enabled." ;;
		"") run sudo systemctl enable sddm.service ;;
		*)
			if ask "Another login manager ($cur) is enabled. Replace it with SDDM?" n; then
				run sudo systemctl disable "$cur"
				run sudo systemctl enable sddm.service
			else
				warn "kept $cur. To switch later: sudo systemctl disable $cur && sudo systemctl enable sddm"
			fi
			;;
	esac
}

# The profile picture is set after installing (Settings > Users, or
# lumen-avatar set <image>). An existing ~/.face is copied to the login screen.
setup_avatar() {
	if [[ $DM == sddm && -f $HOME/.face ]]; then
		run "$HOME/.local/bin/lumen-avatar" sync
	fi
	return 0
}

setup_autostart() {
	local profile=$HOME/.bash_profile marker="# lumen: start X on tty1"
	[[ $DM == none ]] || return 0 # SDDM starts the desktop
	if [[ -f $profile ]] && grep -qF "$marker" "$profile"; then return 0; fi
	case $AUTOSTART in
		no) return 0 ;;
		ask) ask "Start the desktop automatically when you log in on tty1?" y || return 0 ;;
	esac
	log "Adding auto-start to $profile"
	if ((DRY)); then run append "$profile"; return 0; fi
	cat >>"$profile" <<-EOF

		$marker
		if [ -z "\$DISPLAY" ] && [ "\${XDG_VTNR:-0}" -eq 1 ]; then
		    exec startx
		fi
	EOF
}

apply_theme() {
	log "Generating theme files..."
	if ((DRY)); then run "$HOME/.local/bin/lumen-theme" apply; return; fi
	"$HOME/.local/bin/lumen-theme" apply --quiet || warn "lumen-theme reported a problem; run it again after logging in"
}

# ---------------------------------------------------------------- main
preflight
install_packages
install_files
install_system
setup_avatar
setup_autostart
apply_theme

if ! ((DRY)) && command -v qs >/dev/null && qs --version 2>&1 | grep -q 'symbol lookup error'; then
	warn "Quickshell was built for a different Qt version than the one installed, so the bar won't start."
	warn "Run 'sudo pacman -Syu'; if it still fails, rebuild Quickshell (README: 'Quickshell won't start')."
fi

echo
log "Done."
if ((DRY)); then
	echo "   This was a dry run. Run again without --dry-run to install."
else
	if [[ $DM == sddm ]]; then
		echo "   Reboot to reach the login screen, then pick the 'bspwm' session."
	else
		echo "   Log out and back in on tty1, or run: startx"
	fi
	echo "   Set your profile picture in Settings > Users (super + comma)."
	echo "   Shortcuts: super+Return terminal · super+x apps · super+. emoji · super+/ all shortcuts"
fi
