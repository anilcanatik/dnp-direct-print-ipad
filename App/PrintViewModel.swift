import DNPPrintCore
import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class PrintViewModel: ObservableObject {
    @Published var selectedModel: DNPPrinterModel = .rx1hs {
        didSet { selectedPreset = selectedModel.presets[0] }
    }
    @Published var selectedPreset: DNPPrintPreset = .rx1hs4x6
    @Published var finish: DNPFinish = .glossy
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var image: UIImage?
    @Published var status = "Enable the driver, connect the printer, then run Probe."
    @Published var progress = 0.0
    @Published var isWorking = false

    private let driver = DNPDriverClient()

    func loadSelectedPhoto() async {
        guard let selectedPhoto else { return }
        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw DNPPrintError.imageRenderingFailed
            }
            self.image = image
            status = "Photo ready. Probe the printer before printing."
        } catch {
            status = error.localizedDescription
        }
    }

    func probe() {
        guard !isWorking else { return }
        isWorking = true
        status = "Querying printer…"
        Task {
            do {
                let probe = try await Task.detached { [driver] in try driver.probe() }.value
                status = "\(probe.statusText); \(probe.freeBuffers) print buffer(s) free."
            } catch {
                status = error.localizedDescription
            }
            isWorking = false
        }
    }

    func printOneCopy() {
        guard !isWorking else { return }
        guard let image else {
            status = "Choose a photo first."
            return
        }
        let preset = selectedPreset
        let finish = finish
        isWorking = true
        progress = 0
        status = "Preparing \(preset.displayName) raster…"

        Task {
            do {
                let job = try await Task.detached {
                    let raster = try DNPImageRasterizer.rasterize(image, for: preset)
                    return try DNPJobBuilder.build(raster: raster, preset: preset, copies: 1, finish: finish)
                }.value

                status = "Checking printer readiness…"
                let probe = try await Task.detached { [driver] in try driver.probe() }.value
                guard probe.isReadyForOneJob else {
                    throw DNPPrintError.printerNotReady("\(probe.statusText), \(probe.freeBuffers) buffer(s) free")
                }

                status = "Sending \(ByteCountFormatter.string(fromByteCount: Int64(job.count), countStyle: .file))…"
                try await Task.detached { [driver] in
                    try driver.send(job: job) { fraction in
                        Task { @MainActor in self.progress = fraction }
                    }
                }.value
                status = "Job accepted. The printer should start shortly."
            } catch {
                status = error.localizedDescription
            }
            isWorking = false
        }
    }
}
