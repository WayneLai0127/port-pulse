import SwiftUI
import Network
import Foundation

class PortMonitor: ObservableObject {
    @Published var checkInterval: Double = 2.0
    @Published var portNum: UInt16 = 3000
    @Published var portStatusCode: String = "UNKNOWN"
    
    var timer: Timer?
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: self.checkInterval, repeats: true) { _ in
            self.checkPortStatus(port: self.portNum)
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func checkPortStatus(port: UInt16) {
        let host = NWEndpoint.Host("127.0.0.1")
        let connection = NWConnection(host: host, port: NWEndpoint.Port(rawValue: port)!, using: .tcp)

        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                DispatchQueue.main.async {
                    self.portStatusCode = "RUNNING"
                }
            default:
                DispatchQueue.main.async {
                    self.portStatusCode = "IDLE"
                }
            }
        }

        connection.start(queue: .global())
    }

    
}




struct ContentView: View {
    @EnvironmentObject var monitor: PortMonitor
    
    var body: some View {
        VStack {
            Text("Port Status Code: \(monitor.portStatusCode)")
            Text("Currently this is a menu bar focused app, feel free to close this window")
        }.padding(.all)
    }
}


@main
struct port_pulseApp: App {
    // Create a state object for PortMonitor
    @StateObject private var monitor = PortMonitor()
    
    var body: some Scene {
        // Inject the PortMonitor into the environment
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .onReceive(monitor.$checkInterval) { newInterval in
                    monitor.timer?.invalidate()
                    monitor.startMonitoring()
                }
        }

        MenuBarExtra() {
                VStack {
                    Form {
                        Section {
                            TextField("", text: Binding(
                                get: { "\(monitor.portNum)" },
                                set: { newValue in
                                    if let newPortNum = UInt16(newValue) {
                                        monitor.portNum = newPortNum
                                    }
                                }
                            )).padding(.all)
                        } header: {
                            Text("target port:")
                        }
                        Section {
                            TextField("", text: Binding(
                                get: { "\(monitor.checkInterval)" },
                                set: { newValue in
                                    if let newCheckInterval = Double(newValue) {
                                        monitor.checkInterval = newCheckInterval
                                    }
                                }
                            )).padding(.all)
                        } header: {
                            Text("check interval:")
                        }
                    }
                }
        } label: {
            let colors: [String: NSColor] = ["UNKNOWN":.red, "IDLE":.gray, "RUNNING":.green]
            let colorCode = monitor.portStatusCode
            let iconColor = colors[colorCode] ?? .red
            let configuration = NSImage.SymbolConfiguration(pointSize: 12, weight: .light)
                .applying(.init(paletteColors: [iconColor]))
            let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)
            let updateImage = image?.withSymbolConfiguration(configuration)
            Image(nsImage: updateImage!)
            Text("\(String(monitor.portNum))").font(.system(size: 3))
        }
        .menuBarExtraStyle(.window)
    }
}
