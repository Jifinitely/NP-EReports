import Foundation

enum ReportExportHelper {
    static func makeTemporaryPDFURL(report: ElectricalTestReport, data: Data) throws -> URL {
        let fileName = "\(report.exportFileName)-\(report.reportNumber).pdf"
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        try data.write(to: destinationURL, options: .atomic)
        return destinationURL
    }
}
