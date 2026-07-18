//
//  partyui.swift
//  mond
//
//  Created by ruter on 16.07.26.
//  100% skidded from PartyUI (https://github.com/jailbreakdotparty/PartyUI)
//

import SwiftUI
import UIKit

public enum ToggleInfoType: Codable {
    case none, info, warning
}

public struct PlainToggle: View {
    var text: String
    var icon: String
    var infoType: ToggleInfoType
    var infoTitle: String
    var infoMessage: String
    var minSupportedVersion: Double
    var maxSupportedVersion: Double
    @Binding var isOn: Bool
    
    public init(text: String, icon: String = "", infoType: ToggleInfoType = .none, infoTitle: String = "Information", infoMessage: String = "", minSupportedVersion: Double = 0.0, maxSupportedVersion: Double = 100.0, isOn: Binding<Bool>) {
        self.text = text
        self.icon = icon
        self.infoType = infoType
        self.infoTitle = infoTitle
        self.infoMessage = infoMessage
        self._isOn = isOn
        self.minSupportedVersion = minSupportedVersion
        self.maxSupportedVersion = maxSupportedVersion
    }
    
    public var body: some View {
        if doubleSystemVersion() >= minSupportedVersion && doubleSystemVersion() <= maxSupportedVersion {
            Toggle(isOn: $isOn) {
                HStack(spacing: 10) {
                    if !icon.isEmpty {
                        Image(systemName: icon)
                            .frame(width: 22, height: 22, alignment: .center)
                    }
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if infoType == .info || infoType == .warning {
                        Button(action: {
                            Alertinator.shared.alert(title: infoTitle, body: infoMessage)
                        }) {
                            Image(systemName: infoType == .info ? "info.circle" : "exclamationmark.triangle")
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 6)
                    }
                }
            }
        }
    }
}

@MainActor public func doubleSystemVersion() -> Double {
    let rawSystemVersion = UIDevice.current.systemVersion
    let parsedSystemVersion = rawSystemVersion.split(separator: ".").prefix(2).joined(separator: ".")
    return Double(parsedSystemVersion) ?? 0.0
}

@MainActor
public class Alertinator {
    public static let shared = Alertinator()
    
    var alertController: UIAlertController?
    
    public func alert(title: String, body: String, showCancel: Bool = true) {
        Task { @MainActor in
            alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            if showCancel {
                alertController?.addAction(.init(title: "OK", style: .cancel))
            }
            alertController?.view.tintColor = UIColor(named: "AccentColor")
            self.present(alertController!)
        }
    }
    
    public func alert(title: String, body: String, showCancel: Bool = true, actionLabel: String = "OK", action: @escaping () -> Void) {
        Task { @MainActor in
            alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            alertController?.addAction(.init(title: actionLabel, style: .default) { _ in
                action()
            })
            if showCancel {
                alertController?.addAction(.init(title: "Cancel", style: .cancel))
            }
            alertController?.view.tintColor = UIColor(named: "AccentColor")
            self.present(alertController!)
        }
    }
    
    public func prompt(title: String, placeholder: String, showCancel: Bool = true, completion: @escaping (String?) async -> Void) {
        Task { @MainActor in
            alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alertController?.addTextField { field in
                field.placeholder = placeholder
            }
            if showCancel {
                alertController?.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    Task {
                        await completion(nil)
                    }
                })
            }
            alertController?.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                let field = self.alertController?.textFields?.first
                Task {
                    await completion(field?.text)
                }
            })
            alertController?.view.tintColor = UIColor(named: "AccentColor")
            self.present(alertController!)
        }
    }
    
    @MainActor
    private func present(_ alert: UIAlertController) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           var topController = window.rootViewController {
            
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(alert, animated: true)
        }
    }
}

enum AppPaths {
    static var backups: String {
        let url = backupsURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url.path
    }

    private static var backupsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseURL.appendingPathComponent("backups", isDirectory: true)
    }
}

enum TweakPaths {
    static var gestalt = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist"
    static var gestalt_dir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/"
}

public struct PlainAlert: View {
    var title: String
    var icon: String
    var text: String
    var color: Color
    
    public init(title: String = "", icon: String = "", text: String, color: Color = Color(.label)) {
        self.title = title
        self.icon = icon
        self.text = text
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .imageScale(.large)
            }
            VStack(alignment: .leading) {
                if !title.isEmpty {
                    Text(title)
                        .fontWeight(.bold)
                }
                Text(text)
                    .font(!title.isEmpty ? .subheadline : .body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

var terminalRad: CGFloat {
    if #available(iOS 19.0, *) { return 22 } else { return 14 }
}

public struct TerminalPlatter: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .scrollIndicators(.hidden)
            .frame(height: 250)
            .padding(.horizontal)
            .background(Color(.quaternarySystemFill), in: .rect(cornerRadius: terminalRad))
    }
}

struct LogView: View {
    @State private var log = ""

    var body: some View {
        GeometryReader { _ in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    Text(log)
                        .font(.system(size: 10, design: .monospaced))
                        .multilineTextAlignment(.leading)
                        .padding(.top)

                    Spacer()
                        .id(0)
                }
                .onAppear {
                    pipe.fileHandleForReading.readabilityHandler = { fh in
                        let data = fh.availableData

                        if data.isEmpty {
                            fh.readabilityHandler = nil
                            sema.signal()
                            return
                        }

                        guard let text = String(data: data, encoding: .utf8) else {
                            return
                        }

                        DispatchQueue.main.async {
                            log.append(text)
                            proxy.scrollTo(0)
                        }
                    }
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = log
                    } label: {
                        Label("Copy Output", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}
