"""Exercise the app's actual PDF renderer with a generated fixture."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "Sources/PDFPageExtractor.swift").read_text()
start = source.index("    private func render(page:")
end = source.index("    private func showAlert", start)
renderer = source[start:end].replace("private func render", "func render")
error_start = source.index("struct AppError:")
error_end = source.index("let app = NSApplication.shared", error_start)
program = "import AppKit\nimport PDFKit\n" + renderer + source[error_start:error_end] + r'''
let directory = URL(fileURLWithPath: CommandLine.arguments[1])
let pdfURL = directory.appendingPathComponent("sample.pdf")
let document = PDFDocument()
for index in 0..<2 {
    let image = NSImage(size: NSSize(width: 72, height: 144))
    image.lockFocus()
    NSColor.white.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 72, height: 144)).fill()
    NSColor.black.setFill()
    NSBezierPath(rect: NSRect(x: 10, y: 10 + index * 20, width: 40, height: 40)).fill()
    image.unlockFocus()
    document.insert(PDFPage(image: image)!, at: index)
}
precondition(document.write(to: pdfURL))
let loaded = PDFDocument(url: pdfURL)!
precondition(loaded.pageCount == 2)
let output = directory.appendingPathComponent("page.png")
try render(page: loaded.page(at: 0)!, to: output, dpi: 200)
let data = try Data(contentsOf: output)
precondition(Array(data.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10])
let bitmap = NSBitmapImageRep(data: data)!
precondition(bitmap.pixelsWide == 200 && bitmap.pixelsHigh == 400)
var containsDarkPixel = false
for y in 0..<bitmap.pixelsHigh {
    for x in 0..<bitmap.pixelsWide {
        if let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
           color.redComponent < 0.5 && color.alphaComponent > 0.9 {
            containsDarkPixel = true
        }
    }
}
precondition(containsDarkPixel)
print("PASS: two-page PDF; actual renderer; 200 × 400 PNG; visible content")
'''
with tempfile.TemporaryDirectory(prefix="pdf-extractor-test-") as temporary:
    directory = Path(temporary)
    swift = directory / "main.swift"
    binary = directory / "smoke"
    swift.write_text(program)
    subprocess.run(["xcrun", "swiftc", "-module-cache-path", str(ROOT / "build/module-cache"),
                    "-framework", "AppKit", "-framework", "PDFKit", str(swift), "-o", str(binary)], check=True)
    subprocess.run([str(binary), str(directory)], check=True)
