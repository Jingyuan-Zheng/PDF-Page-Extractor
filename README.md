# PDF Page Extractor

[简体中文](README.zh-CN.md)

A small native macOS helper for previewing PDF files and exporting selected pages as **200 DPI PNG images**. Built with Swift, AppKit, and PDFKit; documents stay on your Mac. This renders whole pages, rather than extracting embedded image objects or creating a new PDF.

## Download and use

Download the ZIP for your Mac from [Releases](https://github.com/Jingyuan-Zheng/PDF-Page-Extractor/releases), unzip it, and move **PDF Page Extractor.app** to `/Applications`.

- Requires macOS 13 or newer and Apple silicon for the downloadable app. Intel users can build from source with `python3 build_app.py --arch x86_64`.
- Release builds are ad-hoc signed and are not notarized. macOS may require approval in System Settings → Privacy & Security when first opened.
- This is a Finder/command-line helper without a Dock icon, menu bar, or About window. Double-clicking it without PDF arguments displays “No PDF file was provided.”

Launch with one or more PDFs:

```sh
open -n "/Applications/PDF Page Extractor.app" --args "/path/to/document.pdf"
```

Select thumbnails with Command/Shift, or enter page numbers and ranges such as `1, 3-5, 9` and press Return. Switch between input PDFs using the file popup. Click **Extract Pages** to export.

**Export to Folder** creates a new folder beside the source PDF. Turn it off to write PNGs beside the PDF instead. Existing output names receive `_2`, `_3`, and later suffixes; source PDFs are unchanged. You need write permission in the PDF’s parent folder. Export uses a white background and a fixed 200 DPI resolution. The UI is currently English.

## Companion Finder Quick Actions

Download **PDF-Page-Extractor-Workflows.zip** from Releases. Install the app in `/Applications` (or `~/Applications`), then double-click the included workflows to install them through Automator:

- **Extract Page to Image...** opens the app with selected PDFs for interactive page selection.
- **Extract PDF as Images** exports every page of each selected PDF as 200 DPI PNG into a new sibling folder. This workflow embeds the included shell script and requires [Poppler](https://poppler.freedesktop.org/), available with `brew install poppler`. The interactive app does not require Poppler.

Finder → select PDF files → Quick Actions/Services. Enable the services in System Settings if needed. If you already have Quick Actions with these names, back them up before choosing to replace them.

Workflow bundles and their editable generator are included in this repository. Regenerate after changing the shell script with `python3 build_workflows.py`. The generator contains no machine-specific installation path.

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
