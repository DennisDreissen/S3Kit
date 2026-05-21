//
//  S3Response.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 16/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

public struct S3Response<Result: Sendable>: Sendable {

    /// The response from the S3 service.
    public let result: Result

    /// The response status code from the S3 service.
    public let statusCode: Int

    /// The raw response headers from the S3 service.
    public let headers: [String: String]

    /// Retrieve a header from the response headers by key.
    public func value(forHeaderField key: String) -> String? {
        headers.first { $0.key.caseInsensitiveCompare(key) == .orderedSame }?.value
    }

    public init(result: Result, statusCode: Int, headers: [String : String]) {
        self.result = result
        self.statusCode = statusCode
        self.headers = headers
    }
}
