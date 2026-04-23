import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct SettingsView: View {
    // Company Info
    @AppStorage("companyName") private var companyName = "N & P Contracting"
    @AppStorage("companyAddress") private var companyAddress = "Unit 9 / 48 Tennyson Memorial Avenue, Tennyson QLD 4105"
    @AppStorage("companyPhone") private var companyPhone = "07 3892 3399"
    @AppStorage("companyEmail") private var companyEmail = "info@npcontracting.com.au"
    @AppStorage("companyABN") private var companyABN = "51 709 046 128"
    @AppStorage("companyLicense") private var companyLicense = "65051"
    // Tester Info
    @AppStorage("testerName") private var testerName = ""
    @AppStorage("testerLicense") private var testerLicense = ""
    // Signature
    @AppStorage("defaultSignature") private var defaultSignature: Data?
    @State private var showSignatureEditor = false
    @State private var showReplaceDefaultSignatureAlert = false
    // Theme
    @AppStorage("isDarkMode") private var isDarkMode = false
    // Export/Import
    @State private var showExportSheet = false
    @State private var exportData: Data? = nil
    @State private var showImportPicker = false
    // Alert for reset
    @State private var showResetAlert = false
    @State private var showHelp = false

    private var defaultSignatureImage: UIImage? {
        guard let defaultSignature else { return nil }
        return UIImage(data: defaultSignature)
    }

    private var defaultSignatureActions: [SignatureAction] {
        var actions = [
            SignatureAction(
                title: defaultSignatureImage == nil ? "Set Default Signature" : "Replace Default Signature",
                style: .primary,
                action: beginDefaultSignatureCapture
            )
        ]

        if defaultSignatureImage != nil {
            actions.append(
                SignatureAction(
                    title: "Clear Default Signature",
                    style: .destructive,
                    action: clearDefaultSignature
                )
            )
        }

        return actions
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                BrandHeaderView(title: "Settings")
                Form {
                    Section(header:
                                Text("Company Information")
                                .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.0))
                                .fontWeight(.bold)
                    ) {
                        TextField("Company Name", text: $companyName)
                        TextField("Address", text: $companyAddress)
                        TextField("Phone", text: $companyPhone)
                        TextField("Email", text: $companyEmail)
                        TextField("ABN", text: $companyABN)
                        TextField("License Number", text: $companyLicense)
                    }
                    Section(header:
                                Text("Default Tester Information")
                                .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.0))
                                .fontWeight(.bold)
                    ) {
                        TextField("Tester Name", text: $testerName)
                        TextField("License Number", text: $testerLicense)
                    }
                    Section(header:
                                Text("Signature Management")
                                .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.0))
                                .fontWeight(.bold)
                    ) {
                        SignaturePreviewPanel(
                            title: "Default Signature",
                            signatureImage: defaultSignatureImage,
                            statusText: defaultSignatureImage == nil ? "No default signature saved." : "This signature is applied automatically to new reports.",
                            helperText: "Use the full-screen editor to save a clean default signature with Save, Clear, and Cancel controls.",
                            actions: defaultSignatureActions
                        )
                    }
                    Section(header:
                                Text("Appearance")
                                .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.0))
                                .fontWeight(.bold)
                    ) {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }
                    Section(header:
                                Text("Export/Backup")
                                .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.0))
                                .fontWeight(.bold)
                    ) {
                        Button("Export All Reports") {
                            let payload = AppBackupPayload(
                                reports: HistoryStorage.load(),
                                templates: TemplateStorage.load()
                            )
                            if let data = try? JSONEncoder().encode(payload) {
                                exportData = data
                                showExportSheet = true
                            }
                        }
                        .padding(6)
                        .background(Color(red: 1.0, green: 0.88, blue: 0.0))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .sheet(isPresented: $showExportSheet) {
                            if let data = exportData {
                                ActivityView(activityItems: [data])
                            }
                        }
                        Button("Import/Restore Backup") {
                            showImportPicker = true
                        }
                        .padding(6)
                        .background(Color(red: 1.0, green: 0.88, blue: 0.0))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
                            switch result {
                            case .success(let url):
                                if let data = try? Data(contentsOf: url),
                                   let payload = AppBackupPayload.decode(from: data) {
                                    HistoryStorage.save(payload.reports)
                                    TemplateStorage.save(payload.templates)
                                }
                            default: break
                            }
                        }
                    }
                    Section(header:
                                Text("Reset App Data")
                                .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.0))
                                .fontWeight(.bold)
                    ) {
                        Button("Reset All Data") {
                            showResetAlert = true
                        }
                        .foregroundColor(.red)
                    }
                    Section(header:
                                Text("About/Help")
                                .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.0))
                                .fontWeight(.bold)
                    ) {
                        Text("Version 1.0")
                        Text("Support: info@npcontracting.com.au")
                            .foregroundColor(.black)
                        NavigationLink("Test Standards (AS/NZS 3000, 3017, 3008)", destination: StandardsView())
                        Button("In-App Help") { showHelp = true }
                    }
                }
                .alert(isPresented: $showResetAlert) {
                    Alert(
                        title: Text("Reset All Data?"),
                        message: Text("This will delete all saved reports and settings. This action cannot be undone."),
                        primaryButton: .destructive(Text("Reset")) {
                            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                        },
                        secondaryButton: .cancel()
                    )
                }
                .fullScreenCover(isPresented: $showSignatureEditor) {
                    SignatureEditorView(
                        title: "Default Signature",
                        replacementNotice: defaultSignatureImage == nil ? nil : "Saving here will replace the default signature used on new reports."
                    ) { image in
                        defaultSignature = image.pngData()
                    }
                }
                .sheet(isPresented: $showHelp) {
                    HelpView()
                }
                .alert("Replace Default Signature?", isPresented: $showReplaceDefaultSignatureAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Replace", role: .destructive) {
                        showSignatureEditor = true
                    }
                } message: {
                    Text("This will replace the default signature used for new reports.")
                }
            }
        }
    }

    private func beginDefaultSignatureCapture() {
        if defaultSignatureImage != nil {
            showReplaceDefaultSignatureAlert = true
        } else {
            showSignatureEditor = true
        }
    }

    private func clearDefaultSignature() {
        defaultSignature = nil
    }
}

