import DNPPrintCore
import PhotosUI
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PrintViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Printer") {
                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(DNPPrinterModel.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Print size", selection: $viewModel.selectedPreset) {
                        ForEach(viewModel.selectedModel.presets) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Finish", selection: $viewModel.finish) {
                        ForEach(DNPFinish.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Text("USB ID: \(viewModel.selectedModel.usbIdentifier)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Section("Photo") {
                    PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                        Label(viewModel.image == nil ? "Choose photo" : "Replace photo", systemImage: "photo")
                    }
                    .onChange(of: viewModel.selectedPhoto) { _ in
                        Task { await viewModel.loadSelectedPhoto() }
                    }
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Section("Connection") {
                    Button("Open iPad Settings to enable driver") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Probe printer", action: viewModel.probe)
                        .disabled(viewModel.isWorking)
                    Text(viewModel.status)
                        .font(.callout)
                    if viewModel.progress > 0 && viewModel.progress < 1 {
                        ProgressView(value: viewModel.progress)
                    }
                }

                Section {
                    Button(action: viewModel.printOneCopy) {
                        Label("Print one test copy", systemImage: "printer.fill")
                    }
                    .disabled(viewModel.isWorking || viewModel.image == nil)
                } footer: {
                    Text("Prototype: begin with one copy and keep the printer attended. Color is not yet calibrated with DNP CWD/ICC data.")
                }
            }
            .navigationTitle("DNP Direct Print")
        }
    }
}
