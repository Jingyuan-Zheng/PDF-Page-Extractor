#!/usr/bin/env python3
from __future__ import annotations

import argparse
import platform
import plistlib
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
APP_ROOT = ROOT
SOURCE = APP_ROOT / "Sources" / "PDFPageExtractor.swift"
BUILD_DIR = APP_ROOT / "build"
OUTPUTS = ROOT / "dist"
APP_BUNDLE = OUTPUTS / "PDF Page Extractor.app"
EXECUTABLE_NAME = "PDFPageExtractor"


def main() -> None:
    parser = argparse.ArgumentParser(description="Build PDF Page Extractor for macOS 13+")
    parser.add_argument("--arch", choices=["arm64", "x86_64"], default=platform.machine())
    args = parser.parse_args()
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    (BUILD_DIR / "module-cache").mkdir(parents=True, exist_ok=True)
    OUTPUTS.mkdir(parents=True, exist_ok=True)

    binary = BUILD_DIR / EXECUTABLE_NAME
    subprocess.run(
        [
            "xcrun",
            "swiftc",
            "-target",
            f"{args.arch}-apple-macosx13.0",
            "-O",
            "-module-cache-path",
            str(BUILD_DIR / "module-cache"),
            "-framework",
            "AppKit",
            "-framework",
            "PDFKit",
            str(SOURCE),
            "-o",
            str(binary),
        ],
        check=True,
    )

    if APP_BUNDLE.exists():
        shutil.rmtree(APP_BUNDLE)

    macos_dir = APP_BUNDLE / "Contents" / "MacOS"
    resources_dir = APP_BUNDLE / "Contents" / "Resources"
    macos_dir.mkdir(parents=True)
    resources_dir.mkdir(parents=True)

    shutil.copy2(binary, macos_dir / EXECUTABLE_NAME)

    info = {
        "CFBundleDevelopmentRegion": "en",
        "CFBundleExecutable": EXECUTABLE_NAME,
        "CFBundleIdentifier": "local.pdf-image-actions.page-extractor",
        "CFBundleInfoDictionaryVersion": "6.0",
        "CFBundleName": "PDF Page Extractor",
        "CFBundleDisplayName": "PDF Page Extractor",
        "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": "1.0.0",
        "CFBundleVersion": "1",
        "LSUIElement": True,
        "LSMinimumSystemVersion": "13.0",
        "NSHighResolutionCapable": True,
        "NSPrincipalClass": "NSApplication",
    }

    with (APP_BUNDLE / "Contents" / "Info.plist").open("wb") as file:
        plistlib.dump(info, file, sort_keys=False)

    subprocess.run(["xattr", "-cr", str(APP_BUNDLE)], check=True)
    subprocess.run(["codesign", "--force", "--sign", "-", str(APP_BUNDLE)], check=True)
    subprocess.run(["codesign", "--verify", "--strict", str(APP_BUNDLE)], check=True)
    print(APP_BUNDLE)


if __name__ == "__main__":
    main()
