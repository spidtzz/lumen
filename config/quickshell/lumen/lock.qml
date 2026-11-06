import QtQuick
import Quickshell
import Quickshell.Services.Pam
import qs.services
import qs.modules.lock

// lumen lock screen — a separate Quickshell process started by `lumen-lock`.
// It exits (status 0) only after a correct password; lumen-lock falls back to
// i3lock if it ever stops any other way. LUMEN_LOCK_TEST=1 lets Escape close it.
ShellRoot {
    id: root

    readonly property bool testMode: Quickshell.env("LUMEN_LOCK_TEST") === "1"
    property string error: ""
    property bool busy: false
    property var pending: null
    signal failed()

    function submit(password) {
        if (busy || password === "") return;
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
                Qt.quit();
            } else {
                root.error = "Wrong password. Try again.";
                root.failed();
            }
        }
    }

    Variants {
        model: Quickshell.screens
        LockSurface { lock: root }
    }
}
