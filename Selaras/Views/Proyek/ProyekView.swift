
import SwiftUI

struct ProyekView: View {
    @State private var isShowingAddDeviceSheet = false

    var body: some View {
        VStack(spacing: 16) {
            EmptyDeviceView()

            Button {
                isShowingAddDeviceSheet = true
            } label: {
                Label("Tambah Perangkat", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .navigationTitle("Proyek")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    RiwayatView()
                } label: {
                    Label(
                        "Riwayat",
                        systemImage: "clock.arrow.circlepath"
                    )
                }
            }
        }
        .sheet(isPresented: $isShowingAddDeviceSheet) {
            AddDeviceSheetView()
                .presentationDetents([.medium])
                .presentationBackground(.background)
        }
    }
}

private struct EmptyDeviceView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sensor.radiowaves.left.and.right")
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityHidden(true)

            Text("Belum ada perangkat")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Tambahkan perangkat untuk memulai")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

private struct AddDeviceSheetView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sensor.radiowaves.left.and.right")
                .font(.largeTitle)
                .accessibilityHidden(true)

            Text("Tambah Perangkat")
                .font(.title2.weight(.semibold))

            Text("Pilih perangkat yang ingin ditambahkan ke proyek.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        ProyekView()
    }
}
