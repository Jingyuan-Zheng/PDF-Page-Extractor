# PDF Page Extractor

[简体中文](README.zh-CN.md)

Turn the PDF pages you need into PNG images, directly from Finder. Preview your document, select one page or several, and export them for notes, presentations, or sharing. You can also export every page without opening the preview window.

![PDF Page Extractor preview and page selection](docs/images/pdf-page-extractor.png)

## What you can do

- **Preview before exporting:** see the current page at a large size, with page thumbnails on the right.
- **Choose exactly the pages you need:** select thumbnails or enter a range such as `1, 3-5, 9`.
- **Work with several PDFs:** select multiple files in Finder and switch between them in the app.
- **Keep exports organized:** save images in a new folder beside the PDF, or directly beside the original file.
- **Export a whole PDF in one action:** use the companion **Extract PDF as Images** Quick Action.

Images are saved as **200 DPI PNGs with a white background**. Existing output files receive a numbered suffix, so earlier exports are kept. Your original PDFs are unchanged, and processing happens on your Mac. The interface is currently English.

## Install

### 1. Download the app and Quick Actions

Open [the latest release](https://github.com/Jingyuan-Zheng/PDF-Page-Extractor/releases/latest) and download:

| Download | Purpose |
| --- | --- |
| `PDF-Page-Extractor-v1.0.0-arm64.zip` | The preview and page-selection app |
| `PDF-Page-Extractor-Workflows.zip` | Two Finder Quick Actions |

The downloadable app requires **macOS 13 or newer and an Apple silicon Mac** (M1, M2, M3, and later). You can check your chip under Apple menu → About This Mac. Intel users can build from source; an Intel download is not provided.

### 2. Install the app

1. Double-click the app ZIP to unzip it.
2. Drag **PDF Page Extractor.app** into your **Applications** folder (`/Applications`). The Quick Action also supports your personal `~/Applications` folder.

The app is intended to open through the Quick Action with a PDF selected. Double-clicking the app by itself shows “No PDF file was provided”; that means it needs an input PDF.

The app is ad-hoc signed and has not been notarized by Apple. If macOS blocks your first launch, use **System Settings → Privacy & Security → Open Anyway** for this app after attempting to run the Quick Action, then confirm the system prompt.

### 3. Install the Finder Quick Actions

1. Unzip `PDF-Page-Extractor-Workflows.zip` and open the **Workflows** folder.
2. Double-click **Extract Page to Image....workflow** and accept the installation prompt.
3. Double-click **Extract PDF as Images.workflow** to install the whole-document action as well, if wanted.
4. Select a PDF in Finder, right-click it, and look under **Quick Actions** or **Services** for the installed actions.

If an action is missing, enable it in System Settings. On recent macOS versions, check **General → Login Items & Extensions → Extensions → Finder**, or **Keyboard → Keyboard Shortcuts → Services → Files and Folders**, depending on your macOS version. See [Apple’s extension settings guide](https://support.apple.com/guide/mac-help/mtusr003/mac). If you already have an action with the same name, back it up before replacing it.

**Only the whole-document action needs Poppler.** If you already use Homebrew, install it in Terminal with:

```sh
brew install poppler
```

If you do not have Homebrew, follow the installation instructions at [brew.sh](https://brew.sh/) first. The preview app and **Extract Page to Image...** work without Homebrew or Poppler.

## Use

### Export selected pages

1. In Finder, select one or more PDF files.
2. Right-click → **Quick Actions / Services → Extract Page to Image...**.
3. In the preview window, click a thumbnail to select a page. Hold **Command** to select individual pages, or **Shift** to select a continuous range. Alternatively, enter `1, 3-5, 9` in **Page** and press Return.
4. If you selected several PDFs, choose the PDF to work on from the file dropdown.
5. Leave **Export to Folder** checked to create a new folder beside the PDF. Uncheck it to save the PNGs directly beside the PDF.
6. Click **Extract Page / Extract N Pages**. Finder reveals the exported images when finished.

The left and right arrow buttons browse the preview. Use the thumbnails or **Page** field to choose which pages to export.

### Export every page

Select one or more PDFs in Finder, then right-click → **Quick Actions / Services → Extract PDF as Images**. Each PDF gets its own new folder containing one PNG per page. This action runs without the preview window and requires Poppler.

### Where do the images go?

For `report.pdf`, exporting pages 1–3 with **Export to Folder** creates a folder like `report_pages_1-3_images`, containing `report_page_1.png`, `report_page_2.png`, and `report_page_3.png`.

Exporting the whole PDF creates `report_images`. Running either action again adds `_2`, `_3`, and so on to the output folder or file names. You need write permission in the PDF’s folder; copy the PDF to a writable folder if export fails.

## Troubleshooting and limits

| Problem | What to check |
| --- | --- |
| “No PDF file was provided” | Launch from Finder with PDF files selected, rather than double-clicking the app. |
| Quick Action cannot find the app | Put the app in `/Applications` or `~/Applications`, keeping the name **PDF Page Extractor.app**. |
| “pdftoppm was not found” | Install Poppler for the whole-document action. |
| Export cannot save files | Check write permission in the PDF’s parent folder. |
| Large export seems paused | Pages export synchronously; large selections can temporarily block the preview window. |

Export format and resolution are fixed at PNG / 200 DPI. The app renders entire pages; it does not extract embedded image objects, create a new PDF, or perform OCR. Password-protected PDFs have no password-entry flow.

## For developers

Built with Swift, AppKit, and PDFKit. Install Xcode Command Line Tools and Python 3, then run:

```sh
python3 build_app.py
python3 Tests/smoke_test.py
python3 build_workflows.py
```

The app appears at `dist/PDF Page Extractor.app`, built for your current architecture with macOS 13 as the deployment target. Use `python3 build_app.py --arch x86_64` for Intel. No third-party packages are needed to build the app.

`Workflows/` contains ready-to-install bundles; `build_workflows.py` regenerates them. The all-pages workflow embeds `scripts/pdf_extract_all_pages.sh`, so there is no separate worker to install.

The smoke test generates a two-page PDF and exercises the app’s actual renderer, checking PNG encoding, 200 DPI dimensions, and visible content. macOS CI builds the app, verifies its signature, regenerates workflows, and checks shell syntax. Local workflow verification also covered filenames with spaces and repeated exports without overwriting.

To launch without a Quick Action:

```sh
open -n "/Applications/PDF Page Extractor.app" --args "/path/to/document.pdf"
```

For diagnostics, run the executable with `PDF_PAGE_EXTRACTOR_DEBUG=1`. Logs may contain document paths and are written to `/tmp/pdf-page-extractor.log`.

See [CONTRIBUTING.md](CONTRIBUTING.md) for contributions. Author: [Jingyuan Zheng](https://github.com/Jingyuan-Zheng). Licensed under the [MIT License](LICENSE).
