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

    func download(
        for request: URLRequest
    ) async throws -> (URL, URLResponse) {
        let (data, response) = try handler(request)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try data.write(to: url)

        capturedBody = data
        return (url, response)
    }

    func upload(
        for request: URLRequest,
        from data: Data,
        progressHandler: S3HTTPClient.ProgressHandler?
    ) async throws -> (Data, URLResponse) {
        let simulatedSize = Int64(data.count / 3)
        progressHandler?(simulatedSize, simulatedSize, Int64(data.count))
        progressHandler?(simulatedSize, simulatedSize * 2, Int64(data.count))
        progressHandler?(simulatedSize, Int64(data.count), Int64(data.count))

        capturedBody = data
        return try handler(request)
    }
}
