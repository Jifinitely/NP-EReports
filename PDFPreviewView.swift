//
//  PDFPreviewView.swift
//  ElectricalTestReportApp
//
//  Created by Jeff Chadkirk on 29/4/2025.
//

// Views/PDFPreviewView.swift
import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let report: ElectricalTestReport
    let signature: UIImage?
    @State private var showShareSheet = false
    @State private var pdfData: Data? = nil
    @State private var exportURL: URL? = nil

    var body: some View {
        VStack {
            BrandHeaderView(title: "PDF Preview")
            if let data = pdfData, let pdfDoc = PDFDocument(data: data) {
                PDFKitRepresentedView(pdfDocument: pdfDoc)
                Button(action: { showShareSheet = true }) {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                        .padding()
                        .background(Color.npBrandYellow)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                .sheet(isPresented: $showShareSheet) {
                    if let exportURL = exportURL {
                        ActivityView(activityItems: [exportURL])
                    }
                }
            } else {
                Text("PDF Preview not available.")
            }
        }
        .background(Color.npBackground)
        .onAppear {
            pdfData = PDFGenerator.generatePDF(report: report, signature: signature)
            if let pdfData = pdfData {
                exportURL = try? ReportExportHelper.makeTemporaryPDFURL(report: report, data: pdfData)
            }
        }
    }
}

// Helper for PDFKit in SwiftUI
struct PDFKitRepresentedView: UIViewRepresentable {
    let pdfDocument: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
