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

    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct DefaultS3HTTPClient: S3HTTPClient, @unchecked Sendable {

    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
        try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }
            task.resume()
        }
        #else
        try await session.data(for: request)
        #endif
    }
}
