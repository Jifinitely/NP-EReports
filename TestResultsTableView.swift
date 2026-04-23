//
//  TestResultsTableView.swift
//  ElectricalTestReportApp
//
//  Created by Jeff Chadkirk on 29/4/2025.
//

// Views/TestResultsTableView.swift
import SwiftUI

struct TestResultsTableView: View {
    @Binding var testResults: [TestResult]
    let showValidationErrors: Bool
    @State private var newResult = TestResult.blank()
    @State private var newTestDate = Date()
    @State private var editingResult: TestResult? = nil
    @State private var showEditModal = false
    @State private var showEntryValidationErrors = false

    private let brandYellow = Color.npBrandYellow

    private var canAddCircuit: Bool {
        currentCircuitValidationIssues.isEmpty
    }

    private var currentCircuitValidationIssues: [String] {
        var result = newResult
        result.testDate = Self.testDateFormatter.string(from: newTestDate)
        return result.missingRequiredFields
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TestResultsSection(title: "Circuit Entry", brandYellow: brandYellow) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Add one circuit result at a time. Use the guided controls below to keep the PDF output consistent.")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    if showEntryValidationErrors, !currentCircuitValidationIssues.isEmpty {
                        ValidationNotice(
                            title: "Finish This Circuit Entry",
                            messages: currentCircuitValidationIssues.map { "\($0) is required." }
                        )
                    }

                    DatePicker("Test Date", selection: $newTestDate, displayedComponents: .date)

                    EntryTextField(
                        title: "Circuit / Equipment",
                        placeholder: "Lighting, GPO, A/C, Pump",
                        text: $newResult.circuitOrEquipment,
                        errorMessage: currentCircuitErrorMessage(for: "Circuit / Equipment")
                    )

                    VisualInspectionHelperField(
                        value: $newResult.visualInspection,
                        errorMessage: currentCircuitErrorMessage(for: "Visual Inspection")
                    )

                    IdentifierField(
                        title: "Circuit No.",
                        placeholder: "C1",
                        text: $newResult.circuitNo,
                        helperText: "Uppercase letters, numbers, spaces, dash and slash only.",
                        errorMessage: currentCircuitErrorMessage(for: "Circuit No.")
                    )

                    StructuredCableSizeField(
                        value: $newResult.cableSize,
                        errorMessage: currentCircuitErrorMessage(for: "Cable Size")
                    )

                    StructuredProtectionField(
                        value: $newResult.protectionSizeType,
                        errorMessage: currentCircuitErrorMessage(for: "Protection")
                    )

                    IdentifierField(
                        title: "Neutral No.",
                        placeholder: "N1",
                        text: $newResult.neutralNo,
                        helperText: "Uppercase letters, numbers, spaces, dash and slash only.",
                        errorMessage: currentCircuitErrorMessage(for: "Neutral No.")
                    )

                    EarthContinuityHelperField(
                        value: $newResult.earthContinuity,
                        errorMessage: currentCircuitErrorMessage(for: "Earth Continuity")
                    )

                    StructuredRCDField(
                        value: $newResult.rcd,
                        errorMessage: currentCircuitErrorMessage(for: "RCD")
                    )

                    InsulationResistanceHelperField(
                        value: $newResult.insulationResistance,
                        errorMessage: currentCircuitErrorMessage(for: "Insulation Resistance")
                    )

                    PolarityHelperField(
                        value: $newResult.polarityTest,
                        errorMessage: currentCircuitErrorMessage(for: "Polarity Test")
                    )

                    FaultLoopImpedanceHelperField(
                        value: $newResult.faultLoopImpedance,
                        protectionValue: $newResult.protectionSizeType,
                        errorMessage: currentCircuitErrorMessage(for: "Fault Loop Impedance")
                    )

                    PassFailField(
                        title: "Operational Test",
                        selection: $newResult.operationalTest,
                        helperText: "Record whether the circuit or equipment operated correctly.",
                        errorMessage: currentCircuitErrorMessage(for: "Operational Test")
                    )

