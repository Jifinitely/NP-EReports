import SwiftUI

struct TestResultsPreviewView: View {
    @ObservedObject var viewModel: FormViewModel
    @Binding var selectedTab: Int
    @State private var showPDFPreview = false
    @State private var showValidationAlert = false
    @State private var generatedReport: ElectricalTestReport? = nil

    private let brandYellow = Color.npBrandYellow

    var body: some View {
        VStack(spacing: 0) {
            BrandHeaderView(title: "Preview")

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.previewValidationIssues.isEmpty {
                        PreviewValidationCard(messages: viewModel.previewValidationIssues)
                    }

                    PreviewSection(title: "Job Summary", brandYellow: brandYellow) {
                        PreviewRow(title: "Customer", value: viewModel.customer)
                        PreviewRow(title: "Site Address", value: viewModel.siteAddress)
                        PreviewRow(title: "Switchboard Location", value: viewModel.switchboardLocation)
                        PreviewRow(title: "Building Number", value: viewModel.buildingNumber)
                        PreviewRow(title: "Job Number", value: viewModel.jobNumber)
                        PreviewRow(title: "Chassis ID", value: viewModel.chassisID)
                        PreviewRow(title: "Total Circuits", value: "\(viewModel.testResults.count)")
                        PreviewRow(title: "Photos", value: "\(viewModel.attachments.count)")
                    }

                    PreviewSection(
                        title: "Circuit Results (\(viewModel.testResults.count))",
                        brandYellow: brandYellow
                    ) {
                        if viewModel.testResults.isEmpty {
                            Text("No saved circuits to preview yet.")
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(viewModel.testResults.enumerated()), id: \.element.id) { index, result in
                                    CircuitPreviewCard(index: index + 1, result: result)
                                }
                            }
                        }
                    }

                    PreviewSection(
                        title: "Attachments (\(viewModel.attachments.count))",
                        brandYellow: brandYellow
                    ) {
                        if viewModel.attachments.isEmpty {
                            Text("No site photos attached.")
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.attachments) { attachment in
                                        VStack(alignment: .leading, spacing: 8) {
                                            if let image = UIImage(data: attachment.imageData) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 180, height: 120)
                                                    .clipped()
                                                    .cornerRadius(12)
                                            }

                                            Text(attachment.fileName)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 180)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            VStack(spacing: 12) {
                Button(action: {
                    selectedTab = 0
                }) {
                    Text("Back to Form")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .foregroundColor(brandYellow)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button(action: generatePDF) {
                    Text("Generate PDF")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(brandYellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.npSurface)
        }
        .background(Color.npBackground)
        .navigationBarHidden(true)
        .alert(isPresented: $showValidationAlert) {
            Alert(
                title: Text("Missing Information"),
                message: Text(viewModel.previewValidationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showPDFPreview) {
            if let generatedReport = generatedReport {
                PDFPreviewView(report: generatedReport, signature: viewModel.signatureImage)
            }
        }
    }

    private func generatePDF() {
        guard viewModel.isFormValid else {
            showValidationAlert = true
            return
        }

        let report = viewModel.toElectricalTestReport()
        generatedReport = report

        var reports = HistoryStorage.load()
        if let existingIndex = reports.firstIndex(where: { $0.id == report.id }) {
            reports[existingIndex] = report
        } else {
            reports.append(report)
        }
        HistoryStorage.save(reports)
        showPDFPreview = true
    }
}

private struct PreviewValidationCard: View {
    let messages: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Report Not Ready Yet")
                .font(.headline)
                .foregroundColor(.red)

            ForEach(messages, id: \.self) { message in
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

private struct PreviewSection<Content: View>: View {
    let title: String
    let brandYellow: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(brandYellow)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
            .background(Color.npSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(brandYellow, lineWidth: 1.5)
            )
            .cornerRadius(14)
        }
    }
}

private struct PreviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            Spacer(minLength: 12)
            Text(displayValue(value))
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func displayValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not provided" : value
    }
}

private struct CircuitPreviewCard: View {
    let index: Int
    let result: TestResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Circuit \(index)")
                .font(.headline)
                .foregroundColor(.primary)

            if !result.isComplete {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Missing required fields")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)

                    ForEach(result.missingRequiredFields, id: \.self) { field in
                        Label("\(field) is required.", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(12)
                .background(Color.red.opacity(0.08))
                .cornerRadius(12)
            }

            PreviewRow(title: "Test Date", value: result.testDate)
            PreviewRow(title: "Circuit / Equipment", value: result.circuitOrEquipment)
            PreviewRow(title: "Visual Inspection", value: result.visualInspection)
            PreviewRow(title: "Circuit No.", value: result.circuitNo)
            PreviewRow(title: "Cable Size", value: result.cableSize)
            PreviewRow(title: "Protection", value: result.protectionSizeType)
            PreviewRow(title: "Neutral No.", value: result.neutralNo)
            PreviewRow(title: "Earth Continuity", value: result.earthContinuity)
            PreviewRow(title: "RCD", value: result.rcd)
            PreviewRow(title: "Insulation Resistance", value: result.insulationResistance)
            PreviewRow(title: "Polarity Test", value: result.polarityTest)
            PreviewRow(title: "Fault Loop Impedance", value: result.faultLoopImpedance)
            PreviewRow(title: "Operational Test", value: result.operationalTest)
        }
        .padding(16)
        .background(Color.npSecondarySurface)
        .cornerRadius(14)
    }
}
