//
//  ILogger.swift
//
//
//  Created by Igor  on 23.07.24.
//

import os

public protocol ILogger {
    func log(_ message: String, level: OSLogType)
}