                    Button(action: attemptAddCircuit) {
                        Text("+ Add Circuit")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .padding(.vertical, 14)
                            .background(canAddCircuit ? brandYellow : Color(.systemGray5))
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: resetCircuitEntry) {
                        Text("Clear Current Entry")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .foregroundColor(brandYellow)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Text("Saved circuits can be duplicated and reordered below.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            TestResultsSection(
                title: "Saved Circuits (\(testResults.count))",
                brandYellow: brandYellow
            ) {
                if testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No circuits added yet.")
                            .foregroundColor(.secondary)

                        if showValidationErrors {
                            InlineValidationText(message: "Add at least one complete circuit before previewing or generating the PDF.")
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(testResults.enumerated()), id: \.element.id) { index, result in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Circuit \(index + 1)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(result.circuitOrEquipment.isEmpty ? "Not provided" : result.circuitOrEquipment)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(displayValue(result.testDate))
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }

                                if !result.isComplete {
                                    ValidationNotice(
                                        title: "Circuit \(index + 1) Is Incomplete",
                                        messages: result.missingRequiredFields.map { "\($0) is required." }
                                    )
                                }

                                savedCircuitRow("Visual Inspection", value: result.visualInspection)
                                savedCircuitRow("Circuit No.", value: result.circuitNo)
                                savedCircuitRow("Cable Size", value: result.cableSize)
                                savedCircuitRow("Protection", value: result.protectionSizeType)
                                savedCircuitRow("Neutral No.", value: result.neutralNo)
                                savedCircuitRow("Earth Continuity", value: result.earthContinuity)
                                savedCircuitRow("RCD", value: result.rcd)
                                savedCircuitRow("Insulation Resistance", value: result.insulationResistance)
                                savedCircuitRow("Polarity Test", value: result.polarityTest)
                                savedCircuitRow("Fault Loop Impedance", value: result.faultLoopImpedance)
                                savedCircuitRow("Operational Test", value: result.operationalTest)

                                HStack(spacing: 12) {
                                    Button(action: {
                                        duplicateCircuit(result)
                                    }) {
                                        Text("Duplicate")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.black)
                                            .foregroundColor(brandYellow)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: {
                                        editingResult = result
                                        showEditModal = true
                                    }) {
                                        Text("Edit")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(brandYellow)
                                            .foregroundColor(.black)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)

                                    Button(role: .destructive, action: {
                                        removeCircuit(result)
                                    }) {
                                        Text("Delete")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }

                                HStack(spacing: 12) {
                                    Button(action: {
                                        moveCircuit(result, direction: -1)
                                    }) {
                                        Label("Move Up", systemImage: "arrow.up")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemGray5))
                                            .foregroundColor(.black)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isFirst(result))

                                    Button(action: {
                                        moveCircuit(result, direction: 1)
                                    }) {
                                        Label("Move Down", systemImage: "arrow.down")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemGray5))
                                            .foregroundColor(.black)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isLast(result))
                                }
                            }
                            .padding(16)
                            .background(Color.npSecondarySurface)
                            .cornerRadius(14)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditModal) {
            if let editingResult = editingResult,
               let idx = testResults.firstIndex(where: { $0.id == editingResult.id }) {
                TestResultEditView(result: $testResults[idx], isPresented: $showEditModal)
            }
        }
    }

    private func savedCircuitRow(_ title: String, value: String) -> some View {
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

    private func currentCircuitErrorMessage(for field: String) -> String? {
        guard showEntryValidationErrors else { return nil }
        return currentCircuitValidationIssues.contains(field) ? "\(field) is required." : nil
    }

    private func attemptAddCircuit() {
        showEntryValidationErrors = true
        guard canAddCircuit else { return }

        var result = newResult
        result.testDate = Self.testDateFormatter.string(from: newTestDate)
        testResults.append(result)
        resetCircuitEntry()
    }

    private func removeCircuit(_ result: TestResult) {
        guard let index = testResults.firstIndex(where: { $0.id == result.id }) else { return }
        testResults.remove(at: index)
    }

    private func duplicateCircuit(_ result: TestResult) {
        guard let index = testResults.firstIndex(where: { $0.id == result.id }) else { return }
        testResults.insert(result.duplicated(), at: index + 1)
    }

    private func moveCircuit(_ result: TestResult, direction: Int) {
        guard let currentIndex = testResults.firstIndex(where: { $0.id == result.id }) else { return }

        let targetIndex = currentIndex + direction
        guard testResults.indices.contains(targetIndex) else { return }

        let movedItem = testResults.remove(at: currentIndex)
        testResults.insert(movedItem, at: targetIndex)
    }

    private func isFirst(_ result: TestResult) -> Bool {
        testResults.first?.id == result.id
    }

    private func isLast(_ result: TestResult) -> Bool {
        testResults.last?.id == result.id
    }

    private func resetCircuitEntry() {
        newResult = .blank()
        newTestDate = Date()
        showEntryValidationErrors = false
    }

    fileprivate static let testDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

private struct TestResultsSection<Content: View>: View {
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

private struct ValidationNotice: View {
    let title: String
    let messages: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.red)

            ForEach(messages, id: \.self) { message in
                InlineValidationText(message: message)
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct InlineValidationText: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundColor(.red)
    }
}

private struct EntryTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization = .sentences
    var helperText: String? = nil
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .autocorrectionDisabled()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(errorMessage == nil ? Color.clear : Color.red, lineWidth: 1)
                )

            if let helperText {
                Text(helperText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
    }
}

private struct IdentifierField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var helperText: String? = nil
    var errorMessage: String? = nil

    var body: some View {
        EntryTextField(
            title: title,
            placeholder: placeholder,
            text: $text,
            textInputAutocapitalization: .characters,
            helperText: helperText,
            errorMessage: errorMessage
        )
        .onChange(of: text) { _, newValue in
            let sanitized = newValue.sanitizedIdentifier
            if sanitized != newValue {
                text = sanitized
            }
        }
    }
}

private struct MeasurementField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let unit: String
    var helperText: String? = nil
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            HStack(spacing: 10) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(errorMessage == nil ? Color.clear : Color.red, lineWidth: 1)
                    )

                Text(unit)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.npFieldSurface)
                    .cornerRadius(8)
            }

            if let helperText {
                Text(helperText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
    }
}

