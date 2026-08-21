import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text("BLE Scanner")
                    .font(.title2.bold())
                HStack(spacing: 8) {
                    Circle()
                        .fill(bleManager.isScanning ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(bleManager.isScanning ? "Scanning..." : "Idle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            
            // Controls
            HStack(spacing: 12) {
                Button(action: { bleManager.startScan() }) {
                    Label("Scan", systemImage: "antenna.radiowaves.left.and.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(bleManager.isScanning)
                
                Button(action: { bleManager.stopScan() }) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!bleManager.isScanning)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Device list
            List(bleManager.devices) { device in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(device.name)
                            .font(.headline)
                        Spacer()
                        Text("\(device.rssi) dBm")
                            .font(.caption)
                            .foregroundColor(device.rssi > -60 ? .green : .secondary)
                    }
                    Text(device.identifier)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    bleManager.connect(to: device)
                }
            }
            .listStyle(.plain)
        }
        .sheet(isPresented: $bleManager.showDeviceView) {
            DeviceView()
                .environmentObject(bleManager)
        }
    }
}

struct DeviceView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Device info
                HStack {
                    VStack(alignment: .leading) {
                        Text(bleManager.connectedDevice?.name ?? "Unknown")
                            .font(.title3.bold())
                        Text(bleManager.connectedDevice?.identifier ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Disconnect", role: .destructive) {
                        bleManager.disconnect()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Send A0
                HStack {
                    Button(action: { bleManager.sendA0() }) {
                        Label("Send 0xA0", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!bleManager.isConnected)
                }
                .padding(.horizontal)
                
                // Response log
                VStack(alignment: .leading, spacing: 4) {
                    Text("Response")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(bleManager.responseLog.isEmpty ? "Waiting..." : bleManager.responseLog)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(maxHeight: 200)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { bleManager.showDeviceView = false }
                }
            }
        }
    }
}