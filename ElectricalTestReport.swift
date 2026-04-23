//
//  ElectricalTestReport.swift
//  ElectricalTestReportApp
//
//  Created by Jeff Chadkirk on 29/4/2025.
//


// Models/ElectricalTestReport.swift
import Foundation

enum ReportLifecycleStatus: String, Codable, CaseIterable, Identifiable {
    case inProgress
    case complete
    case sent

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inProgress:
            return "In Progress"
        case .complete:
            return "Complete"
        case .sent:
            return "Sent"
        }
    }
}

enum TemplateScope: String, Codable, CaseIterable, Identifiable {
    case board
    case circuitsOnly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .board:
            return "Board Template"
        case .circuitsOnly:
            return "Circuit Set"
        }
    }

    var applyButtonTitle: String {
        switch self {
        case .board:
            return "Use Board Template"
        case .circuitsOnly:
            return "Apply Circuits"
        }
    }
}

struct ElectricalTestReport: Identifiable, Codable {
    let id: UUID
    var reportTitle: String
    var customer: String
    var siteAddress: String
    var switchboardLocation: String
    var buildingNumber: String
    var jobNumber: String
    var chassisID: String
    var testResults: [TestResult]
    var attachments: [ReportAttachment]
    var testedBy: String
    var licenceNumber: String
    var date: Date
    var lifecycleStatus: ReportLifecycleStatus
    var isArchived: Bool
    var signatureData: Data? // UIImage PNG data

    enum CodingKeys: String, CodingKey {
        case id
        case reportTitle
        case customer
        case siteAddress
        case switchboardLocation
        case buildingNumber
        case jobNumber
        case chassisID
        case testResults
        case attachments
        case testedBy
        case licenceNumber
        case date
        case lifecycleStatus
        case isArchived
        case signatureData
        case jobNo
        case workActivity
    }

    init(
        id: UUID = UUID(),
        reportTitle: String = "",
        customer: String,
        siteAddress: String,
        switchboardLocation: String,
        buildingNumber: String,
        jobNumber: String,
        chassisID: String,
        testResults: [TestResult],
        attachments: [ReportAttachment] = [],
        testedBy: String,
        licenceNumber: String,
        date: Date,
        lifecycleStatus: ReportLifecycleStatus = .inProgress,
        isArchived: Bool = false,
        signatureData: Data?
    ) {
        self.id = id
        self.reportTitle = reportTitle
        self.customer = customer
        self.siteAddress = siteAddress
        self.switchboardLocation = switchboardLocation
        self.buildingNumber = buildingNumber
        self.jobNumber = jobNumber
        self.chassisID = chassisID
        self.testResults = testResults
        self.attachments = attachments
        self.testedBy = testedBy
        self.licenceNumber = licenceNumber
        self.date = date
        self.lifecycleStatus = lifecycleStatus
        self.isArchived = isArchived
        self.signatureData = signatureData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        reportTitle = try container.decodeIfPresent(String.self, forKey: .reportTitle) ?? ""
        customer = try container.decodeIfPresent(String.self, forKey: .customer) ?? ""
        siteAddress = try container.decodeIfPresent(String.self, forKey: .siteAddress) ?? ""
        switchboardLocation = try container.decodeIfPresent(String.self, forKey: .switchboardLocation) ?? ""
        buildingNumber = try container.decodeIfPresent(String.self, forKey: .buildingNumber) ?? ""
        jobNumber = try container.decodeIfPresent(String.self, forKey: .jobNumber)
            ?? container.decodeIfPresent(String.self, forKey: .jobNo)
            ?? ""
        chassisID = try container.decodeIfPresent(String.self, forKey: .chassisID) ?? ""
        testResults = try container.decodeIfPresent([TestResult].self, forKey: .testResults) ?? []
        attachments = try container.decodeIfPresent([ReportAttachment].self, forKey: .attachments) ?? []
        testedBy = try container.decodeIfPresent(String.self, forKey: .testedBy) ?? ""
        licenceNumber = try container.decodeIfPresent(String.self, forKey: .licenceNumber) ?? ""
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        lifecycleStatus = try container.decodeIfPresent(ReportLifecycleStatus.self, forKey: .lifecycleStatus) ?? .complete
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        signatureData = try container.decodeIfPresent(Data.self, forKey: .signatureData)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reportTitle, forKey: .reportTitle)
        try container.encode(customer, forKey: .customer)
        try container.encode(siteAddress, forKey: .siteAddress)
        try container.encode(switchboardLocation, forKey: .switchboardLocation)
        try container.encode(buildingNumber, forKey: .buildingNumber)
        try container.encode(jobNumber, forKey: .jobNumber)
        try container.encode(jobNumber, forKey: .jobNo)
        try container.encode(chassisID, forKey: .chassisID)
        try container.encode(testResults, forKey: .testResults)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(testedBy, forKey: .testedBy)
        try container.encode(licenceNumber, forKey: .licenceNumber)
        try container.encode(date, forKey: .date)
        try container.encode(lifecycleStatus, forKey: .lifecycleStatus)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encodeIfPresent(signatureData, forKey: .signatureData)
    }
}

