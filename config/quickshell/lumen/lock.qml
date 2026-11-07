import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.services
import qs.modules.lock

// lumen lock screen — a separate Quickshell process started by `lumen-lock`.
// It exits (status 0) only after a correct password; lumen-lock falls back to
// i3lock if it ever stops any other way. LUMEN_LOCK_TEST=1 lets Escape close it.
//
// Input: lumen-lock-grab takes the whole keyboard and mouse (an X grab), so
// nothing behind the lock screen gets any key or click, and reports the keys
// typed here. The password is kept in `typed`, never in a text field.
ShellRoot {
    id: root

    readonly property bool testMode: Quickshell.env("LUMEN_LOCK_TEST") === "1"
    property string error: ""
    property bool busy: false
    property var pending: null
    property string typed: ""     // the password being typed
    property bool inputReady: false
    property bool unlocked: false
    signal failed()

    function submit(password) {
        if (busy || password === "") return;
        typed = "";
        error = "";
        busy = true;
        pending = password;
        if (!pam.start()) {
            busy = false;
            error = "Couldn't start the password check.";
        }
    }

    PamContext {
        id: pam
        // pam/lumen-lock next to this file: checks the password with pam_unix.
        configDirectory: "pam"
        config: "lumen-lock"

        onResponseRequiredChanged: {
            if (responseRequired && root.pending !== null) {
                respond(root.pending);
                root.pending = null;
            }
        }
        onCompleted: result => {
            root.busy = false;
            root.pending = null;
            if (result === PamResult.Success) {
                root.unlocked = true;
                grabber.running = false;   // give the keyboard and mouse back
                Qt.quit();
            } else {
                root.error = "Wrong password. Try again.";
                root.failed();
            }
        }
    }

    // Takes the keyboard and mouse and reports keys (see lumen-lock-grab).
    Process {
        id: grabber
        running: true
        command: ["lumen-lock-grab"]
        stdout: SplitParser {
            onRead: line => {
                const [what, arg] = line.split(" ");
                if (what === "ready") {
                    root.inputReady = true;
                } else if (what === "char") {
                    if (!root.busy && root.typed.length < 256) {
                        root.typed += String.fromCodePoint(parseInt(arg, 16));
                        root.error = "";
                    }
                } else if (what === "backspace") {
                    root.typed = Array.from(root.typed).slice(0, -1).join("");
                } else if (what === "clear") {
                    root.typed = "";
                } else if (what === "enter") {
                    root.submit(root.typed);
                } else if (what === "escape") {
                    if (root.testMode) Qt.exit(0);
                    else root.typed = "";
                }
            }
        }
        // Without the grab the lock isn't safe: stop, and lumen-lock locks
        // with i3lock instead (in test mode, just close).
        onExited: code => { if (!root.unlocked) Qt.exit(root.testMode ? 0 : 3); }
    }

    // The keyboard layout shown next to the password (it can change while
    // locked, with the usual switch keys).
    Timer {
        running: Keyboard.layouts.length > 1
        interval: 800
        repeat: true
        onTriggered: Keyboard.refresh()
    }

    Variants {
        model: Quickshell.screens
        LockSurface { lock: root }
    }
}
