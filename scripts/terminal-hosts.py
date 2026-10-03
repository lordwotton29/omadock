#!/usr/bin/env python3
"""Map Hyprland window addresses to their actual terminal emulator.

Omarchy TUIs override app_id, so the executable (or a bounded parent chain)
is the authority. No command line, environment, or window title is read.
"""

import json
import os
import subprocess

TERMINALS = {
    "ghostty": "com.mitchellh.ghostty",
    "kitty": "kitty",
    "alacritty": "Alacritty",
    "foot": "foot",
    "footclient": "foot",
    "wezterm": "org.wezfurlong.wezterm",
    "wezterm-gui": "org.wezfurlong.wezterm",
    "konsole": "org.kde.konsole",
    "gnome-terminal-server": "org.gnome.Terminal",
    "gnome-terminal": "org.gnome.Terminal",
    "kgx": "org.gnome.Console",
    "xfce4-terminal": "xfce4-terminal",
    "tilix": "com.gexperts.Tilix",
    "xterm": "xterm",
    "st": "st",
}


def terminal_for_pid(pid):
    seen = set()
    for _ in range(8):
        if not isinstance(pid, int) or pid <= 1 or pid in seen:
            return ""
        seen.add(pid)
        try:
            executable = os.path.basename(os.readlink(f"/proc/{pid}/exe"))
            terminal = TERMINALS.get(executable)
            if terminal:
                return terminal
            with open(f"/proc/{pid}/stat", encoding="utf-8") as stream:
                # comm may contain spaces and parentheses; ppid follows its last ')'.
                fields = stream.read(4096).rsplit(")", 1)[1].split()
            pid = int(fields[1])
        except (OSError, ValueError, IndexError):
            return ""
    return ""


def main():
    try:
        result = subprocess.run(
            ["hyprctl", "-j", "clients"], capture_output=True, text=True,
            timeout=2, check=True,
        )
        clients = json.loads(result.stdout)
        if not isinstance(clients, list):
            clients = []
        hosts = {}
        for client in clients[:2048]:
            if not isinstance(client, dict):
                continue
            terminal = terminal_for_pid(client.get("pid"))
            address = client.get("address")
            if terminal and isinstance(address, str):
                hosts[address.lower()] = terminal
        print(json.dumps(hosts))
    except (OSError, subprocess.SubprocessError, ValueError):
        print("{}")


if __name__ == "__main__":
    main()