extension ElectricalTestReport {
    var displayTitle: String {
        if !reportTitle.normalizedFieldValue.isEmpty {
            return reportTitle.normalizedFieldValue
        }

        if !customer.normalizedFieldValue.isEmpty {
            return customer.normalizedFieldValue
        }

        if !switchboardLocation.normalizedFieldValue.isEmpty {
            return switchboardLocation.normalizedFieldValue
        }

        return "Untitled Report"
    }

    var lifecycleSummary: String {
        isArchived ? "\(lifecycleStatus.label) • Archived" : lifecycleStatus.label
    }

    var reportNumber: String {
        String(id.uuidString.prefix(8)).uppercased()
    }

    var exportFileName: String {
        let parts = [
            "Electrical-Test-Report",
            sanitizedFilePart(reportTitle),
            sanitizedFilePart(customer),
            sanitizedFilePart(jobNumber),
            Self.fileDateFormatter.string(from: date)
        ]
        return parts
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    func duplicatedForTemplate() -> ElectricalTestReport {
        ElectricalTestReport(
            id: UUID(),
            reportTitle: "",
            customer: customer,
            siteAddress: siteAddress,
            switchboardLocation: switchboardLocation,
            buildingNumber: buildingNumber,
            jobNumber: jobNumber,
            chassisID: chassisID,
            testResults: testResults.map { $0.duplicated() },
            attachments: attachments.map { $0.duplicated() },
            testedBy: testedBy,
            licenceNumber: licenceNumber,
            date: Date(),
            lifecycleStatus: .inProgress,
            isArchived: false,
            signatureData: signatureData
        )
    }

    func templateSnapshot(for scope: TemplateScope) -> ElectricalTestReport {
        let keepsBoardDetails = scope == .board

        return ElectricalTestReport(
            id: UUID(),
            reportTitle: "",
            customer: keepsBoardDetails ? customer : "",
            siteAddress: keepsBoardDetails ? siteAddress : "",
            switchboardLocation: keepsBoardDetails ? switchboardLocation : "",
            buildingNumber: keepsBoardDetails ? buildingNumber : "",
            jobNumber: keepsBoardDetails ? jobNumber : "",
            chassisID: keepsBoardDetails ? chassisID : "",
            testResults: testResults.map { $0.duplicated() },
            attachments: [],
            testedBy: "",
            licenceNumber: "",
            date: Date(),
            lifecycleStatus: .inProgress,
            isArchived: false,
            signatureData: nil
        )
    }

    func suggestedTemplateName(for scope: TemplateScope) -> String {
        let baseName = [
            switchboardLocation.normalizedFieldValue,
            customer.normalizedFieldValue,
            buildingNumber.normalizedFieldValue
        ]
        .first(where: { !$0.isEmpty }) ?? "Untitled"

        switch scope {
        case .board:
            return "\(baseName) Board Template"
        case .circuitsOnly:
            return "\(baseName) Circuit Set"
        }
    }

    private func sanitizedFilePart(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^A-Za-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct SavedReportTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var scope: TemplateScope
    var reportSnapshot: ElectricalTestReport
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        scope: TemplateScope,
        reportSnapshot: ElectricalTestReport,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.scope = scope
        self.reportSnapshot = reportSnapshot
        self.createdAt = createdAt
    }

    var circuitCount: Int {
        reportSnapshot.testResults.count
    }

    var displayName: String {
        name.normalizedFieldValue.isEmpty ? reportSnapshot.suggestedTemplateName(for: scope) : name.normalizedFieldValue
    }
}

// Models/TestResult.swift
import Foundation

struct ReportAttachment: Identifiable, Codable, Hashable {
    let id: UUID
    var fileName: String
    var imageData: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        imageData: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.imageData = imageData
        self.createdAt = createdAt
    }