private struct StructuredCableSizeField: View {
    @Binding var value: String
    var errorMessage: String? = nil
    @State private var state = CableSizeInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cable Size")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Menu {
                ForEach(CableSizeInputState.commonOptions, id: \.self) { option in
                    Button(option.isEmpty ? "Not Set" : option) {
                        state.selection = option
                        if option != "Other" {
                            state.customValue = ""
                        }
                    }
                }
            } label: {
                HStack {
                    Text(state.selectionLabel)
                        .foregroundColor(state.selection.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.npFieldSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(errorMessage == nil ? Color(uiColor: .separator) : .red, lineWidth: 1)
                )
                .cornerRadius(10)
            }

            if state.selection == "Other" {
                EntryTextField(
                    title: "Custom Cable Size",
                    placeholder: "e.g. 2 x 2.5",
                    text: $state.customValue,
                    helperText: "Use this if the size is not in the common list."
                )
            }

            if !state.summary.isEmpty {
                Text("Saved as: \(state.summary)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Choose a common cable size or enter a custom one. The PDF adds mm² automatically.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        .onAppear {
            state = CableSizeInputState.parse(value)
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.summary
            if value != newValue {
                value = newValue
            }
        }
        .onChange(of: value) { _, newValue in
            let parsedState = CableSizeInputState.parse(newValue)
            if parsedState != state {
                state = parsedState
            }
        }
    }
}

private struct CableSizeInputState: Equatable {
    static let commonOptions = ["", "1.0", "1.5", "2.5", "4", "6", "10", "16", "25", "35", "50", "70", "95", "120", "Other"]

    var selection = ""
    var customValue = ""

    var selectionLabel: String {
        selection.isEmpty ? "Select Cable Size" : selection
    }

    var summary: String {
        selection == "Other" ? customValue.normalizedFieldValue : selection
    }

    static func parse(_ rawValue: String) -> CableSizeInputState {
        let trimmedValue = rawValue.normalizedFieldValue

        guard !trimmedValue.isEmpty else {
            return CableSizeInputState()
        }

        if let match = commonOptions.first(where: { option in
            !option.isEmpty && option != "Other" && option == trimmedValue
        }) {
            return CableSizeInputState(selection: match, customValue: "")
        }

        return CableSizeInputState(selection: "Other", customValue: trimmedValue)
    }
}

private struct PassFailField: View {
    let title: String
    @Binding var selection: String
    var helperText: String? = nil
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Picker(title, selection: $selection) {
                Text("Not Set").tag("")
                Text("Pass").tag("Pass")
                Text("Fail").tag("Fail")
            }
            .pickerStyle(.segmented)

            if let helperText {
                Text(helperText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
    }
}

private enum SuggestedAssessment {
    case pass
    case fail
    case needsReference
    case notApplicable

    var title: String {
        switch self {
        case .pass:
            return "Pass"
        case .fail:
            return "Fail"
        case .needsReference:
            return "Needs Reference"
        case .notApplicable:
            return "N/A"
        }
    }

    var tint: Color {
        switch self {
        case .pass:
            return .green
        case .fail:
            return .red
        case .needsReference:
            return .orange
        case .notApplicable:
            return .secondary
        }
    }

    var icon: String {
        switch self {
        case .pass:
            return "checkmark.circle.fill"
        case .fail:
            return "xmark.octagon.fill"
        case .needsReference:
            return "book.closed.fill"
        case .notApplicable:
            return "minus.circle.fill"
        }
    }
}

private struct AssessmentHelperCard: View {
    let outcome: SuggestedAssessment
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: outcome.icon)
                    .foregroundColor(outcome.tint)
                Text("Suggested assessment: \(outcome.title)")
                    .font(.caption.bold())
                    .foregroundColor(outcome.tint)
            }

            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(outcome.tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(outcome.tint.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct EarthContinuityHelperField: View {
    @Binding var value: String
    var errorMessage: String? = nil

    private var trimmedValue: String {
        value.normalizedFieldValue
    }

    private var assessment: SuggestedAssessment? {
        guard !trimmedValue.isEmpty else { return nil }
        return .needsReference
    }

    private var assessmentMessage: String {
        if trimmedValue.numericDoubleValue == nil {
            return "Enter a numeric earth continuity reading, then compare it with AS/NZS 3000 Table 8.1 for the relevant conductor and circuit type."
        }

        return "Use AS/NZS 3000 Table 8.1 and the specific conductor/circuit context to decide pass or fail for this continuity reading."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MeasurementField(
                title: "Earth Continuity",
                placeholder: "0.24",
                text: $value,
                unit: "Ω",
                helperText: "Numbers only. The PDF adds the < symbol.",
                errorMessage: errorMessage
            )

            if let assessment {
                AssessmentHelperCard(outcome: assessment, message: assessmentMessage)
            }
        }
    }
}

private struct InsulationResistanceHelperField: View {
    @Binding var value: String
    var errorMessage: String? = nil

    private var trimmedValue: String {
        value.normalizedFieldValue
    }

    private var assessment: SuggestedAssessment? {
        guard let reading = trimmedValue.numericDoubleValue else {
            return trimmedValue.isEmpty ? nil : .needsReference
        }

        return reading >= 1 ? .pass : .fail
    }

    private var assessmentMessage: String {
        guard let reading = trimmedValue.numericDoubleValue else {
            return "Enter a numeric insulation resistance value. Confirm the applicable test setup and AS/NZS 3000 Section 8.3.6 requirements before deciding pass or fail."
        }

        if reading >= 1 {
            return "This reading meets the usual >1 MΩ benchmark. Confirm the applicable test voltage and AS/NZS 3000 Section 8.3.6 requirements before final sign-off."
        }

        return "This reading is below the usual >1 MΩ benchmark. Investigate and confirm against AS/NZS 3000 Section 8.3.6 before marking the circuit as acceptable."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MeasurementField(
                title: "Insulation Resistance",
                placeholder: "200",
                text: $value,
                unit: "MΩ",
                helperText: "Numbers only. The PDF adds the > symbol.",
                errorMessage: errorMessage
            )

            if let assessment {
                AssessmentHelperCard(outcome: assessment, message: assessmentMessage)
            }
        }
    }
}

