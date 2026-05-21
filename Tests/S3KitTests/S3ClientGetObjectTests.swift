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

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Test
func getObject() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            someData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "test-header": "test-value"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.getObject(
        bucket: "bucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)

    #expect(response.result == someData)
    #expect(response.value(forHeaderField: "test-header") == "test-value")
}

@Test
func getObject_withCustomHeaders() async throws {
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

    let response = try await client.getObject(
        bucket: "bucket",
        key: "image1.jpg",
        customHeaders: [
            "x-aws-custom-header": "custom-header-value",
            "Authorization": "reserved-header",
            "Host": "reserved-header",
            "Content-Length": "reserved-header",
            "x-amz-date": "reserved-header",
            "x-amz-content-sha256": "reserved-header"
        ]
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-aws-custom-header") == "custom-header-value")

    #expect(response.result == someData)
}

@Test
func getObject_returnsInvalidStatusCode() async throws {
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
        try await client.getObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func getObject_returnsInvalidStatusCodeWithInvalidErrorBody() async throws {
    let httpClient = MockS3HTTPClient { request in
        return (
            someData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    await #expect(throws: S3Error.responseError(statusCode: 500, errorData: nil)) {
        try await client.getObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}