    func duplicated() -> ReportAttachment {
        ReportAttachment(fileName: fileName, imageData: imageData)
    }
}

struct TestResult: Identifiable, Codable {
    let id: UUID
    var testDate: String
    var circuitOrEquipment: String
    var visualInspection: String
    var circuitNo: String
    var cableSize: String
    var protectionSizeType: String
    var neutralNo: String
    var earthContinuity: String
    var rcd: String
    var insulationResistance: String
    var polarityTest: String
    var faultLoopImpedance: String
    var operationalTest: String
}
extension TestResult {
    static func blank() -> TestResult {
        TestResult(
            id: UUID(),
            testDate: "",
            circuitOrEquipment: "",
            visualInspection: "",
            circuitNo: "",
            cableSize: "",
            protectionSizeType: "",
            neutralNo: "",
            earthContinuity: "",
            rcd: "",
            insulationResistance: "",
            polarityTest: "",
            faultLoopImpedance: "",
            operationalTest: ""
        )
    }

    func duplicated() -> TestResult {
        TestResult(
            id: UUID(),
            testDate: testDate,
            circuitOrEquipment: circuitOrEquipment,
            visualInspection: visualInspection,
            circuitNo: circuitNo,
            cableSize: cableSize,
            protectionSizeType: protectionSizeType,
            neutralNo: neutralNo,
            earthContinuity: earthContinuity,
            rcd: rcd,
            insulationResistance: insulationResistance,
            polarityTest: polarityTest,
            faultLoopImpedance: faultLoopImpedance,
            operationalTest: operationalTest
        )
    }

    var missingRequiredFields: [String] {
        var missingFields = [String]()
        if Self.isBlank(testDate) {
            missingFields.append("Test Date")
        }
        if Self.isBlank(circuitOrEquipment) {
            missingFields.append("Circuit / Equipment")
        }
        if Self.isBlank(visualInspection) {
            missingFields.append("Visual Inspection")
        }
        if Self.isBlank(circuitNo) {
            missingFields.append("Circuit No.")
        }
        if Self.isBlank(cableSize) {
            missingFields.append("Cable Size")
        }
        if Self.isBlank(protectionSizeType) {
            missingFields.append("Protection")
        }
        if Self.isBlank(neutralNo) {
            missingFields.append("Neutral No.")
        }
        if Self.isBlank(earthContinuity) {
            missingFields.append("Earth Continuity")
        }
        if Self.isBlank(rcd) {
            missingFields.append("RCD")
        }
        if Self.isBlank(insulationResistance) {
            missingFields.append("Insulation Resistance")
        }
        if Self.isBlank(polarityTest) {
            missingFields.append("Polarity Test")
        }
        if Self.isBlank(faultLoopImpedance) {
            missingFields.append("Fault Loop Impedance")
        }
        if Self.isBlank(operationalTest) {
            missingFields.append("Operational Test")
        }

        return missingFields
    }

    var isComplete: Bool {
        missingRequiredFields.isEmpty
    }

    private static func isBlank(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension String {
    var normalizedFieldValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
