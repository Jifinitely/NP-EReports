//
//  PDFGenerator.swift
//  ElectricalTestReportApp
//
//  Created by Jeff Chadkirk on 29/4/2025.
//

// Utilities/PDFGenerator.swift
import AVFoundation
import PDFKit
import SwiftUI

struct PDFGenerator {
    static func generatePDF(report: ElectricalTestReport, signature: UIImage?) -> Data? {
        let companyInfo = CompanyInfo.load()
        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator: "Electrical Test Report App",
            kCGPDFContextAuthor: companyInfo.name,
            kCGPDFContextTitle: report.exportFileName
        ] as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let finalSignature = signature ?? report.signatureData.flatMap(UIImage.init(data:))
        let resultChunks = report.testResults.chunked(into: Layout.rowsPerPage)
        let attachmentChunks = report.attachments.chunked(into: Layout.attachmentsPerPage)
        let totalResultPages = max(resultChunks.count, 1)
        let totalPages = totalResultPages + attachmentChunks.count

        return renderer.pdfData { context in
            for pageIndex in 0..<totalResultPages {
                context.beginPage()
                let rows = pageIndex < resultChunks.count ? resultChunks[pageIndex] : []
                drawResultsPage(
                    in: context.cgContext,
                    report: report,
                    rows: rows,
                    companyInfo: companyInfo,
                    signature: pageIndex == totalResultPages - 1 ? finalSignature : nil,
                    pageNumber: pageIndex + 1,
                    totalPages: totalPages,
                    isFinalResultsPage: pageIndex == totalResultPages - 1
                )
            }

            for (attachmentPageIndex, attachments) in attachmentChunks.enumerated() {
                context.beginPage()
                drawAttachmentsPage(
                    in: context.cgContext,
                    report: report,
                    attachments: attachments,
                    attachmentStartIndex: attachmentPageIndex * Layout.attachmentsPerPage,
                    companyInfo: companyInfo,
                    pageNumber: totalResultPages + attachmentPageIndex + 1,
                    totalPages: totalPages
                )
            }
        }
    }

    private static func drawResultsPage(
        in context: CGContext,
        report: ElectricalTestReport,
        rows: [TestResult],
        companyInfo: CompanyInfo,
        signature: UIImage?,
        pageNumber: Int,
        totalPages: Int,
        isFinalResultsPage: Bool
    ) {
        let headerBottomY = drawPageHeader(
            in: context,
            companyInfo: companyInfo,
            report: report,
            pageNumber: pageNumber,
            totalPages: totalPages,
            pageTitle: "Electrical Test Report"
        )

        let detailsBottomY = drawJobDetails(in: context, report: report, topY: headerBottomY + 12)
        let tableTopY = detailsBottomY + 10
        let footerTopY = tableTopY + Layout.headerRowHeight + (CGFloat(Layout.rowsPerPage) * Layout.rowHeight) + 16
        drawResultsTable(in: context, rows: rows, topY: tableTopY)

        if isFinalResultsPage {
            drawCertificationFooter(
                in: context,
                report: report,
                signature: signature,
                topY: footerTopY
            )
        } else {
            drawContinuationFooter(in: context, topY: footerTopY + 42)
        }
    }

    private static func drawAttachmentsPage(
        in context: CGContext,
        report: ElectricalTestReport,
        attachments: [ReportAttachment],
        attachmentStartIndex: Int,
        companyInfo: CompanyInfo,
        pageNumber: Int,
        totalPages: Int
    ) {
        _ = drawPageHeader(
            in: context,
            companyInfo: companyInfo,
            report: report,
            pageNumber: pageNumber,
            totalPages: totalPages,
            pageTitle: "Site Photos"
        )

        let introBottomY = drawAttachmentsSummary(in: context, report: report, topY: 144)
        let cardRects = [
            CGRect(x: 44, y: introBottomY + 14, width: Layout.pageWidth - 88, height: 154),
            CGRect(x: 44, y: introBottomY + 192, width: Layout.pageWidth - 88, height: 154)
        ]

        for (index, attachment) in attachments.enumerated() where index < cardRects.count {
            drawAttachmentCard(
                in: context,
                attachment: attachment,
                rect: cardRects[index],
                attachmentIndex: attachmentStartIndex + index + 1,
                totalAttachments: report.attachments.count
            )
        }
    }

    @discardableResult
    private static func drawPageHeader(
        in context: CGContext,
        companyInfo: CompanyInfo,
        report: ElectricalTestReport,
        pageNumber: Int,
        totalPages: Int,
        pageTitle: String
    ) -> CGFloat {
        let black = UIColor.black
        let yellow = UIColor(red: 1.0, green: 0.88, blue: 0.0, alpha: 1.0)
        let white = UIColor.white

        let bodyFont = UIFont(name: "Helvetica", size: 10) ?? UIFont.systemFont(ofSize: 10)
        let headerFont = UIFont(name: "Helvetica-Bold", size: 22) ?? UIFont.boldSystemFont(ofSize: 22)
        let smallBoldFont = UIFont(name: "Helvetica-Bold", size: 9) ?? UIFont.boldSystemFont(ofSize: 9)

        let logoRect = CGRect(x: Layout.pageWidth - Layout.marginRight - 188, y: 12, width: 188, height: 72)
        let logoBadgeRect = logoRect.insetBy(dx: -4, dy: -2)
        let logoPath = UIBezierPath(roundedRect: logoBadgeRect, cornerRadius: 16)
        white.setFill()
        logoPath.fill()
        if let logo = UIImage(named: "NPContractingLogo") {
            logo.draw(in: logoRect)
        }

        let companyInfoRect = CGRect(
            x: Layout.marginLeft,
            y: 18,
            width: Layout.pageWidth - Layout.marginLeft - Layout.marginRight - 206,
            height: 74
        )
        drawBoundedText(
            companyInfo.displayText,
            in: companyInfoRect,
            font: bodyFont,
            color: black,
            lineBreakMode: .byTruncatingTail,
            maxLines: 6
        )

        let pageTitleSize = (pageTitle as NSString).size(withAttributes: [.font: headerFont])
        let bannerRect = CGRect(
            x: (Layout.pageWidth - pageTitleSize.width - 44) / 2,
            y: 100,
            width: pageTitleSize.width + 44,
            height: pageTitleSize.height + 10
        )
        yellow.setFill()
        context.fill(bannerRect)
        pageTitle.draw(
            at: CGPoint(
                x: bannerRect.midX - pageTitleSize.width / 2,
                y: bannerRect.midY - pageTitleSize.height / 2
            ),
            withAttributes: [.font: headerFont, .foregroundColor: black]
        )

        let lineY = bannerRect.maxY + 4
        context.setStrokeColor(black.cgColor)
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: Layout.marginLeft, y: lineY))
        context.addLine(to: CGPoint(x: Layout.pageWidth - Layout.marginRight, y: lineY))
        context.strokePath()

        let reportNumberText = "Report No: \(report.reportNumber)"
        let pageText = "Page \(pageNumber) of \(totalPages)"
        reportNumberText.draw(
            at: CGPoint(x: Layout.pageWidth - 210, y: lineY + 8),
            withAttributes: [.font: smallBoldFont, .foregroundColor: black]
        )
        pageText.draw(
            at: CGPoint(x: Layout.pageWidth - 210, y: lineY + 22),
            withAttributes: [.font: smallBoldFont, .foregroundColor: black]
        )

        return lineY
    }

    @discardableResult
    private static func drawJobDetails(in context: CGContext, report: ElectricalTestReport, topY: CGFloat) -> CGFloat {
        let bodyFont = UIFont(name: "Helvetica", size: 10) ?? UIFont.systemFont(ofSize: 10)
        let monoFont = UIFont(name: "Courier", size: 10) ?? UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let black = UIColor.black

        let leftFields = [
            ("Customer:", report.customer),
            ("Switchboard Location:", report.switchboardLocation),
            ("Building Number:", report.buildingNumber)
        ]
        let rightFields = [
            ("Site Address:", report.siteAddress),
            ("Job Number:", report.jobNumber),
            ("Chassis ID:", report.chassisID)
        ]

        for index in 0..<leftFields.count {
            let y = topY + CGFloat(index * 26)
            drawField(
                title: leftFields[index].0,
                value: leftFields[index].1,
                origin: CGPoint(x: Layout.marginLeft, y: y),
                valueWidth: 220,
                labelFont: bodyFont,
                valueFont: monoFont,
                color: black
            )
            drawField(
                title: rightFields[index].0,
                value: rightFields[index].1,
                origin: CGPoint(x: Layout.pageWidth / 2 + 20, y: y),
                valueWidth: 210,
                labelFont: bodyFont,
                valueFont: monoFont,
                color: black
            )
        }

        let summaryTopY = topY + CGFloat(leftFields.count * 26) + 2
        return drawSummaryStrip(in: context, report: report, topY: summaryTopY)
    }

    private static func drawResultsTable(in context: CGContext, rows: [TestResult], topY: CGFloat) {
        let yellow = UIColor(red: 1.0, green: 0.88, blue: 0.0, alpha: 1.0)
        let black = UIColor.black
        let lightGray = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        let headerFont = (UIFont(name: "Helvetica-Bold", size: 7) ?? UIFont.boldSystemFont(ofSize: 7))
        let cellFont = UIFont(name: "Courier-Bold", size: 8) ?? UIFont.boldSystemFont(ofSize: 8)
        let tableBackgroundRect = CGRect(
            x: Layout.tableX - 8,
            y: topY - 8,
            width: Layout.tableWidth + 16,
            height: Layout.headerRowHeight + (CGFloat(Layout.rowsPerPage) * Layout.rowHeight) + 18
        )

        lightGray.setFill()
        context.fill(tableBackgroundRect)

        var x = Layout.tableX
        for (index, title) in Layout.columnTitles.enumerated() {
            let rect = CGRect(x: x, y: topY, width: Layout.columnWidths[index], height: Layout.headerRowHeight)
            yellow.setFill()
            context.fill(rect)
            context.setStrokeColor(yellow.cgColor)
            context.setLineWidth(2)
            context.stroke(rect)
            drawCenteredMultilineText(title, in: rect, font: headerFont, color: black)
            x += Layout.columnWidths[index]
        }

        for rowIndex in 0..<Layout.rowsPerPage {
            let y = topY + Layout.headerRowHeight + (CGFloat(rowIndex) * Layout.rowHeight)
            var columnX = Layout.tableX
            for (columnIndex, width) in Layout.columnWidths.enumerated() {
                let cellRect = CGRect(x: columnX, y: y, width: width, height: Layout.rowHeight)
                context.setStrokeColor(black.cgColor)
                context.setLineWidth(1)
                context.stroke(cellRect)

                if rowIndex < rows.count {
                    let values = rowValues(rows[rowIndex])
                    if columnIndex < values.count {
                        drawBoundedText(
                            values[columnIndex],
                            in: cellRect.insetBy(dx: 4, dy: 4),
                            font: cellFont,
                            color: black,
                            alignment: .left,
                            lineBreakMode: .byTruncatingTail,
                            maxLines: 1
                        )
                    }
                }

                columnX += width
            }
        }
    }

    private static func drawCertificationFooter(
        in context: CGContext,
        report: ElectricalTestReport,
        signature: UIImage?,
        topY: CGFloat
    ) {
        let black = UIColor.black
        let bodyFont = UIFont(name: "Helvetica", size: 9) ?? UIFont.systemFont(ofSize: 9)
        let monoFont = UIFont(name: "Courier", size: 10) ?? UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let certText = "I certify that the electrical installation, to the extent that it is effected by the electrical work, has been tested to ensure it is electrically safe and is in accordance with the requirements of the wiring rules and any other standard applying to the electrical installation under the Electrical Safety Regulation 2002."

        drawBoundedText(
            certText,
            in: CGRect(x: Layout.tableX, y: topY, width: Layout.tableWidth, height: 34),
            font: bodyFont,
            color: black,
            lineBreakMode: .byTruncatingTail,
            maxLines: 3
        )

        let footerY = topY + 42
        drawBoundedText(
            "Tested by:",
            in: CGRect(x: Layout.tableX, y: footerY, width: 58, height: 14),
            font: bodyFont,
            color: black
        )
        drawBoundedText(
            report.testedBy,
            in: CGRect(x: Layout.tableX + 62, y: footerY, width: 150, height: 14),
            font: monoFont,
            color: black
        )
        drawBoundedText(
            "Licence Number:",
            in: CGRect(x: Layout.tableX + 220, y: footerY, width: 94, height: 14),
            font: bodyFont,
            color: black
        )
        drawBoundedText(
            report.licenceNumber,
            in: CGRect(x: Layout.tableX + 320, y: footerY, width: 100, height: 14),
            font: monoFont,
            color: black
        )
        drawBoundedText(
            "Tester's Signature:",
            in: CGRect(x: Layout.tableX + 430, y: footerY, width: 110, height: 14),
            font: bodyFont,
            color: black
        )

        if let signature {
            signature.draw(in: CGRect(x: Layout.tableX + 548, y: footerY - 8, width: 70, height: 24))
        }

        drawBoundedText(
            "Date:",
            in: CGRect(x: Layout.tableX + 642, y: footerY, width: 34, height: 14),
            font: bodyFont,
            color: black
        )
        drawBoundedText(
            Layout.dateFormatter.string(from: report.date),
            in: CGRect(x: Layout.tableX + 680, y: footerY, width: 90, height: 14),
            font: monoFont,
            color: black
        )
    }

    private static func drawContinuationFooter(in context: CGContext, topY: CGFloat) {
        let black = UIColor.black
        let italicFont = UIFont.italicSystemFont(ofSize: 9)
        "Continued on next page".draw(
            at: CGPoint(x: Layout.tableX, y: topY),
            withAttributes: [.font: italicFont, .foregroundColor: black]
        )
    }

    private static func drawAttachmentCard(
        in context: CGContext,
        attachment: ReportAttachment,
        rect: CGRect,
        attachmentIndex: Int,
        totalAttachments: Int
    ) {
        let black = UIColor.black
        let lightGray = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        let cardPath = UIBezierPath(roundedRect: rect, cornerRadius: 16)
        lightGray.setFill()
        cardPath.fill()
        black.setStroke()
        cardPath.lineWidth = 1
        cardPath.stroke()

        let labelRect = CGRect(x: rect.minX + 16, y: rect.minY + 10, width: rect.width - 32, height: 16)
        drawBoundedText(
            "Photo \(attachmentIndex) of \(totalAttachments)",
            in: labelRect,
            font: UIFont.boldSystemFont(ofSize: 11),
            color: black
        )

        let fileNameRect = CGRect(x: rect.minX + 16, y: rect.minY + 28, width: rect.width - 180, height: 18)
        drawBoundedText(
            attachment.fileName,
            in: fileNameRect,
            font: UIFont.systemFont(ofSize: 10),
            color: black
        )

        let createdAtText = "Added \(Layout.attachmentDateFormatter.string(from: attachment.createdAt))"
        let createdAtRect = CGRect(x: rect.maxX - 164, y: rect.minY + 28, width: 148, height: 16)
        drawBoundedText(
            createdAtText,
            in: createdAtRect,
            font: UIFont.systemFont(ofSize: 9),
            color: UIColor.darkGray,
            alignment: .right
        )

        let imageRect = CGRect(x: rect.minX + 16, y: rect.minY + 52, width: rect.width - 32, height: rect.height - 68)
        if let image = UIImage(data: attachment.imageData) {
            let fittedRect = AVMakeRect(aspectRatio: image.size, insideRect: imageRect)
            image.draw(in: fittedRect)
        }
    }

    @discardableResult
    private static func drawSummaryStrip(in context: CGContext, report: ElectricalTestReport, topY: CGFloat) -> CGFloat {
        let stripRect = CGRect(x: Layout.marginLeft, y: topY, width: Layout.pageWidth - Layout.marginLeft - Layout.marginRight, height: 34)
        let yellow = UIColor(red: 1.0, green: 0.88, blue: 0.0, alpha: 1.0)
        let black = UIColor.black
        let bodyFont = UIFont.systemFont(ofSize: 9)
        let titleFont = UIFont.boldSystemFont(ofSize: 9)

        yellow.setFill()
        UIBezierPath(roundedRect: stripRect, cornerRadius: 12).fill()

        let summaryItems = [
            ("Report", report.displayTitle),
            ("Status", report.lifecycleSummary),
            ("Circuits", "\(report.testResults.count)"),
            ("Photos", "\(report.attachments.count)")
        ]
        let widths: [CGFloat] = [0.34, 0.30, 0.18, 0.18]

        var currentX = stripRect.minX
        for (index, item) in summaryItems.enumerated() {
            let cellWidth = stripRect.width * widths[index]
            let cellRect = CGRect(x: currentX, y: stripRect.minY, width: cellWidth, height: stripRect.height)
            if index > 0 {
                context.setStrokeColor(black.withAlphaComponent(0.22).cgColor)
                context.setLineWidth(1)
                context.move(to: CGPoint(x: currentX, y: cellRect.minY + 6))
                context.addLine(to: CGPoint(x: currentX, y: cellRect.maxY - 6))
                context.strokePath()
            }

            drawBoundedText(
                item.0,
                in: CGRect(x: cellRect.minX + 10, y: cellRect.minY + 5, width: cellRect.width - 20, height: 12),
                font: titleFont,
                color: black
            )
            drawBoundedText(
                item.1,
                in: CGRect(x: cellRect.minX + 10, y: cellRect.minY + 17, width: cellRect.width - 20, height: 12),
                font: bodyFont,
                color: black
            )

            currentX += cellWidth
        }

        return stripRect.maxY
    }

    @discardableResult
    private static func drawAttachmentsSummary(in context: CGContext, report: ElectricalTestReport, topY: CGFloat) -> CGFloat {
        let rect = CGRect(x: 44, y: topY, width: Layout.pageWidth - 88, height: 46)
        let lightGray = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        let black = UIColor.black

        let summaryPath = UIBezierPath(roundedRect: rect, cornerRadius: 14)
        lightGray.setFill()
        summaryPath.fill()
        black.withAlphaComponent(0.12).setStroke()
        summaryPath.lineWidth = 1
        summaryPath.stroke()

        let title = "Attachments for \(report.displayTitle)"
        let subtitle = "Job \(report.jobNumber.isEmpty ? "Not set" : report.jobNumber) • \(report.attachments.count) photo(s) • \(report.lifecycleSummary)"

        drawBoundedText(
            title,
            in: CGRect(x: rect.minX + 16, y: rect.minY + 8, width: rect.width - 32, height: 16),
            font: UIFont.boldSystemFont(ofSize: 12),
            color: black
        )
        drawBoundedText(
            subtitle,
            in: CGRect(x: rect.minX + 16, y: rect.minY + 24, width: rect.width - 32, height: 14),
            font: UIFont.systemFont(ofSize: 10),
            color: UIColor.darkGray
        )

        return rect.maxY
    }

    private static func drawField(
        title: String,
        value: String,
        origin: CGPoint,
        valueWidth: CGFloat,
        labelFont: UIFont,
        valueFont: UIFont,
        color: UIColor
    ) {
        drawBoundedText(
            title,
            in: CGRect(x: origin.x, y: origin.y, width: 110, height: 14),
            font: labelFont,
            color: color
        )

        let valueRect = CGRect(x: origin.x + 118, y: origin.y - 1, width: valueWidth, height: 22)
        drawBoundedText(
            value,
            in: valueRect,
            font: valueFont,
            color: color
        )
    }

    private static func drawBoundedText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left,
        lineBreakMode: NSLineBreakMode = .byTruncatingTail,
        maxLines: Int = 1
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = lineBreakMode

        let boundedRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: min(rect.height, ceil(font.lineHeight * CGFloat(maxLines)))
        )

        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
        )

        attributedText.draw(
            with: boundedRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }

    private static func drawCenteredMultilineText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor
    ) {
        let lines = text.components(separatedBy: "\n")
        let lineHeight = font.lineHeight
        var currentY = rect.midY - (CGFloat(lines.count) * lineHeight / 2)

        for line in lines {
            let size = (line as NSString).size(withAttributes: [.font: font])
            let x = rect.midX - size.width / 2
            (line as NSString).draw(
                at: CGPoint(x: x, y: currentY),
                withAttributes: [.font: font, .foregroundColor: color]
            )
            currentY += lineHeight
        }
    }

    private static func rowValues(_ result: TestResult) -> [String] {
        [
            result.testDate,
            result.circuitOrEquipment,
            result.visualInspection,
            result.circuitNo,
            result.cableSize.isEmpty ? "" : "\(result.cableSize) mm²",
            result.protectionSizeType,
            result.neutralNo,
            result.earthContinuity.isEmpty ? "" : "< \(result.earthContinuity)",
            result.rcd,
            result.insulationResistance.isEmpty ? "" : "> \(result.insulationResistance)",
            result.polarityTest,
            result.faultLoopImpedance.isEmpty ? "" : "< \(result.faultLoopImpedance)",
            result.operationalTest
        ]
    }
}

