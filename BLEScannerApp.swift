import SwiftUI

@main
struct BLEScannerApp: App {
    @StateObject var bleManager = BLEManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleManager)
        }
    }
}