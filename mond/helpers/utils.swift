//
//  utils.swift
//  mond
//
//  Created by ruter on 18.07.26.
//

import Darwin
import Foundation
import UIKit

func is_debugged() -> Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride

    let rc = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
    if rc != 0 { return false }

    let P_TRACED: Int32 = 0x00000800
    return (info.kp_proc.p_flag & P_TRACED) != 0
}

func is_supported() -> Bool {
    let v = ProcessInfo.processInfo.operatingSystemVersion
    
    return v.majorVersion == 27 &&
           v.minorVersion == 0 &&
           v.patchVersion == 0
}

func hasHomeButton() -> Bool {
    let sel = NSSelectorFromString("_hasHomeButton")
    return UIDevice.responds(to: sel) &&
        (UIDevice.perform(sel)?.takeUnretainedValue() as? Bool ?? false)
}
