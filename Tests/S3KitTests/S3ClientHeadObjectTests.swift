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

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Test
func headObject() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
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
                    "Content-Type": "image/jpeg",
                    "test-header": "test-value",
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
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)

    #expect(data.eTag == "\"e5a8627dc082f11998d9526e6bc1c542\"")
    #expect(data.size == 7195686)
    #expect(data.lastModified == rfcDateFormatter.date(from: "Tue, 01 May 2000 18:30:59 GMT"))
    #expect(data.contentType == "image/jpeg")
    #expect(data.value(forHeaderField: "test-header") == "test-value")
}

@Test
func headObject_withCustomHeaders() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
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
        key: "image1.jpg",
        customHeaders: [
            "x-aws-custom-header": "custom-header-value",
            "Authorization": "reserved-header",
            "Host": "reserved-header",
            "Content-Length": "reserved-header",
            "x-amz-date": "reserved-header",
            "x-amz-content-sha256": "reserved-header",
        ]
    )

    #expect(urlRequest.httpMethod == "HEAD")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-aws-custom-header") == "custom-header-value")

    #expect(data.eTag == "\"e5a8627dc082f11998d9526e6bc1c542\"")
    #expect(data.size == 7195686)
    #expect(data.lastModified == rfcDateFormatter.date(from: "Tue, 01 May 2000 18:30:59 GMT"))
    #expect(data.contentType == "image/jpeg")
}

@Test
func headObject_withoutContentType() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
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
                    "Last-Modified": "Tue, 01 May 2000 18:30:59 GMT"
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
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)

    #expect(data.eTag == "\"e5a8627dc082f11998d9526e6bc1c542\"")
    #expect(data.size == 7195686)
    #expect(data.lastModified == rfcDateFormatter.date(from: "Tue, 01 May 2000 18:30:59 GMT"))
    #expect(data.contentType == nil)
}

@Test
func headObject_missingETagHeader() async throws {
    let httpClient = MockS3HTTPClient { request in
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

    await #expect(throws: S3Error.missingResponseHeader("ETag")) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func headObject_missingContentLengthHeader() async throws {
    let httpClient = MockS3HTTPClient { request in
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

    await #expect(throws: S3Error.missingResponseHeader("Content-Length")) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func headObject_invalidContentLengthHeader() async throws {
    let httpClient = MockS3HTTPClient { request in
        return (
            Data(),
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\"",
                    "Content-Length": "abc",
                    "Last-Modified": "Tue, 01 May 2000 18:30:59 GMT",
                    "Content-Type": "image/jpeg"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    await #expect(throws: S3Error.missingResponseHeader("Content-Length")) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func headObject_missingLastModifiedHeader() async throws {
    let httpClient = MockS3HTTPClient { request in
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

    await #expect(throws: S3Error.missingResponseHeader("Last-Modified")) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func headObject_invalidLastModifiedHeader() async throws {
    let httpClient = MockS3HTTPClient { request in
        return (
            Data(),
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\"",
                    "Content-Length": "7195686",
                    "Last-Modified": "not-a-date",
                    "Content-Type": "image/jpeg"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    await #expect(throws: S3Error.missingResponseHeader("Last-Modified")) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func headObject_invalidStatusCode() async throws {
    let httpClient = MockS3HTTPClient { request in
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

    await #expect(throws: S3Error.responseError(statusCode: 500, errorData: someError)) {
        try await client.headObject(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}
