//
//  S3ClientGetObjectTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 07/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func getObject_validResponse() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockHTTPClient { request in
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

    let data = try await client.getObject(
        bucket: "bucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)

    #expect(data == someData)
}

@Test
func getObject_validResponseAWSClient() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockHTTPClient { request in
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

    let client = S3Client(
        region: "eu-west-3",
        credentials: StaticCredential(
            accessKeyId: "accessKeyId",
            secretAccessKey: "secretAccessKey"
        ),
        httpClient: httpClient
    )

    let data = try await client.getObject(
        bucket: "bucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString == "https://s3.eu-west-3.amazonaws.com/bucket/image1.jpg")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)

    #expect(data == someData)
}

@Test
func getObject_invalidEndpoint() async throws {
    let httpClient = MockHTTPClient { request in
        Issue.record("HTTP client should not have been called")
        throw URLError(.unknown)
    }

    let client = createS3Client(
        endpoint: "https://example local",
        httpClient: httpClient
    )

    await #expect(throws: S3Error.invalidEndpoint("https://example local")) {
        try await client.getObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func getObject_invalidStatusCode() async throws {
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
        try await client.getObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}
