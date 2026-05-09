//
//  S3ClientHeadObjectTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 07/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func headObject_validResponse() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockHTTPClient { request in
        urlRequest = request

        return (
            Data(),
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\"",
                    "Content-Length": "7195686",
                    "Last-Modified": "Tue, 01 May 2000 18:30:59 GMT",
                    "Content-Type": "image/jpeg"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let data = try await client.headObject(
        bucket: "bucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "HEAD")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    
    #expect(data.eTag == "e5a8627dc082f11998d9526e6bc1c542")
    #expect(data.size == 7195686)
    #expect(data.lastModified == rfcDateFormatter.date(from: "Tue, 01 May 2000 18:30:59 GMT"))
    #expect(data.contentType == "image/jpeg")
}

@Test
func headObject_missingETagHeader() async throws {
    let httpClient = MockHTTPClient { request in
        return (
            Data(),
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "Content-Length": "7195686",
                    "Last-Modified": "Tue, 01 May 2000 18:30:59 GMT",
                    "Content-Type": "image/jpeg"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    await #expect(throws: S3Error.missingHeader("ETag")) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func headObject_missingContentLengthHeader() async throws {
    let httpClient = MockHTTPClient { request in
        return (
            Data(),
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\"",
                    "Last-Modified": "Tue, 01 May 2000 18:30:59 GMT",
                    "Content-Type": "image/jpeg"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    await #expect(throws: S3Error.missingHeader("Content-Length")) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func headObject_missingLastModifiedHeader() async throws {
    let httpClient = MockHTTPClient { request in
        return (
            Data(),
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\"",
                    "Content-Length": "7195686",
                    "Content-Type": "image/jpeg"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    await #expect(throws: S3Error.missingHeader("Last-Modified")) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func headObject_invalidEndpoint() async throws {
    let httpClient = MockHTTPClient { request in
        Issue.record("HTTP client should not have been called")
        throw URLError(.unknown)
    }

    let client = createS3Client(
        endpoint: "https://example local",
        httpClient: httpClient
    )

    await #expect(throws: S3Error.invalidEndpoint("https://example local")) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func headObject_invalidStatusCode() async throws {
    let httpClient = MockHTTPClient { request in
        return (
            someErrorData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: [
                    "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\"",
                    "Content-Length": "7195686",
                    "Last-Modified": "Tue, 01 May 2000 18:30:59 GMT",
                    "Content-Type": "image/jpeg"
                ]
            )!
        )
    }

    let client = createS3Client(
        endpoint: "https://example.local",
        httpClient: httpClient
    )

    await #expect(throws: S3Error.errorResponse(statusCode: 500, body: someErrorData)) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}