private struct FaultLoopImpedanceHelperField: View {
    @Binding var value: String
    @Binding var protectionValue: String
    var errorMessage: String? = nil

    private var trimmedValue: String {
        value.normalizedFieldValue
    }

    private var trimmedProtection: String {
        protectionValue.normalizedFieldValue
    }

    private var protectionState: ProtectionInputState {
        ProtectionInputState.parse(protectionValue)
    }

    private var assessment: SuggestedAssessment? {
        guard !trimmedValue.isEmpty else { return nil }
        return .needsReference
    }

    private var assessmentMessage: String {
        guard trimmedValue.numericDoubleValue != nil else {
            return "Enter a numeric fault loop impedance reading, then compare it with AS/NZS 3000 Table 8.2."
        }

        guard !trimmedProtection.isEmpty else {
            return "Add the protection size and type first. You need the protective device details to check the measured Zs against AS/NZS 3000 Table 8.2."
        }

        if protectionState.requiresCurveForLoopGuidance, protectionState.tripCurve.isEmpty {
            return "Protection is recorded as \(protectionState.summary), but the breaker curve is still missing. Add Type B, Type C, or Type D to narrow the Table 8.2 reference row."
        }

        if let loopReferenceLabel = protectionState.loopReferenceLabel {
            return "Protection is recognised as \(loopReferenceLabel). Use that matching Table 8.2 row to assess whether this measured Zs value passes."
        }

        return protectionState.loopGuidanceMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MeasurementField(
                title: "Fault Loop Impedance Test",
                placeholder: "0.44",
                text: $value,
                unit: "Ω",
                helperText: "Numbers only. The PDF adds the < symbol.",
                errorMessage: errorMessage
            )

            if let assessment {
                AssessmentHelperCard(outcome: assessment, message: assessmentMessage)
            }
        }
    }
}

private struct PolarityHelperField: View {
    @Binding var value: String
    var errorMessage: String? = nil
    @State private var state = PolarityInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Polarity Test Equipment / Circuit")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Text("Use the checklist to guide the polarity check, then confirm the final pass/fail result.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(PolarityInputState.CheckItem.allCases) { item in
                VisualInspectionChecklistRow(
                    title: item.title,
                    selection: binding(for: item)
                )
            }

            if let suggestion = state.suggestedResult {
                HStack(spacing: 10) {
                    Text("Suggested outcome:")
                        .font(.caption.bold())
                        .foregroundColor(.primary)

                    Text(suggestion)
                        .font(.caption.bold())
                        .foregroundColor(suggestion == "Pass" ? .green : .red)

                    Spacer()

                    if suggestion != state.result {
                        Button("Use Suggested") {
                            state.result = suggestion
                        }
                        .font(.caption.bold())
                    }
                }
                .padding(10)
                .background(Color.npFieldSurface)
                .cornerRadius(10)
            } else {
                Text("Complete each polarity check to generate a suggested outcome.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Picker("Polarity Result", selection: $state.result) {
                Text("Not Set").tag("")
                Text("Pass").tag("Pass")
                Text("Fail").tag("Fail")
            }
            .pickerStyle(.segmented)

            if !state.result.isEmpty {
                Text("Saved as: \(state.result)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        .onAppear {
            state = PolarityInputState.parse(value)
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.result.normalizedFieldValue
            if value != newValue {
                value = newValue
            }
        }
        .onChange(of: value) { _, newValue in
            let parsedState = PolarityInputState.parse(newValue)
            if parsedState.result != state.result {
                state.result = parsedState.result
            }
        }
    }

    private func binding(for item: PolarityInputState.CheckItem) -> Binding<VisualInspectionCheckStatus> {
        Binding(
            get: { state.statuses[item] ?? .notChecked },
            set: { newValue in
                state.statuses[item] = newValue
            }
        )
    }
}

private struct PolarityInputState: Equatable {
    enum CheckItem: String, CaseIterable, Identifiable {
        case activeSwitching
        case outletConnection
        case identification

        var id: String { rawValue }

        var title: String {
            switch self {
            case .activeSwitching:
                return "Active conductor is correctly switched and protected"
            case .outletConnection:
                return "Socket-outlets and accessories show correct polarity"
            case .identification:
                return "Conductors and terminations align with the intended polarity"
            }
        }
    }

    var result = ""
    var statuses: [CheckItem: VisualInspectionCheckStatus] = Dictionary(
        uniqueKeysWithValues: CheckItem.allCases.map { ($0, .notChecked) }
    )

