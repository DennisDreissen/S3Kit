//
//  S3HTTPClient.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 07/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol S3HTTPClient: Sendable {

    func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse)

    func upload(
        for request: URLRequest,
        from data: Data,
        progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> (Data, URLResponse)
}

public final class S3DefaultHTTPClient: S3HTTPClient, Sendable {

    /// The URLSession instance used to make HTTP requests.
    let session: URLSession

    public init(configuration: URLSessionConfiguration = .default) {
        self.session = URLSession(
            configuration: configuration,
            delegate: nil,
            delegateQueue: nil
        )
    }

    deinit {
        session.finishTasksAndInvalidate()
    }

    public func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }

    public func upload(
        for request: URLRequest,
        from data: Data,
        progressHandler: (@Sendable (Double) -> Void)?
    ) async throws -> (Data, URLResponse) {
        let delegate = progressHandler.map { S3DefaultUploadProgressDelegate(progressHandler: $0) }
        return try await session.upload(for: request, from: data, delegate: delegate)
    }
}

final class S3DefaultUploadProgressDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {

    let progressHandler: @Sendable (Double) -> Void

    init(progressHandler: @escaping @Sendable (Double) -> Void) {
        self.progressHandler = progressHandler
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard totalBytesExpectedToSend > 0 else {
            return
        }

        progressHandler(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
    }
}
