//
//  S3Response.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 16/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

@dynamicMemberLookup
public struct S3Response<Result: Sendable>: Sendable {

    /// The response object from the request to the S3 service.
    public let result: Result

    /// The raw response headers from the S3 service.
    public let headers: [String: String]

    public subscript<T>(dynamicMember keyPath: KeyPath<Result, T>) -> T {
        result[keyPath: keyPath]
    }
}