private struct AppBackupPayload: Codable {
    var reports: [ElectricalTestReport]
    var templates: [SavedReportTemplate]

    static func decode(from data: Data) -> AppBackupPayload? {
        let decoder = JSONDecoder()

        if let payload = try? decoder.decode(AppBackupPayload.self, from: data) {
            return payload
        }

        if let reports = try? decoder.decode([ElectricalTestReport].self, from: data) {
            return AppBackupPayload(reports: reports, templates: [])
        }

        return nil
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(red: 1.0, green: 0.88, blue: 0.0))
                    .frame(height: 54)
                    .overlay(
                        HStack {
                            Text("Help & Instructions")
                                .font(.title2).bold()
                                .foregroundColor(.black)
                                .padding(.leading, 16)
                            Spacer()
                        }
                    )
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Group {
                            Text("• Fill out the Electrical Test Report form with all required details, including customer, site address, job number, and test results.")
                            Text("• You can add as many circuit results as needed. The PDF will continue across multiple pages automatically.")
                            Text("• For Cable Size, enter only the number (e.g., 2.5). The unit 'mm²' (millimetres squared) will be added automatically in the PDF.")
                            Text("• For Protection Size and Type, enter only the number (e.g., 20). The unit 'A' (Amps) will be added automatically in the PDF.")
                            Text("• For Earth Continuity and Fault Loop Impedance, enter only the number. The '<' (less than) symbol will be added automatically in the PDF.")
                            Text("• For Insulation Resistance, enter only the number. The '>' (greater than) symbol will be added automatically in the PDF.")
                            Text("• For Pass/Fail fields, simply select Pass or Fail using the provided options.")
                            Text("• Add each circuit result by entering the details and tapping '+ Add Circuit'. You can duplicate, edit, delete, and reorder saved circuits.")
                            Text("• Add optional site photos in the Attachments section. Attached photos are included in the PDF after the result pages.")
                            Text("• Tap 'Review Preview' to check the report, then 'Generate PDF' to create a named PDF file you can share or save.")
                            Text("• All exported reports are saved in the History tab. You can search, preview, share, or use any report as a template.")
                            Text("• Use the Settings tab to update your company and tester information, manage your default signature, and backup or restore your data.")
                            Text("• Default tester details and default signature are applied automatically to new reports.")
                            Text("• Use 'Export All Reports' to back up your data as a ZIP file. Use 'Import/Restore Backup' to restore from a backup file.")
                            Text("• For support, email info@npcontracting.com.au.")
                        }
                        Divider()
                        Text("Frequently Asked Questions (FAQs)")
                            .font(.headline)
                            .padding(.top, 8)
                        Group {
                            Text("Q: How do I add a new test result?\nA: Fill in the circuit entry fields and tap '+ Add Circuit'. The result will appear in the saved circuits list.")
                            Text("Q: What do I enter for Cable Size, Protection Size, Earth Continuity, Fault Loop Impedance, and Insulation Resistance?\nA: Enter only the number. The correct unit or symbol (mm² for millimetres squared, A for Amps, < for less than, > for greater than) will be added automatically in the PDF.")
                            Text("Q: How do I export all reports?\nA: Tap 'Export All Reports' in Settings. The app will export a ZIP file containing your data.")
                            Text("Q: How do I reuse an old report?\nA: In History, tap 'Use as Template' to load that report back into the form for editing.")
                            Text("Q: How do I change my company or tester information?\nA: Go to the Settings tab and update the fields under 'Company Information' and 'Default Tester Information'.")
                            Text("Q: How do I set or update my signature?\nA: In Settings, tap 'Set Default Signature' or 'Replace Default Signature', sign in the full-screen editor, then tap Save Signature.")
                            Text("Q: Can I restore my data if I reinstall the app?\nA: Yes, if you exported a backup ZIP file, you can use 'Import/Restore Backup' in Settings to restore your reports.")
                            Text("Q: Who do I contact for help?\nA: Email info@npcontracting.com.au for support.")
                            Text("Q: Can I add photos?\nA: Yes. Use the Attachments section on the form to add site photos. They will be stored with the report and added to the PDF.")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct PDFToShow: Identifiable, Equatable {
    let name: String
    let title: String
    let searchQueries: [String]

    var id: String {
        [name, title, searchQueries.joined(separator: "|")].joined(separator: "::")
    }
}

struct StandardsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPDF: PDFToShow? = nil
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Standards Reference")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 8)
                Text("Use the following standards as a quick reference when checking electrical test results:")
                HStack(spacing: 8) {
                    Button(action: {
                        showPDF = PDFToShow(name: "AS3000.pdf", title: "AS/NZS 3000:2018", searchQueries: [])
                    }) {
                        Text("AS/NZS 3000:2018").underline().foregroundColor(.blue)
                    }
                    Button(action: {
                        showPDF = PDFToShow(name: "AS3017.pdf", title: "AS/NZS 3017:2022", searchQueries: [])
                    }) {
                        Text("AS/NZS 3017:2022").underline().foregroundColor(.blue)
                    }
                    Button(action: {
                        showPDF = PDFToShow(name: "AS3008.pdf", title: "AS/NZS 3008", searchQueries: [])
                    }) {
                        Text("AS/NZS 3008").underline().foregroundColor(.blue)
                    }
                }
                Text("• AS/NZS 3000: Section 8 - Verification (Testing and Inspection)")
                Text("• AS/NZS 3017: Electrical installations - Verification by inspection and testing")
                Text("• AS/NZS 3008: Electrical Installations - Selection of Cables")
                Divider()
                Group {
                    Text("Typical Verification Checks:")
                        .font(.headline)
                    Text("Quick guide only. Confirm compliance against the current applicable standard, installation type, protective device, and measured result.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Tap any item below to search the bundled PDF at the closest matching table or clause.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button(action: {
                        openReference(
                            pdfName: "AS3000.pdf",
                            title: "AS/NZS 3000 Section 8",
                            searchQueries: ["visual inspection", "section 8", "verification"]
                        )
                    }) {
                        Text("• Visual Inspection: Confirm wiring, connections, and equipment are installed correctly, securely, and free from visible damage or defects in line with AS/NZS 3000 Section 8.")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        openReference(
                            pdfName: "AS3000.pdf",
                            title: "AS/NZS 3000 Table 8.1",
                            searchQueries: ["table 8.1", "earth continuity", "continuity"]
                        )
                    }) {
                        Text("• Earth Continuity: Check the measured resistance against the relevant limits and method in AS/NZS 3000 Table 8.1 and related verification guidance.")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        openReference(
                            pdfName: "AS3000.pdf",
                            title: "AS/NZS 3000 Section 8.3.6",
                            searchQueries: ["8.3.6", "insulation resistance", "section 8.3.6"]
                        )
                    }) {
                        Text("• Insulation Resistance: Verify the measured insulation resistance satisfies the applicable requirement in AS/NZS 3000 Section 8.3.6.")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        openReference(
                            pdfName: "AS3000.pdf",
                            title: "AS/NZS 3000 Section 8.3.7",
                            searchQueries: ["8.3.7", "polarity", "section 8.3.7"]
                        )
                    }) {
                        Text("• Polarity Test: Confirm switches, circuit breakers, and socket-outlets are correctly connected in accordance with AS/NZS 3000 Section 8.3.7.")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        openReference(
                            pdfName: "AS3000.pdf",
                            title: "AS/NZS 3000 Table 8.2",
                            searchQueries: ["table 8.2", "fault loop impedance", "fault-loop impedance", "8.2"]
                        )
                    }) {
                        Text("• Fault Loop Impedance: Compare measured values with the applicable limits in AS/NZS 3000 Table 8.2 for the installed protective device and circuit arrangement.")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        openReference(
                            pdfName: "AS3000.pdf",
                            title: "AS/NZS 3000 Section 8.3.10",
                            searchQueries: ["8.3.10", "RCD", "residual current device", "section 8.3.10"]
                        )
                    }) {
                        Text("• RCD Test: Verify residual current devices operate within the required time and current limits for the installed device and test method.")
                            .foregroundColor(.blue)
                    }
                    Text("• Operational Test: Confirm equipment and safety devices operate correctly in accordance with the manufacturer instructions and applicable standard requirements.")
                }
                Divider()
                Text("Refer to the full standards for detailed requirements, limits, and tables. For more information, consult AS/NZS 3000:2018, AS/NZS 3017:2022, and AS/NZS 3008.")
            }
            .padding()
        }
        .navigationTitle("Test Standards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .sheet(item: $showPDF) { pdfToShow in
            StandardsPDFViewer(
                pdfName: pdfToShow.name,
                referenceTitle: pdfToShow.title,
                initialSearchQueries: pdfToShow.searchQueries
            )
        }
    }

    private func openReference(pdfName: String, title: String, searchQueries: [String]) {
        showPDF = PDFToShow(name: pdfName, title: title, searchQueries: searchQueries)
    }
}