    var suggestedResult: String? {
        let allStatuses = CheckItem.allCases.map { statuses[$0] ?? .notChecked }

        if allStatuses.contains(.issue) {
            return "Fail"
        }

        if allStatuses.allSatisfy({ $0 == .ok }) {
            return "Pass"
        }

        return nil
    }

    static func parse(_ rawValue: String) -> PolarityInputState {
        var state = PolarityInputState()
        let normalized = rawValue.normalizedFieldValue

        if normalized.caseInsensitiveCompare("Pass") == .orderedSame {
            state.result = "Pass"
        } else if normalized.caseInsensitiveCompare("Fail") == .orderedSame {
            state.result = "Fail"
        }

        return state
    }
}

private struct VisualInspectionHelperField: View {
    @Binding var value: String
    var errorMessage: String? = nil
    @State private var state = VisualInspectionInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Inspection")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Text("Work through the quick checklist below, then confirm the final visual inspection result.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(VisualInspectionInputState.CheckItem.allCases) { item in
                VisualInspectionChecklistRow(
                    title: item.title,
                    selection: binding(for: item)
                )
            }

            if let suggestion = state.suggestedResult {
                HStack(spacing: 10) {
                    Text("Suggested outcome:")
                        .font(.caption.bold())
                        .foregroundColor(.primary)

                    Text(suggestion)
                        .font(.caption.bold())
                        .foregroundColor(suggestion == "Pass" ? .green : .red)

                    Spacer()

                    if suggestion != state.result {
                        Button("Use Suggested") {
                            state.result = suggestion
                        }
                        .font(.caption.bold())
                    }
                }
                .padding(10)
                .background(Color.npFieldSurface)
                .cornerRadius(10)
            } else {
                Text("Complete each checklist item to generate a suggested outcome.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Picker("Visual Inspection Result", selection: $state.result) {
                Text("Not Set").tag("")
                Text("Pass").tag("Pass")
                Text("Fail").tag("Fail")
            }
            .pickerStyle(.segmented)

            if !state.result.isEmpty {
                Text("Saved as: \(state.result)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        .onAppear {
            state = VisualInspectionInputState.parse(value)
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.result.normalizedFieldValue
            if value != newValue {
                value = newValue
            }
        }
        .onChange(of: value) { _, newValue in
            let parsedState = VisualInspectionInputState.parse(newValue)
            if parsedState.result != state.result {
                state.result = parsedState.result
            }
        }
    }

    private func binding(for item: VisualInspectionInputState.CheckItem) -> Binding<VisualInspectionCheckStatus> {
        Binding(
            get: { state.statuses[item] ?? .notChecked },
            set: { newValue in
                state.statuses[item] = newValue
            }
        )
    }
}

private struct VisualInspectionChecklistRow: View {
    let title: String
    @Binding var selection: VisualInspectionCheckStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Picker(title, selection: $selection) {
                ForEach(VisualInspectionCheckStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .background(Color.npFieldSurface)
        .cornerRadius(12)
    }
}

private enum VisualInspectionCheckStatus: String, CaseIterable, Identifiable {
    case notChecked
    case ok
    case issue

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notChecked:
            return "Unset"
        case .ok:
            return "OK"
        case .issue:
            return "Issue"
        }
    }
}

private struct VisualInspectionInputState: Equatable {
    enum CheckItem: String, CaseIterable, Identifiable {
        case damage
        case secure
        case terminations
        case identification

        var id: String { rawValue }

        var title: String {
            switch self {
            case .damage:
                return "No visible damage to equipment, accessories, or cabling"
            case .secure:
                return "Equipment and wiring are secure and adequately supported"
            case .terminations:
                return "Terminations, enclosures, and protection appear correct"
            case .identification:
                return "Labels, barriers, and circuit identification are acceptable"
            }
        }
    }

    var result = ""
    var statuses: [CheckItem: VisualInspectionCheckStatus] = Dictionary(
        uniqueKeysWithValues: CheckItem.allCases.map { ($0, .notChecked) }
    )

    var suggestedResult: String? {
        let allStatuses = CheckItem.allCases.map { statuses[$0] ?? .notChecked }

        if allStatuses.contains(.issue) {
            return "Fail"
        }

        if allStatuses.allSatisfy({ $0 == .ok }) {
            return "Pass"
        }

        return nil
    }

    static func parse(_ rawValue: String) -> VisualInspectionInputState {
        var state = VisualInspectionInputState()
        let normalized = rawValue.normalizedFieldValue

        if normalized.caseInsensitiveCompare("Pass") == .orderedSame {
            state.result = "Pass"
        } else if normalized.caseInsensitiveCompare("Fail") == .orderedSame {
            state.result = "Fail"
        }

        return state
    }
}

private struct StructuredProtectionField: View {
    @Binding var value: String
    var errorMessage: String? = nil
    @State private var state = ProtectionInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Protection Size and Type")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            HStack(spacing: 10) {
                Menu {
                    ForEach(ProtectionInputState.ratingOptions, id: \.self) { option in
                        Button(option.isEmpty ? "Not Set" : option) {
                            state.rating = option
                            if option.isEmpty {
                                state.customDetails = ""
                            }
                        }
                    }
                } label: {
                    selectionMenuLabel(
                        title: state.ratingLabel,
                        isPlaceholder: state.rating.isEmpty,
                        showsError: errorMessage != nil
                    )
                }

