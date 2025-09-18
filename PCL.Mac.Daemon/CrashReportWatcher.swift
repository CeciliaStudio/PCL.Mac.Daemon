//
//  CrashReportWatcher.swift
//  PCL.Mac.Daemon
//
//  Created by YiZhiMCQiu on 2025/9/18.
//

import Foundation

final class CrashReportWatcher {
    func startWatching(onFileCreate: @escaping (URL) -> Void) {
        let fileManager = FileManager.default
        
        let diagnosticDir: URL = fileManager
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("DiagnosticReports", isDirectory: true)
        
        guard fileManager.fileExists(atPath: diagnosticDir.path) else {
            return
        }
        
        var knownFiles: Set<URL> = []
        if let initial = try? fileManager.contentsOfDirectory(
            at: diagnosticDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            knownFiles = Set(initial.filter { $0.hasDirectoryPath == false })
        }
        
        let deadline = Date().addingTimeInterval(10.0)
        let pollInterval: TimeInterval = 0.5
        
        while Date() < deadline {
            autoreleasepool {
                if let current = try? fileManager.contentsOfDirectory(
                    at: diagnosticDir,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                ) {
                    let files = current.filter { $0.hasDirectoryPath == false }
                    
                    for fileURL in files {
                        if !knownFiles.contains(fileURL) {
                            knownFiles.insert(fileURL)
                            onFileCreate(fileURL)
                        }
                    }
                }
            }
            Thread.sleep(forTimeInterval: pollInterval)
        }
    }
}
