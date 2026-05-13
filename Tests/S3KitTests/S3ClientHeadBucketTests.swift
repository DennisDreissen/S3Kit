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

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Test
func headBucket() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
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
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
}

@Test
func headBucket_invalidStatusCode() async throws {
    let httpClient = MockS3HTTPClient { request in
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

    await #expect(throws: S3Error.responseError(statusCode: 500, errorData: someError)) {
        try await client.headBucket(
            bucket: "bucket",
        )
    }
}