                Menu {
                    ForEach(ProtectionInputState.deviceFamilyOptions, id: \.self) { option in
                        Button(option.isEmpty ? "Not Set" : option) {
                            state.deviceFamily = option
                            if option.isEmpty {
                                state.customDetails = ""
                            }
                        }
                    }
                } label: {
                    selectionMenuLabel(
                        title: state.deviceLabel,
                        isPlaceholder: state.deviceFamily.isEmpty,
                        showsError: errorMessage != nil
                    )
                }
            }

            if state.showsCurveSelection {
                Menu {
                    ForEach(ProtectionInputState.curveOptions, id: \.self) { option in
                        Button(option.isEmpty ? "Not Set" : option) {
                            state.tripCurve = option
                        }
                    }
                } label: {
                    selectionMenuLabel(
                        title: state.curveLabel,
                        isPlaceholder: state.tripCurve.isEmpty,
                        showsError: false
                    )
                }
            }

            if state.showsCustomDetails {
                EntryTextField(
                    title: "Custom Protection Details",
                    placeholder: "e.g. 125A MCCB, gG fuse",
                    text: $state.customDetails,
                    helperText: "Use this when the rating or device type is outside the common options."
                )
            }

            Text(state.guidanceText)
                .font(.caption)
                .foregroundColor(.secondary)

            if !state.summary.isEmpty {
                Text("Saved as: \(state.summary)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        .onAppear {
            state = ProtectionInputState.parse(value)
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.summary
            if value != newValue {
                value = newValue
            }
        }
        .onChange(of: value) { _, newValue in
            let parsedState = ProtectionInputState.parse(newValue)
            if parsedState != state {
                state = parsedState
            }
        }
    }

