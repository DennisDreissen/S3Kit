//
//  MockS3HTTPClient.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 07/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation
import S3Kit

final class MockS3HTTPClient: S3HTTPClient, Sendable {

    typealias Handler = @Sendable (URLRequest) throws -> (Data, URLResponse)

    private let handler: Handler

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}
