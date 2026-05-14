//
//  S3ClientPutObjectTests.swift
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
func putObject() async throws {
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

    try await client.putObject(
        data: someData,
        bucket: "bucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Length") == "\(someData.count)")
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == nil)
    #expect(urlRequest.httpBody == someData)
}

@Test
func putObject_signerAlgorithmSigV4a() async throws {
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

    let client = createS3Client(signerAlgorithm: .sigV4a, httpClient: httpClient)

    try await client.putObject(
        data: someData,
        bucket: "bucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Length") == "\(someData.count)")
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == nil)
    #expect(urlRequest.httpBody == someData)
}

@Test
func putObject_withContentType() async throws {
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

    try await client.putObject(
        data: someData,
        bucket: "bucket",
        key: "image1.jpg",
        contentType: "image/jpeg"
    )

    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Length") == "\(someData.count)")
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "image/jpeg")
    #expect(urlRequest.httpBody == someData)
}

@Test
func putObject_withEmptyData() async throws {
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

    try await client.putObject(
        data: Data(),
        bucket: "bucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Length") == nil)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == nil)
    #expect(urlRequest.httpBody == nil)
}

@Test
func putObject_invalidStatusCode() async throws {
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
        try await client.putObject(
            data: someData,
            bucket: "bucket",
            key: "image1.jpg",
            contentType: "image/jpeg"
        )
    }
}
