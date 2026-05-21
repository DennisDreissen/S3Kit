//
//  Helpers.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation
import S3Kit

func testData(kilobytes: Int) -> Data {
    var data = Data(count: kilobytes * 1024)
    data.withUnsafeMutableBytes {
        arc4random_buf($0.baseAddress!, $0.count)
    }
    return data
}

func testData(megabytes: Int) -> Data {
    testData(kilobytes: megabytes * 1024)
}

func createS3Client() -> S3Client {
    let endpoint = URL(string:
        ProcessInfo.processInfo.environment["S3_ENDPOINT"] ?? "http://localhost:29145"
    )!

    return S3Client(
        endpoint: endpoint,
        credentials: S3Credentials(
            accessKeyId: "s3client_integration_tests",
            secretAccessKey: "s3client_integration_tests"
        )
    )
}

extension AsyncThrowingStream where Element == Data {

    func collect() async throws -> Data {
        try await reduce(into: Data()) { @Sendable in $0.append($1) }
    }
}
