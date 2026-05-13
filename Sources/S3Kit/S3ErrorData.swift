//
//  S3Object.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public struct S3ErrorData: Sendable, Equatable {

    /// S3 error code identifying the error type.
    public let code: String

    /// Human-readable description of the error.
    public let message: String?

    /// Unique identifier for the request.
    public let requestId: String?

    public init(code: String, message: String? = nil, requestId: String? = nil) {
        self.code = code
        self.message = message
        self.requestId = requestId
    }
}
