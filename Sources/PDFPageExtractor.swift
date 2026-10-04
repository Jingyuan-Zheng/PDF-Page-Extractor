import AppKit
import PDFKit

final class PageThumbnailItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("PageThumbnailItem")

    private let thumbnailImageView = NSImageView()
    private let pageLabel = NSTextField(labelWithString: "")
    private let checkmarkView = NSImageView()
    private let cardView = NSView()

    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true

        cardView.wantsLayer = true
        cardView.layer?.cornerRadius = 8
        cardView.layer?.masksToBounds = false
        cardView.translatesAutoresizingMaskIntoConstraints = false

        thumbnailImageView.imageScaling = .scaleProportionallyUpOrDown
        thumbnailImageView.wantsLayer = true
        thumbnailImageView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        thumbnailImageView.layer?.cornerRadius = 5
        thumbnailImageView.layer?.masksToBounds = true
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

        pageLabel.alignment = .center
        pageLabel.font = .systemFont(ofSize: 12, weight: .medium)
        pageLabel.textColor = .secondaryLabelColor
        pageLabel.translatesAutoresizingMaskIntoConstraints = false

        checkmarkView.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Selected")
        checkmarkView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        checkmarkView.contentTintColor = .controlAccentColor
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(cardView)
        cardView.addSubview(thumbnailImageView)
        cardView.addSubview(pageLabel)
        cardView.addSubview(checkmarkView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),

            pageLabel.topAnchor.constraint(equalTo: cardView.topAnchor),
            pageLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            pageLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            pageLabel.heightAnchor.constraint(equalToConstant: 22),

            thumbnailImageView.topAnchor.constraint(equalTo: pageLabel.bottomAnchor, constant: 4),
            thumbnailImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            thumbnailImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            thumbnailImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8),

            checkmarkView.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 6),
            checkmarkView.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: -6),
            checkmarkView.widthAnchor.constraint(equalToConstant: 22),
            checkmarkView.heightAnchor.constraint(equalToConstant: 22)
        ])

        updateSelectionState()
    }

    func configure(pageNumber: Int, image: NSImage?) {
        pageLabel.stringValue = "\(pageNumber)"
        thumbnailImageView.image = image
        updateSelectionState()
    }

    private func updateSelectionState() {
        checkmarkView.isHidden = !isSelected
        cardView.layer?.backgroundColor = isSelected
            ? NSColor.controlAccentColor.withAlphaComponent(0.18).cgColor
            : NSColor.clear.cgColor
        cardView.layer?.borderWidth = isSelected ? 2 : 0
        cardView.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.75).cgColor
        cardView.layer?.shadowOpacity = isSelected ? 0.18 : 0
        cardView.layer?.shadowRadius = isSelected ? 8 : 0
        cardView.layer?.shadowOffset = NSSize(width: 0, height: -1)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate, NSWindowDelegate, NSCollectionViewDataSource, NSCollectionViewDelegate {
    private var window: NSWindow!
    private var pdfView: PDFView!
    private var thumbnailCollectionView: NSCollectionView!
    private var thumbnailScrollView: NSScrollView!
    private var filePopup: NSPopUpButton!
    private var previousButton: NSButton!
    private var nextButton: NSButton!
    private var pageField: NSTextField!
    private var pageCountLabel: NSTextField!
    private var statusLabel: NSTextField!
    private var exportButton: NSButton!
    private var exportToFolderCheckbox: NSButton!

    private var pdfURLs: [URL] = []
    private var document: PDFDocument?
    private var currentURL: URL?
    private var selectedPageIndexes = IndexSet()
    private var thumbnailCache: [Int: NSImage] = [:]
    private var isSyncingSelection = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        log("didFinishLaunching args=\(CommandLine.arguments)")
        pdfURLs = CommandLine.arguments.dropFirst().map(URL.init(fileURLWithPath:)).filter {
            $0.pathExtension.lowercased() == "pdf"
        }
        log("pdfURLs=\(pdfURLs.map(\.path))")

        if pdfURLs.isEmpty {
            showFatalAlert("No PDF file was provided.")
            NSApp.terminate(nil)
            return
        }

        buildWindow()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.beginLoadingPDF(at: self.pdfURLs[0])
            self.window.makeKeyAndOrderFront(nil)
            self.window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.window.makeKeyAndOrderFront(nil)
            self?.window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Extract PDF Page"
        window.minSize = NSSize(width: 760, height: 520)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.delegate = self

        let contentView = NSVisualEffectView(frame: window.contentView?.bounds ?? NSRect(x: 0, y: 0, width: 1000, height: 760))
        contentView.material = .contentBackground
        contentView.blendingMode = .behindWindow
        contentView.state = .active
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView

        let toolbarBackground = NSVisualEffectView()
        toolbarBackground.material = .headerView
        toolbarBackground.blendingMode = .withinWindow
        toolbarBackground.state = .active
        toolbarBackground.translatesAutoresizingMaskIntoConstraints = false

        let previewBackground = NSVisualEffectView()
        previewBackground.material = .contentBackground
        previewBackground.blendingMode = .withinWindow
        previewBackground.state = .active
        previewBackground.translatesAutoresizingMaskIntoConstraints = false

        let sidebarBackground = NSVisualEffectView()
        sidebarBackground.material = .contentBackground
        sidebarBackground.blendingMode = .withinWindow
        sidebarBackground.state = .active
        sidebarBackground.translatesAutoresizingMaskIntoConstraints = false

        let toolbar = NSStackView()
        toolbar.orientation = .horizontal
        toolbar.alignment = .centerY
        toolbar.spacing = 10
        toolbar.edgeInsets = NSEdgeInsets(top: 12, left: 76, bottom: 10, right: 14)
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        filePopup = NSPopUpButton()
        filePopup.target = self
        filePopup.action = #selector(fileSelectionChanged(_:))
        filePopup.translatesAutoresizingMaskIntoConstraints = false
        filePopup.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        filePopup.setContentHuggingPriority(.defaultLow, for: .horizontal)
        filePopup.addItems(withTitles: pdfURLs.map { $0.lastPathComponent })
        filePopup.isHidden = pdfURLs.count <= 1

        previousButton = iconButton(symbolName: "chevron.left", accessibilityDescription: "Previous Page", action: #selector(previousPage(_:)))
        nextButton = iconButton(symbolName: "chevron.right", accessibilityDescription: "Next Page", action: #selector(nextPage(_:)))

        pageField = NSTextField(string: "1")
        pageField.placeholderString = "1, 3-5"
        pageField.alignment = .left
        pageField.delegate = self
        pageField.target = self
        pageField.action = #selector(pageFieldSubmitted(_:))
        pageField.bezelStyle = .roundedBezel
        pageField.controlSize = .large
        pageField.translatesAutoresizingMaskIntoConstraints = false

        pageCountLabel = NSTextField(labelWithString: "/ 0")
        pageCountLabel.translatesAutoresizingMaskIntoConstraints = false

        exportToFolderCheckbox = NSButton(checkboxWithTitle: "Export to Folder", target: nil, action: nil)
        exportToFolderCheckbox.state = .on
        exportToFolderCheckbox.controlSize = .regular
        exportToFolderCheckbox.toolTip = "Save extracted images into a new folder"

        exportButton = NSButton(title: "Extract Pages", target: self, action: #selector(extractSelectedPages(_:)))
        exportButton.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "Extract Selected Pages")
        exportButton.imagePosition = .imageLeading
        exportButton.bezelStyle = .rounded
        exportButton.bezelColor = .controlAccentColor
        exportButton.controlSize = .large

        statusLabel = NSTextField(labelWithString: "")
        statusLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let titleLabel = NSTextField(labelWithString: "PDF Page Extractor")
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        titleLabel.textColor = .labelColor

        toolbar.addArrangedSubview(titleLabel)
        toolbar.addArrangedSubview(filePopup)
        toolbar.addArrangedSubview(previousButton)
        toolbar.addArrangedSubview(nextButton)
        toolbar.addArrangedSubview(label("Page"))
        toolbar.addArrangedSubview(pageField)
        toolbar.addArrangedSubview(pageCountLabel)
        toolbar.addArrangedSubview(exportToFolderCheckbox)
        toolbar.addArrangedSubview(exportButton)
        toolbar.addArrangedSubview(statusLabel)

        pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displaysPageBreaks = false
        pdfView.displayBox = .mediaBox
        pdfView.pageShadowsEnabled = true
        pdfView.interpolationQuality = .high
        pdfView.backgroundColor = .clear
        pdfView.translatesAutoresizingMaskIntoConstraints = false

        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 148, height: 192)
        flowLayout.sectionInset = NSEdgeInsets(top: 10, left: 8, bottom: 12, right: 8)
        flowLayout.minimumLineSpacing = 10
        flowLayout.minimumInteritemSpacing = 0

        thumbnailCollectionView = NSCollectionView()
        thumbnailCollectionView.collectionViewLayout = flowLayout
        thumbnailCollectionView.register(PageThumbnailItem.self, forItemWithIdentifier: PageThumbnailItem.identifier)
        thumbnailCollectionView.dataSource = self
        thumbnailCollectionView.delegate = self
        thumbnailCollectionView.allowsMultipleSelection = true
        thumbnailCollectionView.isSelectable = true
        thumbnailCollectionView.backgroundColors = [.clear]
        thumbnailCollectionView.translatesAutoresizingMaskIntoConstraints = false

        thumbnailScrollView = NSScrollView()
        thumbnailScrollView.documentView = thumbnailCollectionView
        thumbnailScrollView.hasVerticalScroller = true
        thumbnailScrollView.hasHorizontalScroller = false
        thumbnailScrollView.drawsBackground = false
        thumbnailScrollView.borderType = .noBorder
        thumbnailScrollView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(toolbarBackground)
        toolbarBackground.addSubview(toolbar)
        contentView.addSubview(previewBackground)
        previewBackground.addSubview(pdfView)
        contentView.addSubview(sidebarBackground)
        sidebarBackground.addSubview(thumbnailScrollView)

        NSLayoutConstraint.activate([
            toolbarBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
            toolbarBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolbarBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            toolbar.topAnchor.constraint(equalTo: toolbarBackground.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: toolbarBackground.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: toolbarBackground.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: toolbarBackground.bottomAnchor),

            filePopup.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
            previousButton.widthAnchor.constraint(equalToConstant: 34),
            nextButton.widthAnchor.constraint(equalToConstant: 34),
            pageField.widthAnchor.constraint(equalToConstant: 138),
            pageCountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 48),

            previewBackground.topAnchor.constraint(equalTo: toolbarBackground.bottomAnchor),
            previewBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            previewBackground.trailingAnchor.constraint(equalTo: sidebarBackground.leadingAnchor),
            previewBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            sidebarBackground.topAnchor.constraint(equalTo: previewBackground.topAnchor),
            sidebarBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sidebarBackground.bottomAnchor.constraint(equalTo: previewBackground.bottomAnchor),
            sidebarBackground.widthAnchor.constraint(equalToConstant: 172),

            pdfView.topAnchor.constraint(equalTo: previewBackground.topAnchor, constant: 10),
            pdfView.leadingAnchor.constraint(equalTo: previewBackground.leadingAnchor, constant: 10),
            pdfView.trailingAnchor.constraint(equalTo: previewBackground.trailingAnchor, constant: -10),
            pdfView.bottomAnchor.constraint(equalTo: previewBackground.bottomAnchor, constant: -10),

            thumbnailScrollView.topAnchor.constraint(equalTo: sidebarBackground.topAnchor),
            thumbnailScrollView.leadingAnchor.constraint(equalTo: sidebarBackground.leadingAnchor),
            thumbnailScrollView.trailingAnchor.constraint(equalTo: sidebarBackground.trailingAnchor),
            thumbnailScrollView.bottomAnchor.constraint(equalTo: sidebarBackground.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: pdfView
        )

        statusLabel.stringValue = "Loading..."
        previousButton.isEnabled = false
        nextButton.isEnabled = false
        exportButton.isEnabled = false
    }

    private func label(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func iconButton(symbolName: String, accessibilityDescription: String, action: Selector) -> NSButton {
        let button = NSButton(title: "", target: self, action: action)
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDescription)
        button.imagePosition = .imageOnly
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.toolTip = accessibilityDescription
        return button
    }

    private func beginLoadingPDF(at url: URL) {
        log("beginLoadingPDF \(url.path)")
        currentURL = url
        document = nil
        pdfView.document = nil
        selectedPageIndexes.removeAll()
        thumbnailCache.removeAll()
        thumbnailCollectionView.reloadData()
        window.title = "Extract PDF Page - \(url.lastPathComponent)"
        statusLabel.stringValue = "Loading \(url.lastPathComponent)..."
        syncControls()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.log("background opening \(url.path)")
            let loaded = PDFDocument(url: url)
            let pageCount = loaded?.pageCount ?? 0
            self?.log("background opened pageCount=\(pageCount)")

            DispatchQueue.main.async {
                guard let self else { return }
                guard let loaded, loaded.pageCount > 0 else {
                    self.showFatalAlert("Could not open this PDF:\n\(url.path)")
                    return
                }

                self.finishLoadingPDF(loaded, from: url)
            }
        }
    }

    private func finishLoadingPDF(_ loaded: PDFDocument, from url: URL) {
        currentURL = url
        document = loaded
        log("assigning document to PDFView")
        pdfView.document = loaded
        selectedPageIndexes = IndexSet(integer: 0)
        thumbnailCache.removeAll()
        thumbnailCollectionView.reloadData()
        applySelectionToThumbnailView(scrollToFirst: true)
        syncFieldFromSelection()
        log("assigned document to PDFView")
        pdfView.goToFirstPage(nil)
        log("went to first page")
        window.title = "Extract PDF Page - \(url.lastPathComponent)"
        statusLabel.stringValue = url.lastPathComponent
        statusLabel.toolTip = url.path
        syncControls()
        DispatchQueue.main.async { [weak self] in
            self?.fitPageToWindow()
        }
        log("loaded pageCount=\(loaded.pageCount)")
    }

    @objc private func fileSelectionChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        guard pdfURLs.indices.contains(index) else { return }
        beginLoadingPDF(at: pdfURLs[index])
    }

    @objc private func previousPage(_ sender: Any?) {
        pdfView.goToPreviousPage(sender)
        syncControls()
        selectCurrentPageIfSelectionIsEmpty()
        fitPageToWindow()
    }

    @objc private func nextPage(_ sender: Any?) {
        pdfView.goToNextPage(sender)
        syncControls()
        selectCurrentPageIfSelectionIsEmpty()
        fitPageToWindow()
    }

    @objc private func pageChanged(_ notification: Notification) {
        syncControls()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        applyPageFieldSelection()
    }

    @objc private func pageFieldSubmitted(_ sender: NSTextField) {
        applyPageFieldSelection()
    }

    func windowDidResize(_ notification: Notification) {
        fitPageToWindow()
    }

    @objc private func extractSelectedPages(_ sender: Any?) {
        guard let document, let currentURL else {
            showAlert("No PDF is loaded.")
            return
        }

        guard !selectedPageIndexes.isEmpty else {
            showAlert("Select at least one page to extract.")
            return
        }

        do {
            var outputURLs: [URL] = []
            let stem = currentURL.deletingPathExtension().lastPathComponent
            let outputDirectory: URL?

            if exportToFolderCheckbox.state == .on {
                outputDirectory = try uniqueOutputDirectory(for: currentURL, selectionLabel: compactPageRange(from: selectedPageIndexes))
            } else {
                outputDirectory = nil
            }

            for pageIndex in selectedPageIndexes {
                guard let page = document.page(at: pageIndex) else { continue }
                let outputURL: URL
                if let outputDirectory {
                    outputURL = outputDirectory.appendingPathComponent("\(stem)_page_\(pageIndex + 1).png")
                } else {
                    outputURL = uniqueOutputFile(
                        in: currentURL.deletingLastPathComponent(),
                        baseName: "\(stem)_page_\(pageIndex + 1)",
                        extension: "png"
                    )
                }
                try render(page: page, to: outputURL, dpi: 200)
                outputURLs.append(outputURL)
                log("saved \(outputURL.path)")
            }

            statusLabel.stringValue = "Saved \(outputURLs.count) page image(s)"
            if let outputDirectory, outputURLs.isEmpty {
                NSWorkspace.shared.activateFileViewerSelecting([outputDirectory])
            } else {
                NSWorkspace.shared.activateFileViewerSelecting(outputURLs)
            }
        } catch {
            log("save failed \(error.localizedDescription)")
            showAlert(error.localizedDescription)
        }
    }

    private func applyPageFieldSelection() {
        guard let document else { return }

        do {
            let parsedSelection = try parsePageSelection(pageField.stringValue, maxPage: document.pageCount)
            selectedPageIndexes = parsedSelection
            applySelectionToThumbnailView(scrollToFirst: true)
            syncFieldFromSelection()
            goToFirstSelectedPage()
            syncControls()
            fitPageToWindow()
        } catch {
            showAlert(error.localizedDescription)
            syncFieldFromSelection()
        }
    }

    private func syncControls() {
        guard let document else {
            pageField.stringValue = ""
            pageCountLabel.stringValue = "/ 0"
            previousButton.isEnabled = false
            nextButton.isEnabled = false
            exportButton.isEnabled = false
            return
        }

        let pageNumber: Int
        if let currentPage = pdfView.currentPage {
            let pageIndex = document.index(for: currentPage)
            pageNumber = pageIndex == NSNotFound ? 1 : pageIndex + 1
        } else {
            pageNumber = selectedPageIndexes.first.map { $0 + 1 } ?? 1
        }

        pageCountLabel.stringValue = "/ \(document.pageCount)"
        previousButton.isEnabled = pageNumber > 1
        nextButton.isEnabled = pageNumber < document.pageCount
        exportButton.isEnabled = !selectedPageIndexes.isEmpty
        exportButton.title = selectedPageIndexes.count <= 1 ? "Extract Page" : "Extract \(selectedPageIndexes.count) Pages"
    }

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        document?.pageCount ?? 0
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item = collectionView.makeItem(
            withIdentifier: PageThumbnailItem.identifier,
            for: indexPath
        )
        guard let pageItem = item as? PageThumbnailItem else { return item }
        pageItem.configure(pageNumber: indexPath.item + 1, image: thumbnailImage(for: indexPath.item))
        return pageItem
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        thumbnailSelectionChanged()
    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        thumbnailSelectionChanged()
    }

    private func thumbnailSelectionChanged() {
        guard !isSyncingSelection else { return }
        selectedPageIndexes = thumbnailCollectionView.selectionIndexes
        syncFieldFromSelection()
        goToFirstSelectedPage()
        syncControls()
        fitPageToWindow()
    }

    private func applySelectionToThumbnailView(scrollToFirst: Bool) {
        isSyncingSelection = true
        thumbnailCollectionView.selectionIndexes = selectedPageIndexes
        isSyncingSelection = false

        guard scrollToFirst, let first = selectedPageIndexes.first else { return }
        thumbnailCollectionView.scrollToItems(
            at: [IndexPath(item: first, section: 0)],
            scrollPosition: .centeredVertically
        )
    }

    private func syncFieldFromSelection() {
        guard document != nil else { return }
        pageField.stringValue = compactPageRange(from: selectedPageIndexes)
    }

    private func goToFirstSelectedPage() {
        guard let document, let first = selectedPageIndexes.first, let page = document.page(at: first) else { return }
        pdfView.go(to: page)
    }

    private func selectCurrentPageIfSelectionIsEmpty() {
        guard selectedPageIndexes.isEmpty, let document, let currentPage = pdfView.currentPage else { return }
        let pageIndex = document.index(for: currentPage)
        guard pageIndex != NSNotFound else { return }
        selectedPageIndexes = IndexSet(integer: pageIndex)
        applySelectionToThumbnailView(scrollToFirst: true)
        syncFieldFromSelection()
        syncControls()
    }

    private func thumbnailImage(for pageIndex: Int) -> NSImage? {
        if let cached = thumbnailCache[pageIndex] {
            return cached
        }

        guard let page = document?.page(at: pageIndex) else {
            return nil
        }

        let image = page.thumbnail(of: NSSize(width: 112, height: 154), for: .mediaBox)
        thumbnailCache[pageIndex] = image
        return image
    }

    private func parsePageSelection(_ input: String, maxPage: Int) throws -> IndexSet {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError("Enter one or more pages, such as 1, 3-5.")
        }

        let separators = CharacterSet(charactersIn: ",;\n\t ")
        let tokens = trimmed.components(separatedBy: separators).filter { !$0.isEmpty }
        guard !tokens.isEmpty else {
            throw AppError("Enter one or more pages, such as 1, 3-5.")
        }

        var indexes = IndexSet()
        for token in tokens {
            if token.contains("-") {
                let bounds = token.split(separator: "-", omittingEmptySubsequences: false)
                guard bounds.count == 2,
                      let start = Int(bounds[0].trimmingCharacters(in: .whitespaces)),
                      let end = Int(bounds[1].trimmingCharacters(in: .whitespaces)) else {
                    throw AppError("Could not read page range '\(token)'. Use a format like 3-8.")
                }

                let lower = min(start, end)
                let upper = max(start, end)
                guard lower >= 1, upper <= maxPage else {
                    throw AppError("Page range '\(token)' is outside 1 to \(maxPage).")
                }

                indexes.insert(integersIn: (lower - 1)..<upper)
            } else if let pageNumber = Int(token) {
                guard (1...maxPage).contains(pageNumber) else {
                    throw AppError("Page \(pageNumber) is outside 1 to \(maxPage).")
                }
                indexes.insert(pageNumber - 1)
            } else {
                throw AppError("Could not read page '\(token)'. Use pages like 1, 3-5, 9.")
            }
        }

        guard !indexes.isEmpty else {
            throw AppError("Select at least one page.")
        }
        return indexes
    }

    private func compactPageRange(from indexes: IndexSet) -> String {
        guard let firstIndex = indexes.first else { return "" }

        var parts: [String] = []
        var rangeStart = firstIndex
        var previous = firstIndex

        for index in indexes.dropFirst() {
            if index == previous + 1 {
                previous = index
            } else {
                parts.append(formatPageRange(start: rangeStart, end: previous))
                rangeStart = index
                previous = index
            }
        }

        parts.append(formatPageRange(start: rangeStart, end: previous))
        return parts.joined(separator: ", ")
    }

    private func formatPageRange(start: Int, end: Int) -> String {
        start == end ? "\(start + 1)" : "\(start + 1)-\(end + 1)"
    }

    private func fitPageToWindow() {
        guard pdfView.document != nil else { return }
        pdfView.autoScales = true
        pdfView.layoutDocumentView()
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
    }

    private func uniqueOutputDirectory(for pdfURL: URL, selectionLabel: String) throws -> URL {
        let parent = pdfURL.deletingLastPathComponent()
        let stem = pdfURL.deletingPathExtension().lastPathComponent
        let safeSelection = selectionLabel
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: "_")
            .replacingOccurrences(of: "-", with: "-")
        let baseName = "\(stem)_pages_\(safeSelection)_images"
        var candidate = parent.appendingPathComponent(baseName, isDirectory: true)
        var suffix = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = parent.appendingPathComponent("\(baseName)_\(suffix)", isDirectory: true)
            suffix += 1
        }

        try FileManager.default.createDirectory(at: candidate, withIntermediateDirectories: true)
        return candidate
    }

    private func uniqueOutputFile(in directory: URL, baseName: String, extension fileExtension: String) -> URL {
        var candidate = directory.appendingPathComponent(baseName).appendingPathExtension(fileExtension)
        var suffix = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName)_\(suffix)").appendingPathExtension(fileExtension)
            suffix += 1
        }

        return candidate
    }

    private func render(page: PDFPage, to outputURL: URL, dpi: CGFloat) throws {
        let bounds = page.bounds(for: .mediaBox)
        let scale = dpi / 72.0
        let width = max(1, Int((bounds.width * scale).rounded(.up)))
        let height = max(1, Int((bounds.height * scale).rounded(.up)))

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap)?.cgContext else {
            throw AppError("Could not create a bitmap renderer.")
        }

        context.saveGState()
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()

        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw AppError("Could not encode the page as PNG.")
        }

        try png.write(to: outputURL, options: .atomic)
    }

    private func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Extract PDF Page"
        alert.informativeText = message
        alert.runModal()
    }

    private func showFatalAlert(_ message: String) {
        log("fatal \(message)")
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Extract PDF Page"
        alert.informativeText = message
        alert.runModal()
    }

    private func log(_ message: String) {
        guard ProcessInfo.processInfo.environment["PDF_PAGE_EXTRACTOR_DEBUG"] == "1" else { return }
        let line = "\(Date()) \(message)\n"
        let url = URL(fileURLWithPath: "/tmp/pdf-page-extractor.log")
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path),
               let handle = try? FileHandle(forWritingTo: url) {
                _ = try? handle.seekToEnd()
                _ = try? handle.write(contentsOf: data)
                _ = try? handle.close()
            } else {
                try? data.write(to: url)
            }
        }
    }
}

struct AppError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