private struct CompanyInfo {
    let name: String
    let address: String
    let phone: String
    let email: String
    let abn: String
    let licence: String

    var displayText: String {
        """
        \(name)
        \(address)
        Telephone: \(phone)
        Email: \(email)
        ABN: \(abn)
        Electrical Contractor Licence \(licence)
        """
    }

    static func load() -> CompanyInfo {
        CompanyInfo(
            name: UserDefaults.standard.string(forKey: "companyName") ?? "N & P Contracting",
            address: UserDefaults.standard.string(forKey: "companyAddress") ?? "Unit 9 / 48 Tennyson Memorial Avenue, Tennyson QLD 4105",
            phone: UserDefaults.standard.string(forKey: "companyPhone") ?? "07 3892 3399",
            email: UserDefaults.standard.string(forKey: "companyEmail") ?? "info@npcontracting.com.au",
            abn: UserDefaults.standard.string(forKey: "companyABN") ?? "51 709 046 128",
            licence: UserDefaults.standard.string(forKey: "companyLicense") ?? "65051"
        )
    }
}

private enum Layout {
    static let pageWidth: CGFloat = 841.8
    static let pageHeight: CGFloat = 595.2
    static let marginLeft: CGFloat = 32
    static let marginRight: CGFloat = 32
    static let tableWidth: CGFloat = 780
    static let tableX: CGFloat = (pageWidth - tableWidth) / 2
    static let headerRowHeight: CGFloat = 38
    static let rowHeight: CGFloat = 27
    static let rowsPerPage = 8
    static let attachmentsPerPage = 2
    static let columnTitles = [
        "Test Date",
        "Circuit or Equipment",
        "Visual Inspection\nComplete\n(Pass/Fail)",
        "Circuit No.",
        "Cable Size",
        "Protection Size\nand Type",
        "Neutral No.",
        "Earth Continuity\n(Ohms)",
        "RCD",
        "Insulation\nResistance\n(MEGOHM)",
        "Polarity Test\nEquip./Circuit\n(Pass/Fail)",
        "Fault Loop\nImpedance\nTest (Ohms)",
        "Operational\nTest\n(Pass/Fail)"
    ]
    static let columnWidths: [CGFloat] = {
        let baseColumnWidths: [CGFloat] = [65, 85, 80, 55, 60, 85, 55, 75, 45, 85, 85, 85, 75]
        let total = baseColumnWidths.reduce(0, +)
        let scale = tableWidth / total
        return baseColumnWidths.map { $0 * scale }
    }()
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    static let attachmentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
