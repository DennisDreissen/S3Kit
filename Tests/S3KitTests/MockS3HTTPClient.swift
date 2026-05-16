//
//  MockS3HTTPClient.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 07/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation
import S3Kit

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class MockS3HTTPClient: S3HTTPClient, Sendable {

    typealias Handler = @Sendable (URLRequest) throws -> (Data, URLResponse)

    private let handler: Handler
    nonisolated(unsafe) var capturedBody: Data?

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedBody = request.httpBody
        return try handler(request)
    }

    func upload(
        for request: URLRequest,
        from data: Data,
        progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> (Data, URLResponse) {
        progressHandler?(0.3)
        progressHandler?(0.6)
        progressHandler?(0.9)
        progressHandler?(1.0)
        capturedBody = data
        return try handler(request)
    }
}
