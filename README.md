# PDF Page Extractor

[简体中文](README.zh-CN.md)

A small native macOS helper for previewing PDF files and exporting selected pages as **200 DPI PNG images**. Built with Swift, AppKit, and PDFKit; documents stay on your Mac. This renders whole pages, rather than extracting embedded image objects or creating a new PDF.

## Download and use

Download the ZIP for your Mac from [Releases](https://github.com/Jingyuan-Zheng/PDF-Page-Extractor/releases), unzip it, and move **PDF Page Extractor.app** to `/Applications`.

- Requires macOS 13 or newer. Choose `arm64` for Apple silicon or `x86_64` for Intel.
- Release builds are ad-hoc signed and are not notarized. macOS may require approval in System Settings → Privacy & Security when first opened.
- This is a Finder/command-line helper without a Dock icon, menu bar, or About window. Double-clicking it without PDF arguments displays “No PDF file was provided.”

Launch with one or more PDFs:

```sh
open -n "/Applications/PDF Page Extractor.app" --args "/path/to/document.pdf"
```

Select thumbnails with Command/Shift, or enter page numbers and ranges such as `1, 3-5, 9` and press Return. Switch between input PDFs using the file popup. Click **Extract Pages** to export.

**Export to Folder** creates a new folder beside the source PDF. Turn it off to write PNGs beside the PDF instead. Existing output names receive `_2`, `_3`, and later suffixes; source PDFs are unchanged. You need write permission in the PDF’s parent folder. Export uses a white background and a fixed 200 DPI resolution. The UI is currently English.

## Optional Finder Quick Action

Open Automator, create a **Quick Action**, set “Workflow receives current” to **PDF files** in **Finder**, add **Run Shell Script**, choose `/bin/zsh`, and set “Pass input” to **as arguments**. Paste:

```sh
/usr/bin/open -n "/Applications/PDF Page Extractor.app" --args "$@"
```

Save as **Extract Page to Image**. It appears in Finder’s Quick Actions/Services; enable it in System Settings if necessary.

## Build from source

Install Apple’s Xcode Command Line Tools and Python 3, then:

```sh
python3 build_app.py
```

The app is created at `dist/PDF Page Extractor.app` for your current architecture, with macOS 13 as the deployment target. No third-party packages are required. The build applies an ad-hoc signature; it does not create a Developer ID signature or notarization ticket.

## Verification

```sh
python3 Tests/smoke_test.py
```

This creates a synthetic two-page PDF, compiles a renderer derived from the app’s actual rendering method, exports page one, and checks the PNG signature, expected 200 DPI dimensions, and nonwhite content. CI also builds and verifies the app bundle on macOS.

For optional local diagnostics, launch the executable with `PDF_PAGE_EXTRACTOR_DEBUG=1`; logs may contain document paths and are written to `/tmp/pdf-page-extractor.log`.

## Limitations

Large selections render synchronously and can temporarily block the window. Password-protected PDFs have no password-entry flow. Export DPI and format are fixed. The app does not OCR documents.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Author: [Jingyuan Zheng](https://github.com/Jingyuan-Zheng). Licensed under the [MIT License](LICENSE).
