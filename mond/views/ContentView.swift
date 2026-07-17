//
//  ContentView.swift
//  mond
//
//  Created by ruter on 16.07.26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @AppStorage("mg_devicename") private var mg_devicename: String = ""
    
    @State private var mg_dict_now: NSMutableDictionary = NSMutableDictionary()
    @State private var is_valid: Bool = false
    
    @State private var subtype: Int = 0
    @State private var og_subtype: Int = 0
    @State private var og_devicename: String = ""
    @State private var enable_devicename: Bool = false
    @State private var product_type: String = ""
    
    @State private var show_logs: Bool = false
    @State private var show_confirm: Bool = false
    
    private var mg_valid: Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt)) else { return false }
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) != nil
    }
    
    private var mg_empty: Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: TweakPaths.gestalt),
              let size = attributes[.size] as? UInt64 else { return false }

        return size == 0
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !mg_valid || mg_empty {
                    Section {
                        if mg_empty {
                            PlainAlert(title: "Do not reboot!", icon: "exclamationmark.triangle.fill", text: "Your MobileGestalt.plist seems to be empty.", color: Color.yellow)
                        }
                        
                        if !mg_valid {
                            PlainAlert(title: "Do not reboot!", icon: "exclamationmark.triangle.fill", text: "Your MobileGestalt.plist seems to be invalid.", color: Color.yellow)
                        }
                    } header: {
                        Label("Warning", systemImage: "exclamationmark.triangle")
                    } footer: {
                        Text("Rebooting now might cause a bootloop. Try pressing 'Revert Tweaks'. If the warnings dont go away after that, you're fucked.")
                    }
                }
                
                Section {
                    Button {
                        mg_apply()
                    } label: {
                        Text("Apply Tweaks")
                    }
                    
                    Button {
                        mg_revert()
                    } label: {
                        Text("Revert Tweaks")
                    }
                } footer: {
                    Text("**WARNING:** These tweaks have the capability to break features on your device or softbrick it if misused!")
                }
                
                Section {
                    Picker(selection: $subtype) {
                        Text("Original (\(og_subtype))").tag(og_subtype)
                        if isDeviceNotBroke() {
                            Text("Disable Dynamic Island").tag(2436)
                        }
                        Text("iPhone 14 Pro").tag(2436)
                        Text("iPhone 14 Pro Max").tag(2796)
                        Text("iPhone 15 Pro Max").tag(2976)
                        if doubleSystemVersion() >= 18.0 {
                            Text("iPhone 16 Pro").tag(2622)
                            Text("iPhone 16 Pro Max").tag(2868)
                        }
                        if doubleSystemVersion() >= 26.0 {
                            Text("iPhone Air").tag(2736)
                        }
                        if hasHomeButton() {
                            Text("iPhone X Gestures").tag(2436)
                        }
                    } label: {
                        HStack {
                            Text("Subtype")
                            Spacer()
                        }
                    }
                    
                    Toggle("Custom Device Name", isOn: $enable_devicename)
                    
                    if enable_devicename {
                        TextField("Device Name", text: $mg_devicename)
                    }
                } header: {
                    Label("Device Artwork", systemImage: "paintbrush.pointed")
                }
                
                // basic tweak toggles
                Section {
                    PlainToggle(text: "Dynamic Island", minSupportedVersion: 19.0, isOn: mgKeyBinding(["YlEtTtHlNesRBMal1CqRaA"]))
                    PlainToggle(text: "Always On Display", minSupportedVersion: 18.0, isOn: mgKeyBinding(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]))
                    PlainToggle(text: "AOD Vibrancy", minSupportedVersion: 18.0, isOn: mgKeyBinding(["ykpu7qyhqFweVMKtxNylWA"]))
                    PlainToggle(text: "Charge Limit", minSupportedVersion: 17.0, isOn: mgKeyBinding(["37NVydb//GP/GrhuTN+exg"]))
                    PlainToggle(text: "Boot Chime", isOn: mgKeyBinding(["QHxt+hGLaBPbQJbXiUJX3w"]))
                    PlainToggle(text: "Liquid Glass LPM", minSupportedVersion: 19.0, isOn: mgKeyBinding(["SAGvsp6O6kAQ4fEfDJpC4Q"]))
                } header: {
                    Label("Software-Oriented Features", systemImage: "gearshape")
                }
                
                Section {
                    PlainToggle(text: "Camera Control", minSupportedVersion: 18.0, isOn: mgKeyBinding(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]))
                    PlainToggle(text: "Action Button", minSupportedVersion: 17.0, isOn: mgKeyBinding(["cT44WE1EohiwRzhsZ8xEsw"]))
                    PlainToggle(text: "Crash Detection", isOn: mgKeyBinding(["HCzWusHQwZDea6nNhaKndw"]))
                    if hasHomeButton() {
                        PlainToggle(text: "Enable Tap to Wake", isOn: mgKeyBinding(["yZf3GTRMGTuwSV/lD7Cagw"]))
                    }
                    PlainToggle(text: "Pulse Width Modulation", minSupportedVersion: 19.0, isOn: mgKeyBinding(["6IejgN+1Fmu5/QrZFOIeNw"]))
                } header: {
                    Label("Hardware-Oriented Features", systemImage: "iphone")
                }
                
                Section {
                    PlainToggle(text: "Security Research Device UI", minSupportedVersion: 26.0, isOn: mgKeyBinding(["XYlJKKkj2hztRP1NWWnhlw"]))
                    PlainToggle(text: "Disable Region Restrictions", isOn: mgRegionRestrictionsBinding())
                    PlainToggle(text: "Apple Intelligence", minSupportedVersion: 18.1, isOn: mgKeyBinding(["A62OafQ85EJAiiqKn4agtg"]))
                    HStack(spacing: 10) {
                        Picker("Spoofing", selection: $product_type) {
                            Text("Default").tag(machineName())
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                if doubleSystemVersion() >= 17.4 {
                                    Text("iPad Pro 11-inch (M4)").tag("iPad16,3")
                                    Text("iPad Pro 11-inch (M4, Cellular)").tag("iPad16,4")
                                }
                                Text("iPad Pro 11-inch (4th Gen)").tag("iPad14,3")
                                Text("iPad Pro 11-inch (4th Gen, Cellular)").tag("iPad14,4")
                            } else {
                                Text("iPhone 15 Pro").tag("iPhone16,1")
                                Text("iPhone 15 Pro Max").tag("iPhone16,2")
                                if doubleSystemVersion() >= 18.0 {
                                    Text("iPhone 16").tag("iPhone17,3")
                                    Text("iPhone 16 Plus").tag("iPhone17,4")
                                    Text("iPhone 16 Pro").tag("iPhone17,1")
                                    Text("iPhone 16 Pro Max").tag("iPhone17,2")
                                }
                                if doubleSystemVersion() >= 19.0 {
                                    Text("iPhone 17").tag("iPhone18,3")
                                    Text("iPhone 17 Pro").tag("iPhone18,1")
                                    Text("iPhone 17 Pro Max").tag("iPhone18,2")
                                    Text("iPhone Air").tag("iPhone18,4")
                                }
                            }
                        }
                        
                        Button {
                            Alertinator.shared.alert(
                                title: "Device Spoofing Info",
                                body: "Only spoof your device model if you want to download Apple Intelligence. This may break Face ID. If you decide to unspoof and want to keep Apple Intelligence, do NOT re-enter the Apple Intelligence & Siri menu in Settings."
                            )
                        } label: {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label("Eligibility", systemImage: "checklist")
                }
                
                Section {
                    let cacheExtra = mg_dict_now["CacheExtra"] as? NSMutableDictionary
                    
                    PlainToggle(text: "Allow Installing iPadOS Apps", isOn: mgKeyBinding(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, defaultValue: [1], enableValue: [1, 2]))
                    PlainToggle(text: "Apple Pencil Settings", isOn: mgKeyBinding(["yhHcB0iH0d1XzPO/CFd3ow"]))
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        PlainToggle(text: "Stage Manager", isOn: mgKeyBinding(["qeaj75wk3HF4DwQ8qbIi7g"]))
                    }
                    PlainToggle(
                        text: "iPadOS UI",
                        infoType: .warning,
                        infoMessage: "This is a very dangerous tweak to use! If you use an alphanumeric passcode, DO NOT USE THIS TWEAK AT ALL! Please do not turn off \"Show Dock In Stage Manager\" or your device will BOOTLOOP when rotating to landscape! With these two things in mind, you may experience general instability, or other major issues such as app data randomly disappearing. But I guess some funny multitasking features that still make the device relatively unusable are cool? Whatever dude, I'm not here to tell you how to use your own device.",
                        isOn: mgTrollPadBinding()
                    )
                    .disabled(cacheExtra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
                } header: {
                    Label("iPadOS Features", systemImage: "ipad")
                }
                
                Section {
                    PlainToggle(text: "Internal Storage", isOn: mgKeyBinding(["LBJfwOEzExRxzlAnSuI7eg"]))
                    PlainToggle(text: "Internal Features", isOn: mgInternalStuffBinding())
                    PlainToggle(text: "Metal HUD in All Apps", isOn: mgKeyBinding(["EqrsVvjcYDdxHBiQmGhAWw"]))
                } header: {
                    Label("Internal", systemImage: "ant")
                }
                
                Section {
                    CreditsRow(name: "roooot", role: "Main Developer", profile: URL(string: "https://github.com/rooootdev")!)
                    CreditsRow(name: "Jailbreak.Party", role: "UI Components", profile: URL(string: "https://github.com/jailbreakdotparty")!)
                } header: {
                    Label("Credits", systemImage: "person.3.fill")
                }
            }
            .navigationTitle("mond")
            .onAppear {
                cmg()
                mgLoadData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            show_logs = true
                        } label: {
                            Image(systemName: "apple.terminal")
                        }
                        
                        Button {
                            show_confirm = true
                        } label: {
                            Image(systemName: "goforward")
                        }
                    }
                }
            }
            .sheet(isPresented: $show_logs) {
                NavigationStack {
                    List {
                        Section {
                            LogView()
                                .modifier(TerminalPlatter())
                        } header: {
                            Label("Logs", systemImage: "apple.terminal")
                        }
                    }
                    .navigationTitle("Logs")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                show_logs = false
                            } label: {
                                Text("Done")
                                    .bold()
                            }
                        }
                    }
                }
            }
            .alert("Are you sure?", isPresented: $show_confirm) {
                Button("Cancel") {
                    show_confirm = falseg
                }
                
                Button("Confirm") {
                    state.respring()
                }
            } message: {
                Text("Confirm that you want to respring.")
            }
        }
    }
    
    private enum MGViewError: Error, LocalizedError {
        case missingArtworkSubtype
        case missingArtworkDeviceName
        
        var errorDescription: String? {
            switch self {
            case .missingArtworkSubtype:
                return "Failed to get ArtworkDeviceSubType!"
            case .missingArtworkDeviceName:
                return "Failed to get ArtworkDeviceProductDescription!"
            }
        }
    }
    
    private func mgLoadData() {
        do {
            let mgCurrentURL = URL(fileURLWithPath: TweakPaths.gestalt)
            mg_dict_now = try NSMutableDictionary(contentsOf: mgCurrentURL, error: ())
            
            // this'll cache gestalt and put it in a safe place
            let mgSavedURL = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            
            if !FileManager.default.fileExists(atPath: mgSavedURL.path) {
                try FileManager.default.copyItem(at: mgCurrentURL, to: mgSavedURL)
            }
            
            // get original gestalt values
            let mgSavedDict = try NSMutableDictionary(contentsOf: mgSavedURL, error: ())
            let ogCacheExtra = mgSavedDict["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            let ogArtwork = ogCacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            guard let ogSubtype = ogArtwork["ArtworkDeviceSubType"] as? Int else { throw MGViewError.missingArtworkSubtype }
            og_subtype = ogSubtype
            
            guard let ogDeviceName = ogArtwork["ArtworkDeviceProductDescription"] as? String else { throw MGViewError.missingArtworkDeviceName }
            
            // now get current gestalt values
            let cacheExtra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            let artwork = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            subtype = artwork["ArtworkDeviceSubType"] as? Int ?? ogSubtype // fallback
            mg_devicename = artwork["ArtworkDeviceProductDescription"] as? String ?? ogDeviceName
            
            // assume it's been changed
            if mg_devicename != ogDeviceName {
                enable_devicename = true
            }
            
            if let productType = cacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"] as? String, !productType.isEmpty {
                product_type = productType
            } else {
                product_type = machineName()
            }
        } catch {
            print("(mg) failed to load data: \(error)")
            Alertinator.shared.alert(title: "Failed to load current MobileGestalt!", body: "Restart the app and try again. Check logs for more detailed information.")
        }
    }
    
    private func mg_apply() {
        do {
            let cacheExtra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            if !product_type.isEmpty {
                cacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"] = product_type
            }
            
            let ArtworkDict = cacheExtra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            ArtworkDict["ArtworkDeviceSubType"] = subtype
            if enable_devicename {
                ArtworkDict["ArtworkDeviceProductDescription"] = mg_devicename
            }
            
            let data = try PropertyListSerialization.data(fromPropertyList: mg_dict_now, format: .xml, options: 0)

            try writeGestaltData(data)
            mg_dict_now = NSMutableDictionary()
            enable_devicename = false

            print("(mg) successfully overwrote mobilegestalt!")
            Alertinator.shared.alert(title: "Successfully applied Gestalt tweaks!", body: "Respring your device for changes to take effect. Note that some tweaks may require a reboot for them to apply properly.", actionLabel: "Respring", action: {
                state.respring()
            })
        } catch {
            print("(mg) failed to apply mobilegestalt: \(error)")
            Alertinator.shared.alert(title: "Failed to apply MobileGestalt!", body: "Restart the app and try again. Check logs for more detailed information.")
        }
    }
    
    private func mg_revert() {
        do {
            let backupURL = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            let backupData = try Data(contentsOf: backupURL)
            try writeGestaltData(backupData)

            print("(mg) successfully reverted mobilegestalt!)")
            Alertinator.shared.alert(title: "Successfully reverted Gestalt tweaks!", body: "Reboot your device for changes to take effect.")
        } catch {
            // The direct file write path now surfaces the underlying error through the catch.
            print("(mg) failed to revert mobilegestalt: \(error)")
            Alertinator.shared.alert(title: "Failed to revert MobileGestalt!", body: "Check logs for error information.")
        }
    }

    private func writeGestaltData(_ data: Data) throws {
        let targetURL = URL(fileURLWithPath: TweakPaths.gestalt)
        let fileManager = FileManager.default
        let tempURL = targetURL.deletingLastPathComponent()
            .appendingPathComponent(".\(targetURL.lastPathComponent).\(UUID().uuidString).tmp")

        try data.write(to: tempURL, options: [.withoutOverwriting])
        defer { try? fileManager.removeItem(at: tempURL) }

        if fileManager.fileExists(atPath: targetURL.path) {
            _ = try fileManager.replaceItemAt(targetURL, withItemAt: tempURL)
        } else {
            try fileManager.moveItem(at: tempURL, to: targetURL)
        }
    }
    
    // MARK: bindings
    private func mgKeyBinding<T: Equatable>(_ keys: [String], type: T.Type = Int.self, defaultValue: T? = 0, enableValue: T? = 1) -> Binding<Bool>  {
        guard let cacheExtra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        return Binding(get: {
            if let value = cacheExtra[keys.first!] as? T?, let enableValue {
                return value == enableValue
            }
            return false
        }, set: { enabled in
            for key in keys {
                // if it exists inside of the plist, then update it. if not then pull the value completely.
                if enabled {
                    cacheExtra[key] = enableValue
                } else {
                    cacheExtra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mgTrollPadBinding() -> Binding<Bool> {
        guard let cacheData = mg_dict_now["CacheData"] as? NSMutableData,
                let cacheExtra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        let valueOffset = cache_data_offset("mtrAoWJ3gsq+I90ZnQ0vQw")
        let keys = [
            "uKc7FPnEO++lVhHWHFlGbQ", // ipad
            "mG0AnH/Vy1veoqoLRAIgTA", // MedusaFloatingLiveAppCapability
            "UCG5MkVahJxG1YULbbd5Bg", // MedusaOverlayAppCapability
            "ZYqko/XM5zD3XBfN5RmaXA", // MedusaPinnedAppCapability
            "nVh/gwNpy7Jv1NOk00CMrw", // MedusaPIPCapability,
            "qeaj75wk3HF4DwQ8qbIi7g", // DeviceSupportsEnhancedMultitasking
        ]
        
        return Binding(get: {
            if let value = cacheExtra[keys.first!] as? Int? {
                return value == 1
            }
            return false
        }, set: { enabled in
            if enabled {
                Alertinator.shared.alert(title: "Warning!", body: "This is a very dangerous tweak to use! If you use an alphanumeric passcode, DO NOT USE THIS TWEAK AT ALL! Please do not turn off \"Show Dock In Stage Manager\" or your device will BOOTLOOP when rotating to landscape! With these two things in mind, you may experience general instability, or other major issues such as app data randomly disappearing. I'm honestly not too certain why you'd want to use this tweak anyways, it's not like your device is gonna be all that usable (due to apps scaling weirdly) when it's enabled.")
            }
            cacheData.mutableBytes.storeBytes(of: enabled ? 3 : 1, toByteOffset: valueOffset, as: Int.self)
            for key in keys {
                if enabled {
                    cacheExtra[key] = 1
                } else {
                    cacheExtra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mgRegionRestrictionsBinding() -> Binding<Bool> {
        guard let cacheExtra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        return Binding<Bool>(
            get: {
                return cacheExtra["h63QSdBCiT/z0WU6rdQv6Q"] as? String == "US" &&
                    cacheExtra["zHeENZu+wbg7PUprwNwBWg"] as? String == "LL/A"
            },
            set: { enabled in
                if enabled {
                    Alertinator.shared.alert(title: "Warning!", body: "Please do not use this feature to bypass region restrictions that would equate to breaking regional laws (e.g. disabling the camera shutter sound). We will NOT be held responsible for enabling any illegal activites!")
                    cacheExtra["h63QSdBCiT/z0WU6rdQv6Q"] = "US"
                    cacheExtra["zHeENZu+wbg7PUprwNwBWg"] = "LL/A"
                } else {
                    cacheExtra.removeObject(forKey: "h63QSdBCiT/z0WU6rdQv6Q")
                    cacheExtra.removeObject(forKey: "zHeENZu+wbg7PUprwNwBWg")
                }
            }
        )
    }
    
    private func mgInternalStuffBinding() -> Binding<Bool> {
        guard let cacheData = mg_dict_now["CacheData"] as? NSMutableData else {
            return .constant(false)
        }
        
        let off_appleInternalInstall = cache_data_offset("EqrsVvjcYDdxHBiQmGhAWw")
        let off_HasInternalSettingsBundle = cache_data_offset("Oji6HRoPi7rH7HPdWVakuw")
        let off_InternalBuild = cache_data_offset("LBJfwOEzExRxzlAnSuI7eg")
        
        return Binding(
            get: {
                return cacheData.bytes.load(fromByteOffset: off_appleInternalInstall, as: Int.self) == 1
            },
            set: { enabled in
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_appleInternalInstall, as: Int.self)
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_HasInternalSettingsBundle, as: Int.self)
                cacheData.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_InternalBuild, as: Int.self)
            }
        )
    }
    
    // MARK: device info getters
    private func isDeviceNotBroke() -> Bool {
        let supportedDevices: [String] = ["iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2", "iPhone17,3", "iPhone17,4", "iPhone17,1", "iPhone17,2", "iPhone18,3", "iPhone18,1", "iPhone18,2", "iPhone17,5"]
        if supportedDevices.contains(machineName()) && doubleSystemVersion() < 19.0 {
            return true
        }
        return false
    }
    
    private func machineName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}

struct CreditsRow: View {
    let name: String
    let role: String
    let profile: URL

    private var pfp: URL? {
        URL(string: profile.absoluteString + ".png")
    }

    var body: some View {
        HStack(alignment: .top) {
            AsyncImage(url: pfp) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)

                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .onTapGesture {
            UIApplication.shared.open(profile)
        }
    }
}
