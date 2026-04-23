import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: FormViewModel
    @Binding var selectedTab: Int

    @State private var reports: [ElectricalTestReport] = HistoryStorage.load()
    @State private var templates: [SavedReportTemplate] = TemplateStorage.load()
    @State private var searchText = ""
    @State private var shareURL: URL? = nil
    @State private var showShareSheet = false
    @State private var previewReport: ElectricalTestReport? = nil
    @State private var contentMode: HistoryContentMode = .reports
    @State private var reportFilter: ReportFilter = .active
    @State private var renameTarget: ElectricalTestReport? = nil
    @State private var templateCreationContext: TemplateCreationContext? = nil

    var body: some View {
        VStack(spacing: 0) {
            BrandHeaderView(title: "History")

            VStack(spacing: 12) {
                Picker("Content", selection: $contentMode) {
                    ForEach(HistoryContentMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if contentMode == .reports {
                    Picker("Report Filter", selection: $reportFilter) {
                        ForEach(ReportFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
            .background(Color.npSurface)

            Group {
                switch contentMode {
                case .reports:
                    reportsContent
                case .templates:
                    templatesContent
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color.npBackground)
        .searchable(text: $searchText, prompt: contentMode.searchPrompt)
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ActivityView(activityItems: [shareURL])
            }
        }
        .sheet(item: $previewReport) { report in
            PDFPreviewView(
                report: report,
                signature: report.signatureData.flatMap(UIImage.init(data:))
            )
        }
        .sheet(item: $renameTarget) { report in
            RenameReportSheet(initialName: report.reportTitle.isEmpty ? report.displayTitle : report.reportTitle) { newTitle in
                renameReport(report, newTitle: newTitle)
            }
        }
        .sheet(item: $templateCreationContext) { context in
            SaveTemplateSheet(
                initialName: context.report.suggestedTemplateName(for: context.scope),
                scope: context.scope
            ) { name in
                saveTemplate(from: context.report, scope: context.scope, name: name)
            }
        }
        .onAppear {
            refreshContent()
        }
    }

    private var reportsContent: some View {
        Group {
            if filteredReports.isEmpty {
                HistoryEmptyState(
                    title: searchText.isEmpty ? "No reports yet." : "No matching reports found.",
                    message: searchText.isEmpty ? "Generated PDFs will appear here for preview, sharing, templates, and lifecycle tracking." : "Try a different search term or switch the report filter."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredReports) { report in
                            ReportHistoryCard(
                                report: report,
                                onUseAsTemplate: { useAsTemplate(report) },
                                onPreview: { previewReport = report },
                                onShare: { shareReport(report) },
                                onRename: { renameTarget = report },
                                onSaveBoardTemplate: { templateCreationContext = TemplateCreationContext(report: report, scope: .board) },
                                onSaveCircuitTemplate: { templateCreationContext = TemplateCreationContext(report: report, scope: .circuitsOnly) },
                                onSetStatus: { setStatus($0, for: report) },
                                onToggleArchive: { toggleArchive(report) },
                                onDelete: { deleteReport(report) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var templatesContent: some View {
        Group {
            if filteredTemplates.isEmpty {
                HistoryEmptyState(
                    title: searchText.isEmpty ? "No saved templates." : "No matching templates found.",
                    message: searchText.isEmpty ? "Save board templates or circuit sets from report history to reuse them on the form." : "Try a different template name, site, or switchboard search."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredTemplates) { template in
                            SavedTemplateCard(
                                template: template,
                                onApply: { applyTemplate(template) },
                                onPreview: { previewReport = template.reportSnapshot },
                                onDelete: { deleteTemplate(template) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var filteredReports: [ElectricalTestReport] {
        let visibleReports = reports.filter { report in
            switch reportFilter {
            case .active:
                return !report.isArchived
            case .archived:
                return report.isArchived
            case .all:
                return true
            }
        }
        .sorted { $0.date > $1.date }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return visibleReports }

        return visibleReports.filter { report in
            [
                report.displayTitle,
                report.customer,
                report.siteAddress,
                report.switchboardLocation,
                report.jobNumber,
                report.chassisID,
                report.lifecycleSummary,
                historyDateFormatter.string(from: report.date)
            ]
            .contains { $0.lowercased().contains(query) }
        }
    }

    private var filteredTemplates: [SavedReportTemplate] {
        let sortedTemplates = templates.sorted { $0.createdAt > $1.createdAt }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return sortedTemplates }

        return sortedTemplates.filter { template in
            [
                template.displayName,
                template.scope.label,
                template.reportSnapshot.customer,
                template.reportSnapshot.siteAddress,
                template.reportSnapshot.switchboardLocation,
                template.reportSnapshot.jobNumber
            ]
            .contains { $0.lowercased().contains(query) }
        }
    }

    private func refreshContent() {
        reports = HistoryStorage.load()
        templates = TemplateStorage.load()
    }

    private func deleteReport(_ report: ElectricalTestReport) {
        reports.removeAll { $0.id == report.id }
        HistoryStorage.save(reports)
    }

    private func renameReport(_ report: ElectricalTestReport, newTitle: String) {
        updateReport(report) { storedReport in
            storedReport.reportTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func setStatus(_ status: ReportLifecycleStatus, for report: ElectricalTestReport) {
        updateReport(report) { storedReport in
            storedReport.lifecycleStatus = status
        }
    }

    private func toggleArchive(_ report: ElectricalTestReport) {
        updateReport(report) { storedReport in
            storedReport.isArchived.toggle()
        }
    }

    private func updateReport(_ report: ElectricalTestReport, mutate: (inout ElectricalTestReport) -> Void) {
        guard let index = reports.firstIndex(where: { $0.id == report.id }) else { return }
        mutate(&reports[index])
        HistoryStorage.save(reports)
    }

    private func useAsTemplate(_ report: ElectricalTestReport) {
        viewModel.loadTemplate(from: report)
        selectedTab = 0
    }

    private func saveTemplate(from report: ElectricalTestReport, scope: TemplateScope, name: String) {
        let template = SavedReportTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            scope: scope,
            reportSnapshot: report.templateSnapshot(for: scope)
        )
        templates.insert(template, at: 0)
        TemplateStorage.save(templates)
    }

    private func applyTemplate(_ template: SavedReportTemplate) {
        viewModel.applySavedTemplate(template)
        selectedTab = 0
    }

    private func deleteTemplate(_ template: SavedReportTemplate) {
        templates.removeAll { $0.id == template.id }
        TemplateStorage.save(templates)
    }

    private func shareReport(_ report: ElectricalTestReport) {
        guard let pdfData = PDFGenerator.generatePDF(
            report: report,
            signature: report.signatureData.flatMap(UIImage.init(data:))
        ) else {
            return
        }

        shareURL = try? ReportExportHelper.makeTemporaryPDFURL(report: report, data: pdfData)
        showShareSheet = shareURL != nil
    }
}

private enum HistoryContentMode: String, CaseIterable, Identifiable {
    case reports
    case templates

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reports:
            return "Reports"
        case .templates:
            return "Templates"
        }
    }

    var searchPrompt: String {
        switch self {
        case .reports:
            return "Search title, customer, site, job or status"
        case .templates:
            return "Search templates, site or switchboard"
        }
    }
}

private enum ReportFilter: String, CaseIterable, Identifiable {
    case active
    case archived
    case all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .active:
            return "Active"
        case .archived:
            return "Archived"
        case .all:
            return "All"
        }
    }
}

private struct TemplateCreationContext: Identifiable {
    let id = UUID()
    let report: ElectricalTestReport
    let scope: TemplateScope
}

private struct ReportHistoryCard: View {
    let report: ElectricalTestReport
    let onUseAsTemplate: () -> Void
    let onPreview: () -> Void
    let onShare: () -> Void
    let onRename: () -> Void
    let onSaveBoardTemplate: () -> Void
    let onSaveCircuitTemplate: () -> Void
    let onSetStatus: (ReportLifecycleStatus) -> Void
    let onToggleArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(report.displayTitle)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if !report.siteAddress.isEmpty {
                        Text(report.siteAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    LifecycleBadge(status: report.lifecycleStatus)

                    if report.isArchived {
                        Text("Archived")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.18))
                            .foregroundColor(.secondary)
                            .cornerRadius(999)
                    }
                }
            }

            HStack(spacing: 10) {
                HistoryMetaPill(title: "Job", value: report.jobNumber)
                HistoryMetaPill(title: "Date", value: historyDateFormatter.string(from: report.date))
                HistoryMetaPill(title: "Circuits", value: "\(report.testResults.count)")
                HistoryMetaPill(title: "Photos", value: "\(report.attachments.count)")
            }

            HStack(spacing: 12) {
                HistoryActionButton(
                    title: "Use as Template",
                    background: .black,
                    foreground: .npBrandYellow,
                    action: onUseAsTemplate
                )

                HistoryActionButton(
                    title: "Preview",
                    background: .npBrandYellow,
                    foreground: .black,
                    action: onPreview
                )

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Color.npBrandYellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Menu {
                    Button("Rename Report", action: onRename)

                    Divider()

                    ForEach(ReportLifecycleStatus.allCases) { status in
                        Button(status.label) {
                            onSetStatus(status)
                        }
                    }

                    Divider()

                    Button(report.isArchived ? "Restore to Active" : "Archive Report", action: onToggleArchive)
                    Button("Save Board Template", action: onSaveBoardTemplate)
                    Button("Save Circuit Set", action: onSaveCircuitTemplate)

                    Divider()

                    Button("Delete Report", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color.npSecondarySurface)
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.npSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.npBrandYellow.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct SavedTemplateCard: View {
    let template: SavedReportTemplate
    let onApply: () -> Void
    let onPreview: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(templateSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(template.scope.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.npBrandYellow.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(999)
            }

            HStack(spacing: 10) {
                HistoryMetaPill(title: "Circuits", value: "\(template.circuitCount)")
                HistoryMetaPill(title: "Saved", value: historyDateFormatter.string(from: template.createdAt))
                HistoryMetaPill(title: "Board", value: template.reportSnapshot.switchboardLocation)
            }

            HStack(spacing: 12) {
                HistoryActionButton(
                    title: template.scope.applyButtonTitle,
                    background: .black,
                    foreground: .npBrandYellow,
                    action: onApply
                )

                HistoryActionButton(
                    title: "Preview",
                    background: .npBrandYellow,
                    foreground: .black,
                    action: onPreview
                )

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.npSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.npBrandYellow.opacity(0.3), lineWidth: 1)
        )
    }

    private var templateSubtitle: String {
        let parts = [
            template.reportSnapshot.customer,
            template.reportSnapshot.siteAddress,
            template.reportSnapshot.switchboardLocation
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        return parts.isEmpty ? "Reusable saved template" : parts.joined(separator: " • ")
    }
}

private struct HistoryActionButton: View {
    let title: String
    let background: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(background)
                .foregroundColor(foreground)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct LifecycleBadge: View {
    let status: ReportLifecycleStatus

    var body: some View {
        Text(status.label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(999)
    }

    private var backgroundColor: Color {
        switch status {
        case .inProgress:
            return Color.orange.opacity(0.2)
        case .complete:
            return Color.green.opacity(0.18)
        case .sent:
            return Color.blue.opacity(0.18)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .inProgress:
            return .orange
        case .complete:
            return .green
        case .sent:
            return .blue
        }
    }
}

private struct HistoryMetaPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)

            Text(displayValue)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.npSecondarySurface)
        .cornerRadius(12)
    }

    private var displayValue: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not set" : value
    }
}

private struct HistoryEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

private struct RenameReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    let onSave: (String) -> Void

    init(initialName: String, onSave: @escaping (String) -> Void) {
        _name = State(initialValue: initialName)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Report Title") {
                    TextField("Enter a report title", text: $name)
                }

                Section {
                    Text("Leave this blank if you want the history card to keep using the customer or switchboard name.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Rename Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SaveTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    let scope: TemplateScope
    let onSave: (String) -> Void

    init(initialName: String, scope: TemplateScope, onSave: @escaping (String) -> Void) {
        _name = State(initialValue: initialName)
        self.scope = scope
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Template Name") {
                    TextField("Enter a template name", text: $name)
                }

                Section("Template Type") {
                    Text(scope.label)
                        .font(.body.bold())

                    Text(scopeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Save Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name)
                        dismiss()
                    }
                }
            }
        }
    }

    private var scopeDescription: String {
        switch scope {
        case .board:
            return "Board templates keep the board/job details and saved circuits, but they leave photos and signatures behind."
        case .circuitsOnly:
            return "Circuit sets only reuse the saved circuits, so you can drop them into a new job without replacing the current job details."
        }
    }
}

private let historyDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

struct HistoryStorage {
    static let key = "exported_reports"

    static func load() -> [ElectricalTestReport] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let reports = try? JSONDecoder().decode([ElectricalTestReport].self, from: data) else {
            return []
        }
        return reports
    }

    static func save(_ reports: [ElectricalTestReport]) {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct TemplateStorage {
    static let key = "saved_report_templates"

    static func load() -> [SavedReportTemplate] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let templates = try? JSONDecoder().decode([SavedReportTemplate].self, from: data) else {
            return []
        }
        return templates
    }

    static func save(_ templates: [SavedReportTemplate]) {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