struct StandardsPDFViewer: View {
    let pdfName: String
    let referenceTitle: String
    let initialSearchQueries: [String]
    @State private var searchText = ""
    @State private var pdfDocument: PDFDocument? = nil
    @State private var searchResults: [PDFSelection] = []
    @State private var currentResultIndex: Int = 0
    @State private var bookmarks: [Int: String] = [:] // pageIndex: label
    @State private var showBookmarks = false
    @State private var didApplyInitialSearch = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !referenceTitle.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(referenceTitle)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if !initialSearchQueries.isEmpty {
                            Text("Auto-searching the bundled PDF for the closest matching table or clause.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }

                HStack {
                    TextField("Search", text: $searchText, onCommit: search)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding([.horizontal, .top])
                    if !searchResults.isEmpty {
                        Button(action: previousResult) { Image(systemName: "chevron.up") }
                        Text("\(currentResultIndex + 1)/\(searchResults.count)")
                            .font(.caption)
                            .frame(minWidth: 40)
                        Button(action: nextResult) { Image(systemName: "chevron.down") }
                    }
                    Button(action: { showBookmarks = true }) {
                        Image(systemName: "bookmark")
                    }
                    Button("Close") { dismiss() }
                        .padding(.trailing)
                }
                Divider()
                if let pdfDocument = pdfDocument {
                    PDFKitRepresentedViewWithHighlight(pdfDocument: pdfDocument, selection: currentSelection, onBookmark: addOrRemoveBookmark, bookmarks: bookmarks, goToPage: goToPage)
                } else {
                    Text("PDF not found.")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if let url = Bundle.main.url(forResource: pdfName.replacingOccurrences(of: ".pdf", with: ""), withExtension: "pdf") {
                    let document = PDFDocument(url: url)
                    pdfDocument = document
                    applyInitialSearchIfNeeded(using: document)
                }
            }
            .sheet(isPresented: $showBookmarks) {
                NavigationView {
                    List {
                        ForEach(bookmarks.sorted(by: { $0.key < $1.key }), id: \.key) { (page, label) in
                            Button(action: { goToPage(page); showBookmarks = false }) {
                                HStack {
                                    Text("Page \(page + 1)")
                                    if !label.isEmpty { Text(": \(label)") }
                                }
                            }
                        }
                        .onDelete { indices in
                            for index in indices {
                                let key = Array(bookmarks.keys.sorted())[index]
                                bookmarks.removeValue(forKey: key)
                            }
                        }
                    }
                    .navigationTitle("Bookmarks")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showBookmarks = false }
                        }
                    }
                }
            }
        }
    }

    var currentSelection: PDFSelection? {
        guard !searchResults.isEmpty, currentResultIndex < searchResults.count else { return nil }
        return searchResults[currentResultIndex]
    }

    func search() {
        guard let pdfDocument = pdfDocument, !searchText.isEmpty else {
            searchResults = []
            currentResultIndex = 0
            return
        }
        let results = pdfDocument.findString(searchText, withOptions: .caseInsensitive)
        searchResults = results
        currentResultIndex = 0
        for selection in results { selection.color = .yellow }
    }

    func applyInitialSearchIfNeeded(using document: PDFDocument?) {
        guard !didApplyInitialSearch else { return }
        didApplyInitialSearch = true

        guard let document, !initialSearchQueries.isEmpty else { return }

        for query in initialSearchQueries {
            let results = document.findString(query, withOptions: .caseInsensitive)
            if !results.isEmpty {
                searchText = query
                searchResults = results
                currentResultIndex = 0
                for selection in results { selection.color = .yellow }
                return
            }
        }

        searchText = initialSearchQueries[0]
        searchResults = []
        currentResultIndex = 0
    }

    func nextResult() {
        guard !searchResults.isEmpty else { return }
        currentResultIndex = (currentResultIndex + 1) % searchResults.count
    }

    func previousResult() {
        guard !searchResults.isEmpty else { return }
        currentResultIndex = (currentResultIndex - 1 + searchResults.count) % searchResults.count
    }

    func addOrRemoveBookmark(page: Int, label: String = "") {
        if bookmarks[page] != nil {
            bookmarks.removeValue(forKey: page)
        } else {
            bookmarks[page] = label
        }
    }

    func goToPage(_ page: Int) {
        guard let pdfDocument = pdfDocument, let pdfView = PDFKitRepresentedViewWithHighlight.lastPDFView else { return }
        if let pageObj = pdfDocument.page(at: page) {
            pdfView.go(to: pageObj)
        }
    }
}

