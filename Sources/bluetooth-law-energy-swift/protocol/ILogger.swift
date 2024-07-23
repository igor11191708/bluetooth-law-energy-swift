//
//  ILogger.swift
//
//
//  Created by Igor  on 23.07.24.
//

import os

/// Protocol defining a logger with a log method.
public protocol ILogger {
    /// Logs a message with a specified log level.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The log level of type `OSLogType`.
    func log(_ message: String, level: OSLogType)
}