    private func selectionMenuLabel(title: String, isPlaceholder: Bool, showsError: Bool) -> some View {
        HStack {
            Text(title)
                .foregroundColor(isPlaceholder ? .secondary : .primary)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.npFieldSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(showsError ? .red : Color(uiColor: .separator), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}

private struct ProtectionInputState: Equatable {
    static let ratingOptions = ["", "6A", "10A", "16A", "20A", "25A", "32A", "40A", "50A", "63A", "80A", "100A", "Other"]
    static let deviceFamilyOptions = ["", "MCB", "RCBO", "Fuse", "MCCB", "Other"]
    static let curveOptions = ["", "Type B", "Type C", "Type D"]

    var rating = ""
    var deviceFamily = ""
    var tripCurve = ""
    var customDetails = ""

    var ratingLabel: String {
        rating.isEmpty ? "Select Rating" : rating
    }

    var deviceLabel: String {
        deviceFamily.isEmpty ? "Select Device" : deviceFamily
    }

    var curveLabel: String {
        tripCurve.isEmpty ? "Select Curve" : tripCurve
    }

    var showsCustomDetails: Bool {
        rating == "Other" || deviceFamily == "Other"
    }

    var showsCurveSelection: Bool {
        deviceFamily == "MCB" || deviceFamily == "RCBO"
    }

    var requiresCurveForLoopGuidance: Bool {
        deviceFamily == "MCB" || deviceFamily == "RCBO"
    }

    var loopReferenceLabel: String? {
        guard !rating.isEmpty, rating != "Other" else { return nil }
        guard requiresCurveForLoopGuidance, !tripCurve.isEmpty else { return nil }
        return "\(rating) \(deviceFamily) \(tripCurve)"
    }

    var loopGuidanceMessage: String {
        if rating == "Other" || deviceFamily == "Other" {
            return "The protection entry uses custom details (\(summary)). Confirm the exact device characteristic and the matching AS/NZS 3000 Table 8.2 reference before deciding pass or fail."
        }

        if deviceFamily == "Fuse" || deviceFamily == "MCCB" {
            return "Protection is recorded as \(summary). Use the exact device characteristic and the applicable AS/NZS 3000 Table 8.2 reference before deciding pass or fail."
        }

        if deviceFamily == "MCB" || deviceFamily == "RCBO" {
            return "Protection is recorded as \(summary). Add the breaker curve when known so the loop helper can narrow the correct Table 8.2 row."
        }

        return "Use AS/NZS 3000 Table 8.2 with the recorded protection details (\(summary)) to decide whether the measured Zs passes."
    }

    var guidanceText: String {
        if summary.isEmpty {
            return "Choose the protective device rating and family. The loop helper can narrow Table 8.2 better when the breaker curve is known."
        }

        if requiresCurveForLoopGuidance && tripCurve.isEmpty {
            return "Add the breaker curve if known. Generic MCB/RCBO entries are not specific enough for the best loop guidance."
        }

        return "The PDF uses the combined result exactly as shown below."
    }

    var summary: String {
        let trimmedCustomDetails = customDetails.normalizedFieldValue
        var components = [String]()

        if rating == "Other" {
            if !trimmedCustomDetails.isEmpty {
                components.append(trimmedCustomDetails)
            }
        } else if !rating.isEmpty {
            components.append(rating)
        }

        if deviceFamily == "Other" {
            if !trimmedCustomDetails.isEmpty, !components.contains(trimmedCustomDetails) {
                components.append(trimmedCustomDetails)
            }
        } else if !deviceFamily.isEmpty {
            components.append(deviceFamily)
        }

        if !tripCurve.isEmpty {
            components.append(tripCurve)
        }

        if rating != "Other", deviceFamily != "Other", !trimmedCustomDetails.isEmpty {
            components.append(trimmedCustomDetails)
        }

        if components.isEmpty {
            return trimmedCustomDetails
        }

        return components.joined(separator: " ")
    }

    static func parse(_ rawValue: String) -> ProtectionInputState {
        let trimmedValue = rawValue.normalizedFieldValue

        guard !trimmedValue.isEmpty else {
            return ProtectionInputState()
        }

        var state = ProtectionInputState()
        let lowercased = trimmedValue.lowercased()

        if let rating = ratingOptions.first(where: { option in
            !option.isEmpty && option != "Other" && lowercased.contains(option.lowercased())
        }) {
            state.rating = rating
        }

        if let device = deviceFamilyOptions.first(where: { option in
            !option.isEmpty && option != "Other" && lowercased.contains(option.lowercased())
        }) {
            state.deviceFamily = device
        }

        if let curve = curveOptions.first(where: { option in
            !option.isEmpty && lowercased.contains(option.lowercased())
        }) {
            state.tripCurve = curve
        }

        if !state.tripCurve.isEmpty && state.deviceFamily.isEmpty {
            state.deviceFamily = "MCB"
        }

        var remainingText = trimmedValue
        let knownTokens = ratingOptions.filter { !$0.isEmpty && $0 != "Other" } +
            deviceFamilyOptions.filter { !$0.isEmpty && $0 != "Other" } +
            curveOptions.filter { !$0.isEmpty }
        for token in knownTokens {
            remainingText = remainingText.replacingOccurrences(of: token, with: "", options: .caseInsensitive)
        }
        remainingText = remainingText.normalizedFieldValue

        if !remainingText.isEmpty {
            state.customDetails = remainingText

            if state.rating.isEmpty {
                state.rating = "Other"
            } else if state.deviceFamily.isEmpty {
                state.deviceFamily = "Other"
            }
        }

        if state.rating.isEmpty && state.deviceFamily.isEmpty && !trimmedValue.isEmpty {
            state.rating = "Other"
            state.customDetails = trimmedValue
        }

        return state
    }
}

private struct StructuredRCDField: View {
    @Binding var value: String
    var errorMessage: String? = nil
    @State private var state = RCDInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RCD")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Menu {
                ForEach(RCDInputState.typeOptions, id: \.self) { option in
                    Button(option.isEmpty ? "Not Set" : option) {
                        updateType(option)
                    }
                }
            } label: {
                HStack {
                    Text(state.typeLabel)
                        .foregroundColor(state.type.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.npFieldSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(errorMessage == nil ? Color(uiColor: .separator) : .red, lineWidth: 1)
                )
                .cornerRadius(10)
            }

            if state.requiresStatus {
                PassFailField(
                    title: "RCD Result",
                    selection: $state.status,
                    helperText: "Record whether the RCD tripped correctly."
                )

                MeasurementField(
                    title: "Trip Time",
                    placeholder: "24",
                    text: $state.tripTime,
                    unit: "ms",
                    helperText: "Optional. Include when you want the trip time shown."
                )
            }

            if state.showsNotesField {
                EntryTextField(
                    title: state.type == "Other" ? "RCD Notes" : "Additional Notes",
                    placeholder: state.type == "Other" ? "Custom RCD details" : "Optional notes",
                    text: $state.notes
                )
            }

            if !state.summary.isEmpty {
                Text("Saved as: \(state.summary)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Use this field for RCD type, result, and optional trip time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let outcome = state.assessment {
                AssessmentHelperCard(outcome: outcome, message: state.assessmentMessage)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        .onAppear {
            state = RCDInputState.parse(value)
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.summary
            if value != newValue {
                value = newValue
            }
        }
        .onChange(of: value) { _, newValue in
            let parsedState = RCDInputState.parse(newValue)
            if parsedState != state {
                state = parsedState
            }
        }
    }

    private func updateType(_ newType: String) {
        state.type = newType

        if newType.isEmpty || newType == "N/A" {
            state.status = ""
            state.tripTime = ""
        }
    }
}

private struct RCDInputState: Equatable {
    static let typeOptions = ["", "N/A", "30mA", "100mA", "RCBO", "Other"]

    var type = ""
    var status = ""
    var tripTime = ""
    var notes = ""

    var typeLabel: String {
        type.isEmpty ? "Select RCD setup" : type
    }

    var requiresStatus: Bool {
        !type.isEmpty && type != "N/A"
    }

    var showsNotesField: Bool {
        !type.isEmpty
    }

    var assessment: SuggestedAssessment? {
        guard !type.isEmpty else { return nil }

        if type == "N/A" {
            return .notApplicable
        }

        if status == "Fail" {
            return .fail
        }

        if status == "Pass" {
            return .pass
        }

        return .needsReference
    }

    var assessmentMessage: String {
        switch assessment {
        case .notApplicable:
            return "No RCD assessment is needed for this circuit entry."
        case .fail:
            return "The recorded RCD result is fail. Investigate the device, test setup, and applicable AS/NZS 3000 Section 8.3.10 requirements."
        case .pass:
            if tripTime.normalizedFieldValue.isEmpty {
                return "The RCD is recorded as a pass. Add a trip time when available and confirm the test current and timing requirements against AS/NZS 3000 Section 8.3.10."
            }
            return "The RCD is recorded as a pass. Confirm the trip time and applied test current against AS/NZS 3000 Section 8.3.10 and the installed device."
        case .needsReference:
            return "Select the RCD result and confirm the device/test conditions before deciding pass or fail."
        case nil:
            return ""
        }
    }

    var summary: String {
        let trimmedNotes = notes.normalizedFieldValue
        let trimmedTripTime = tripTime.normalizedFieldValue

        guard !type.isEmpty else {
            return ""
        }

        if type == "N/A" {
            return trimmedNotes.isEmpty ? "N/A" : "N/A \(trimmedNotes)"
        }

        var components = [String]()

        if type == "Other" {
            if !trimmedNotes.isEmpty {
                components.append(trimmedNotes)
            } else {
                components.append("Other")
            }
        } else {
            components.append(type)
            if !status.isEmpty {
                components.append(status)
            }
            if !trimmedTripTime.isEmpty {
                components.append("\(trimmedTripTime)ms")
            }
            if !trimmedNotes.isEmpty {
                components.append(trimmedNotes)
            }
        }

        return components.joined(separator: " ")
    }

    static func parse(_ rawValue: String) -> RCDInputState {
        let trimmedValue = rawValue.normalizedFieldValue

        guard !trimmedValue.isEmpty else {
            return RCDInputState()
        }

        var state = RCDInputState()
        let lowercased = trimmedValue.lowercased()

        if lowercased == "n/a" || lowercased.contains("not applicable") {
            state.type = "N/A"
        } else if lowercased.contains("rcbo") {
            state.type = "RCBO"
        } else if lowercased.contains("100ma") || lowercased.contains("100 ma") {
            state.type = "100mA"
        } else if lowercased.contains("30ma") || lowercased.contains("30 ma") {
            state.type = "30mA"
        } else {
            state.type = "Other"
        }

        if lowercased.contains("pass") {
            state.status = "Pass"
        } else if lowercased.contains("fail") {
            state.status = "Fail"
        }

        if let match = trimmedValue.range(
            of: #"\d+(?:\.\d+)?\s*ms"#,
            options: .regularExpression
        ) {
            let tripValue = String(trimmedValue[match])
            state.tripTime = tripValue
                .replacingOccurrences(of: "ms", with: "", options: .caseInsensitive)
                .normalizedFieldValue
        }

        var notes = trimmedValue
        let replacements = ["30mA", "30 mA", "100mA", "100 mA", "RCBO", "Pass", "Fail", "N/A", "n/a"]
        for token in replacements {
            notes = notes.replacingOccurrences(of: token, with: "", options: .caseInsensitive)
        }
        notes = notes.replacingOccurrences(
            of: #"\d+(?:\.\d+)?\s*ms"#,
            with: "",
            options: .regularExpression
        )
        notes = notes.normalizedFieldValue

        if state.type == "Other" {
            state.notes = trimmedValue
        } else {
            state.notes = notes
        }

        return state
    }
}

private extension String {
    var normalizedFieldValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    var numericDoubleValue: Double? {
        let normalized = normalizedFieldValue
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "MΩ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Ω", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .normalizedFieldValue

        return Double(normalized)
    }

    var sanitizedIdentifier: String {
        uppercased()
            .filter { character in
                character.isLetter || character.isNumber || character == " " || character == "-" || character == "/"
            }
            .normalizedFieldValue
    }
}

struct TestResultEditView: View {
    @Binding var result: TestResult
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section("Circuit Details") {
                    DatePicker(
                        "Test Date",
                        selection: Binding(
                            get: {
                                TestResultsTableView.testDateFormatter.date(from: result.testDate) ?? Date()
                            },
                            set: { newDate in
                                result.testDate = TestResultsTableView.testDateFormatter.string(from: newDate)
                            }
                        ),
                        displayedComponents: .date
                    )

                    EntryTextField(
                        title: "Circuit / Equipment",
                        placeholder: "Lighting, GPO, A/C, Pump",
                        text: $result.circuitOrEquipment
                    )
                    IdentifierField(
                        title: "Circuit No.",
                        placeholder: "C1",
                        text: $result.circuitNo,
                        helperText: "Uppercase letters, numbers, spaces, dash and slash only."
                    )
                    IdentifierField(
                        title: "Neutral No.",
                        placeholder: "N1",
                        text: $result.neutralNo,
                        helperText: "Uppercase letters, numbers, spaces, dash and slash only."
                    )
                }

                Section("Checks") {
                    VisualInspectionHelperField(value: $result.visualInspection)
                    PolarityHelperField(value: $result.polarityTest)
                    PassFailField(title: "Operational Test", selection: $result.operationalTest)
                }

                Section("Measurements") {
                    StructuredCableSizeField(value: $result.cableSize)
                    StructuredProtectionField(value: $result.protectionSizeType)
                    EarthContinuityHelperField(value: $result.earthContinuity)
                    StructuredRCDField(value: $result.rcd)
                    InsulationResistanceHelperField(value: $result.insulationResistance)
                    FaultLoopImpedanceHelperField(
                        value: $result.faultLoopImpedance,
                        protectionValue: $result.protectionSizeType
                    )
                }
            }
            .navigationTitle("Edit Circuit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}
