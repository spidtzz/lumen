.pragma library
// Parse an sxhkdrc into shortcut rows for the keyboard shortcut viewer.
//
//   # @group Windows          starts a group for the bindings below it
//   # Close the window        a comment directly above a binding describes it
//   super + q                 the binding (not indented)
//       bspc node -c          its command (indented; "\" continues a line)
//
// Bindings without a description show their command instead.
// Returns [{ group, keys: [[chip, ...], ...] (one list per chord), desc, command }]

function parse(text, defaultGroup) {
    const lines = text.split("\n");
    const rows = [];
    let group = defaultGroup || "General";
    let comment = "";
    let i = 0;

    while (i < lines.length) {
        const raw = lines[i];
        const t = raw.trim();
        i++;

        if (t === "") { comment = ""; continue; }
        if (t.startsWith("#")) {
            const body = t.replace(/^#+\s?/, "");
            const g = body.match(/^@group\s+(.+)$/);
            if (g) { group = g[1].trim(); comment = ""; }
            else comment = body.trim();
            continue;
        }
        if (/^\s/.test(raw)) continue;   // stray command line

        // Binding (with "\" continuations), then its indented command lines.
        let binding = t;
        while (binding.endsWith("\\") && i < lines.length) binding = binding.slice(0, -1) + lines[i++].trim();
        const cmd = [];
        while (i < lines.length && /^\s+\S/.test(lines[i])) {
            let c = lines[i++].trim();
            while (c.endsWith("\\") && i < lines.length) c = c.slice(0, -1) + " " + lines[i++].trim();
            cmd.push(c);
        }
        rows.push({
            group: group,
            keys: binding.split(";").map(chord => chord.split("+").map(prettyKey).filter(k => k !== "")),
            desc: comment,
            command: cmd.join("; ")
        });
        comment = "";
    }
    return rows;
}

const NAMES = {
    super: "Super", mod4: "Super", shift: "Shift", ctrl: "Ctrl", control: "Ctrl",
    alt: "Alt", mod1: "Alt", mode_switch: "AltGr", hyper: "Hyper",
    return: "Enter", space: "Space", escape: "Esc", tab: "Tab", backspace: "Backspace",
    delete: "Delete", print: "Print", slash: "/", backslash: "\\", comma: ",", period: ".",
    semicolon: ";", apostrophe: "'", grave: "`", minus: "-", equal: "=",
    bracketleft: "[", bracketright: "]", left: "←", right: "→", up: "↑", down: "↓",
    prior: "Page Up", next: "Page Down", home: "Home", end: "End", insert: "Insert",
    button1: "Left click", button2: "Middle click", button3: "Right click",
    button4: "Scroll up", button5: "Scroll down",
    xf86audioraisevolume: "Volume +", xf86audiolowervolume: "Volume −", xf86audiomute: "Mute",
    xf86audiomicmute: "Mic mute", xf86monbrightnessup: "Brightness +", xf86monbrightnessdown: "Brightness −",
    xf86audioplay: "Play", xf86audiopause: "Pause", xf86audionext: "Next track",
    xf86audioprev: "Previous track", xf86audiostop: "Stop"
};

// "super" -> "Super", "{h,j,k,l}" -> "H / J / K / L", "{1-9,0}" -> "1–9 / 0",
// "bracket{left,right}" -> "[ / ]"; "@" (on release) and "~" (pass through) are dropped.
function prettyKey(k) {
    k = k.trim().replace(/^[@~]+/, "");
    if (k === "") return "";
    const m = k.match(/^([^{]*)\{([^}]*)\}(.*)$/);
    if (m) {
        return m[2].split(",").map(part => {
            const range = part.match(/^(\w)-(\w)$/);
            if (range && m[1] === "" && m[3] === "") return range[1].toUpperCase() + "–" + range[2].toUpperCase();
            return single(m[1] + part + m[3]);
        }).join(" / ");
    }
    return single(k);
}

function single(k) {
    if (k === "_") return "";
    const n = NAMES[k.toLowerCase()];
    if (n) return n;
    if (/^XF86/.test(k)) return k.replace(/^XF86/, "").replace(/([a-z])([A-Z])/g, "$1 $2");
    return k.length === 1 ? k.toUpperCase() : k.charAt(0).toUpperCase() + k.slice(1);
}
