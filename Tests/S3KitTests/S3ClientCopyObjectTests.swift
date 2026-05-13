//
//  S3ClientCopyObjectTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 13/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Test
func copyObject() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            someData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    try await client.copyObject(
        sourceBucket: "sourceBucket",
        sourceKey: "image1.jpg",
        bucket: "destinationBucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/destinationBucket/image1.jpg")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-copy-source") == "/sourceBucket/image1.jpg")
}

@Test
func copyObject_spaceEncodedKey() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            someData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    try await client.copyObject(
        sourceBucket: "sourceBucket",
        sourceKey: "some key.jpg",
        bucket: "destinationBucket",
        key: "some key.jpg"
    )

    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/destinationBucket/some%20key.jpg")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-copy-source") == "/sourceBucket/some%20key.jpg")
}

@Test
func copyObject_invalidStatusCode() async throws {
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
        try await client.copyObject(
            sourceBucket: "sourceBucket",
            sourceKey: "image1.jpg",
            bucket: "destinationBucket",
            key: "image1.jpg"
        )
    }
}
