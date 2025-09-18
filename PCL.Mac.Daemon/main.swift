//
//  main.swift
//  PCL.Mac.Daemon
//
//  Created by YiZhiMCQiu on 8/6/25.
//

import Foundation
import AppKit

func showDialog(message: String, title: String = "提示") {
    let script = "display dialog \"\(message)\" with title \"\(title)\" buttons {\"确定\"} default button \"确定\" with icon stop"
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = ["-e", script]
    task.launch()
    task.waitUntilExit()
}

func exportCrashReport(_ crashTime: Date, _ diagnosticReportURL: URL) {
    do {
        log("正在导出崩溃报告")
        let fileManager = FileManager.default
        let reportURL = fileManager
            .homeDirectoryForCurrentUser
            .appending(path: "Desktop")
            .appending(path: "PCL.Mac-crash-\(crashTime.timeIntervalSince1970)")
        try fileManager.createDirectory(at: reportURL, withIntermediateDirectories: true)
        try fileManager.copyItem(at: diagnosticReportURL, to: reportURL.appending(path: "诊断报告.ips"))
        let logURL = fileManager.homeDirectoryForCurrentUser
            .appending(path: "Library")
            .appending(path: "Application Support")
            .appending(path: "PCL-Mac")
            .appending(path: "Logs")
            .appending(path: "app.log")
        try fileManager.copyItem(at: logURL, to: reportURL.appending(path: "启动器日志.log"))
        showDialog(message: "很抱歉，PCL.Mac 因为一些问题崩溃了……\n一个诊断报告已被生成在你的桌面上。\n若要寻求帮助，请将诊断报告压缩并发给他人，而不是发送此页面的照片或截图。")
    } catch {
        err("无法导出崩溃报告: \(error.localizedDescription)")
    }
}

let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

if arguments.count != 2 {
    print("Usage: daemon <pid> <flag_path>")
    exit(1)
}

guard let parentPID: pid_t = Int32(arguments[0]) else {
    print("Invalid PID")
    exit(1)
}
let flagURL: URL = URL(fileURLWithPath: arguments[1])

debug("父进程 PID: \(parentPID)")
debug("正常退出标记位置: \(flagURL.path)")

let source: any DispatchSourceProcess = DispatchSource.makeProcessSource(identifier: parentPID, eventMask: .exit)
source.setEventHandler {
    if FileManager.default.fileExists(atPath: flagURL.path) {
        log("进程非正常退出")
        let crashTime = Date()
        let watcher = CrashReportWatcher()
        log("开始监听诊断报告目录")
        watcher.startWatching { url in
            if url.lastPathComponent.starts(with: "PCL.Mac") {
                log("发现诊断报告 \(url.lastPathComponent)")
                exportCrashReport(crashTime, url)
                exit(0)
            }
        }
        warn("未检测到诊断报告创建")
        exit(0)
    } else {
        log("进程正常退出")
    }
}
source.resume()
dispatchMain()