struct PDFKitRepresentedViewWithHighlight: UIViewRepresentable {
    let pdfDocument: PDFDocument
    let selection: PDFSelection?
    let onBookmark: (Int, String) -> Void
    let bookmarks: [Int: String]
    let goToPage: (Int) -> Void
    static var lastPDFView: PDFView? = nil

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        PDFKitRepresentedViewWithHighlight.lastPDFView = pdfView
        addBookmarkButton(to: pdfView, context: context)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = pdfDocument
        if let selection = selection, !selection.pages.isEmpty {
            pdfView.go(to: selection)
            pdfView.setCurrentSelection(selection, animate: true)
            pdfView.highlightedSelections = [selection]
        } else {
            pdfView.highlightedSelections = nil
        }
        addBookmarkButton(to: pdfView, context: context)
    }

    private func addBookmarkButton(to pdfView: PDFView, context: Context) {
        pdfView.subviews.filter { $0 is UIButton && $0.tag == 9999 }.forEach { $0.removeFromSuperview() }
        let button = UIButton(type: .system)
        button.setTitle("Bookmark", for: .normal)
        button.tag = 9999
        button.addTarget(context.coordinator, action: #selector(Coordinator.bookmarkTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        pdfView.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor, constant: -16),
            button.topAnchor.constraint(equalTo: pdfView.topAnchor, constant: 16)
        ])
        context.coordinator.onBookmark = onBookmark
        context.coordinator.pdfView = pdfView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var onBookmark: ((Int, String) -> Void)?
        weak var pdfView: PDFView?
        @objc func bookmarkTapped() {
            guard let pdfView = pdfView, let page = pdfView.currentPage, let pageIndex = pdfView.document?.index(for: page) else { return }
            onBookmark?(pageIndex, "")
        }
    }
} 
