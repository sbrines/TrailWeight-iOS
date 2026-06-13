import SwiftUI
#if os(iOS)
import VisionKit

/// A live camera barcode scanner. Reports the first barcode payload it reads.
/// iOS only — VisionKit's DataScannerViewController isn't available on macOS.
@available(iOS 16.0, *)
struct BarcodeScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    static var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        try? scanner.startScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard !hasScanned else { return }
            for item in addedItems {
                if case let .barcode(barcode) = item,
                   let payload = barcode.payloadStringValue, !payload.isEmpty {
                    hasScanned = true
                    onScan(payload)
                    break
                }
            }
        }
    }
}
#endif
