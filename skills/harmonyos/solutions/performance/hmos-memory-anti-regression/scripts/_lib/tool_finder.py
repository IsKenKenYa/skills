"""Cross-platform tool finder for HarmonyOS development tools.

Searches for tools (hdc, trace_streamer, addr2line)
in the following order:
  1. Environment variable (HDC_HOME, TRACE_STREAMER_HOME, etc.)
  2. DevEco Studio installation directory (auto-detected)
  3. System PATH (shutil.which)

DevEco Studio auto-detection:
  - Windows: C:\\Program Files\\Huawei\\DevEco Studio\\
  - macOS:   /Applications/DevEco Studio.app/Contents/
  - Linux:   /opt/DevEco Studio/ or ~/DevEco Studio/
  - WSL2:    /mnt/c/Program Files/Huawei/DevEco Studio/

After locating DevEco Studio root, toolchains are searched under:
  <root>/sdk/default/openharmony/toolchains/
  <root>/sdk/openharmony/toolchains/
"""

import os
import platform
import shutil
import sys
from pathlib import Path
from typing import Optional


def _is_wsl() -> bool:
    try:
        return "microsoft" in open("/proc/version").read().lower()
    except Exception:
        return False


def _find_deveco_root() -> Optional[str]:
    root = os.environ.get("DEVECO_HOME")
    if root and Path(root).is_dir():
        return root

    candidates = []
    system = platform.system()

    if system == "Windows" or _is_wsl():
        prefix = "/mnt/c" if _is_wsl() else "C:"
        candidates.extend([
            f"{prefix}/Program Files/Huawei/DevEco Studio",
            f"{prefix}/Program Files (x86)/Huawei/DevEco Studio",
        ])
    elif system == "Darwin":
        candidates.extend([
            "/Applications/DevEco Studio.app/Contents",
            os.path.expanduser("~/DevEco Studio.app/Contents"),
        ])
    elif system == "Linux":
        candidates.extend([
            "/opt/DevEco Studio",
            os.path.expanduser("~/DevEco Studio"),
        ])

    for c in candidates:
        if Path(c).is_dir():
            return c

    return None


def _toolchain_dirs() -> list[str]:
    root = _find_deveco_root()
    if not root:
        return []
    return [
        str(Path(root) / "sdk" / "default" / "openharmony" / "toolchains"),
        str(Path(root) / "sdk" / "openharmony" / "toolchains"),
    ]


def _win_temp_dir() -> str:
    system = platform.system()
    if system == "Windows":
        return os.environ.get("TEMP", os.path.expandvars(r"%LOCALAPPDATA%\Temp"))
    if _is_wsl():
        username = os.environ.get("USER", "user")
        for candidate in [
            f"/mnt/c/Users/{username}/AppData/Local/Temp",
            "/mnt/c/Users/Administrator/AppData/Local/Temp",
        ]:
            if Path(candidate).is_dir():
                return candidate
        return f"/mnt/c/Users/{username}/AppData/Local/Temp"
    return os.environ.get("TMPDIR", "/tmp")


def find_hdc() -> Optional[str]:
    env = os.environ.get("HDC_PATH")
    if env and shutil.which(env):
        return env

    names = ["hdc.exe", "hdc"] if (_is_wsl() or platform.system() == "Windows") else ["hdc"]
    for d in _toolchain_dirs():
        for name in names:
            p = Path(d) / name
            if p.exists():
                return str(p)

    for name in names:
        found = shutil.which(name)
        if found:
            return found

    return None


def find_trace_streamer() -> Optional[str]:
    env = os.environ.get("TRACE_STREAMER_PATH")
    if env and shutil.which(env):
        return env

    if _is_wsl():
        names = ["trace_streamer.exe", "trace_streamer_windows.exe",
                 "trace_streamer_linux", "trace_streamer"]
    else:
        platform_map = {
            "win32": ["trace_streamer_windows.exe", "trace_streamer.exe", "trace_streamer"],
            "linux": ["trace_streamer_linux", "trace_streamer"],
            "darwin": ["trace_streamer_mac", "trace_streamer_darwin", "trace_streamer"],
        }
        names = platform_map.get(sys.platform, ["trace_streamer"])

    search_dirs = _toolchain_dirs()
    root = _find_deveco_root()
    if root:
        search_dirs.append(str(Path(root) / "tools" / "profiler" / "dic_server"))
    for d in search_dirs:
        for name in names:
            p = Path(d) / name
            if p.exists():
                return str(p)

    for name in names:
        found = shutil.which(name)
        if found:
            return found

    return None


def find_addr2line() -> Optional[str]:
    env = os.environ.get("ADDR2LINE_PATH")
    if env and shutil.which(env):
        return env

    platform_map = {
        "win32": ["llvm-addr2line.exe", "addr2line.exe", "llvm-addr2line"],
        "linux": ["llvm-addr2line", "addr2line"],
        "darwin": ["llvm-addr2line", "addr2line"],
    }
    names = platform_map.get(sys.platform, ["addr2line"])

    for d in _toolchain_dirs():
        for name in names:
            p = Path(d) / name
            if p.exists():
                return str(p)

    for name in names:
        found = shutil.which(name)
        if found:
            return found

    return None

def hdc_env() -> dict:
    """Return environment dict with MSYS2 path conversion disabled for hdc commands.

    On Windows (Git Bash / MSYS2), the shell auto-converts Unix-style paths starting
    with '/' to MSYS2 root paths (e.g. /data/local/tmp → C:/Program Files/Git/data/...),
    corrupting both local and remote paths in hdc commands.
    Setting MSYS_NO_PATHCONV=1 and MSYS2_ARG_CONV_EXCL="*" disables this conversion.
    """
    env = os.environ.copy()
    if sys.platform == "win32":
        env["MSYS_NO_PATHCONV"] = "1"
        env["MSYS2_ARG_CONV_EXCL"] = "*"
    return env
