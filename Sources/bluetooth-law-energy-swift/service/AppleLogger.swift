//
//  AppleLogger.swift
//
//
//  Created by Igor  on 23.07.24.
//

import os

/// A logger implementation that uses Apple's os.Logger for logging.
/// This class conforms to the ILogger protocol.
public class AppleLogger: ILogger {
    
    /// The underlying os.Logger instance used for logging.
    private let logger: Logger

    /// Initializes a new instance of AppleLogger with the specified subsystem and category.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (typically the bundle identifier of your app).
    ///   - category: The logging category (e.g., a specific module or feature).
    public init(subsystem: String, category: String) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    /// Logs a message at the specified log level.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The log level (e.g., .default, .info, .debug, .error). Defaults to .default.
    public func log(_ message: String, level: OSLogType = .default) {
        logger.log(level: level, "\(message, privacy: .public)")
    }
}
