//
//  S3ClientHeadBucketTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 09/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func headBucket_validResponse() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockHTTPClient { request in
        urlRequest = request

        return (
            Data(),
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    try await client.headBucket(
        bucket: "bucket"
    )

    #expect(urlRequest.httpMethod == "HEAD")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
}

@Test
func headBucket_invalidEndpoint() async throws {
    let httpClient = MockHTTPClient { request in
        Issue.record("HTTP client should not have been called")
        throw URLError(.unknown)
    }

    let client = createS3Client(
        endpoint: "https://example local",
        httpClient: httpClient
    )

    await #expect(throws: S3Error.invalidEndpoint("https://example local")) {
        try await client.headBucket(
            bucket: "bucket",
        )
    }
}

@Test
func headBucket_invalidStatusCode() async throws {
    let httpClient = MockHTTPClient { request in
        return (
            someErrorData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(
        endpoint: "https://example.local",
        httpClient: httpClient
    )

    await #expect(throws: S3Error.errorResponse(statusCode: 500, body: someErrorData)) {
        try await client.headBucket(
            bucket: "bucket",
        )
    }
}
