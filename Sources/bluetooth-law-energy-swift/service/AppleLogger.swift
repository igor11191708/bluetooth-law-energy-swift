//
//  AppleLogger.swift
//
//
//  Created by Igor  on 23.07.24.
//

import os

public class AppleLogger: ILogger {
    
    private let logger: Logger

    public init(subsystem: String, category: String) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(_ message: String, level: OSLogType = .default) {
        logger.log(level: level, "\(message, privacy: .public)")
    }
}
