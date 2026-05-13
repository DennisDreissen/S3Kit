//
//  S3PutObjectMultipartTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 07/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func createMultipartUpload() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            createMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:],
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let uploadId = try await client.createMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploads=")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)

    #expect(uploadId == "test-upload-id")
}

@Test
func createMultipartUpload_withContentType() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            createMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:],
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let uploadId = try await client.createMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg",
        contentType: "some/content-type"
    )

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploads=")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["Content-Type"] == "some/content-type")

    #expect(uploadId == "test-upload-id")
}

@Test
func createMultipartUpload_invalidResponseMalformedXML() async throws {
    let httpClient = MockS3HTTPClient { request in
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

    let client = createS3Client(
        endpoint: "https://example.local",
        httpClient: httpClient
    )

    await #expect(throws: S3Error.decodingResponseFailed) {
        try await client.createMultipartUpload(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func createMultipartUpload_invalidStatusCode() async throws {
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
        try await client.createMultipartUpload(
            bucket: "bucket",
            key: "image1.jpg"
        )
    }
}

@Test
func uploadPart() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            createMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\"",
                ],
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let data = try await client.uploadPart(
        data: someData,
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        partNumber: 1
    )

    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?partNumber=1&uploadId=test-upload-id")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["Content-Type"] == "application/octet-stream")
    #expect(urlRequest.httpBody == someData)

    #expect(data.eTag == "\"e5a8627dc082f11998d9526e6bc1c542\"")
    #expect(data.partNumber == 1)
}

@Test
func uploadPart_missingETagHeader() async throws {
    let httpClient = MockS3HTTPClient { request in
        return (
            createMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:],
            )!
        )
    }

    let client = createS3Client(
        endpoint: "https://example.local",
        httpClient: httpClient
    )

    await #expect(throws: S3Error.missingResponseHeader("ETag")) {
        try await client.uploadPart(
            data: someData,
            bucket: "bucket",
            key: "image1.jpg",
            uploadId: "test-upload-id",
            partNumber: 1
        )
    }
}

@Test
func uploadPart_invalidStatusCode() async throws {
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
        try await client.uploadPart(
            data: someData,
            bucket: "bucket",
            key: "image1.jpg",
            uploadId: "test-upload-id",
            partNumber: 1
        )
    }
}

@Test
func completeMultipartUpload() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            completeMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:],
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    try await client.completeMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        parts: [
            S3ObjectPart(partNumber: 1, eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"")
        ]
    )

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploadId=test-upload-id")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["Content-Type"] == "application/xml")

    #expect(urlRequest.httpBody == (
        "<CompleteMultipartUpload>" +
        "<Part>" +
        "<PartNumber>1</PartNumber>" +
        "<ETag>&quot;e5a8627dc082f11998d9526e6bc1c542&quot;</ETag>" +
        "</Part>" +
        "</CompleteMultipartUpload>"
    ).data(using: .utf8))
}

@Test
func completeMultipartUpload_multipleParts() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            completeMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:],
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    try await client.completeMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        parts: [
            S3ObjectPart(partNumber: 2, eTag: "\"e5a8627dc082f11998d9526e6bc1c542\""),
            S3ObjectPart(partNumber: 1, eTag: "\"e5a8627dc082f11998d9526e6bc1c543\""),
            S3ObjectPart(partNumber: 3, eTag: "\"e5a8627dc082f11998d9526e6bc1c544\"")
        ]
    )

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploadId=test-upload-id")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["Content-Type"] == "application/xml")

    #expect(urlRequest.httpBody == (
        "<CompleteMultipartUpload>" +
            "<Part>" +
                "<PartNumber>1</PartNumber>" +
                "<ETag>&quot;e5a8627dc082f11998d9526e6bc1c543&quot;</ETag>" +
            "</Part>" +
            "<Part>" +
                "<PartNumber>2</PartNumber>" +
                "<ETag>&quot;e5a8627dc082f11998d9526e6bc1c542&quot;</ETag>" +
            "</Part>" +
            "<Part>" +
                "<PartNumber>3</PartNumber>" +
                "<ETag>&quot;e5a8627dc082f11998d9526e6bc1c544&quot;</ETag>" +
            "</Part>" +
        "</CompleteMultipartUpload>"
    ).data(using: .utf8))
}

@Test
func completeMultipartUpload_errorWithSuccessStatusCode() async throws {
    let httpClient = MockS3HTTPClient { request in
        return (
            someErrorData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(
        endpoint: "https://example.local",
        httpClient: httpClient
    )

    await #expect(throws: S3Error.responseError(statusCode: 200, errorData: someError)) {
        try await client.completeMultipartUpload(
            bucket: "bucket",
            key: "image1.jpg",
            uploadId: "test-upload-id",
            parts: [
                S3ObjectPart(partNumber: 1, eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"")
            ]
        )
    }
}

@Test
func completeMultipartUpload_invalidStatusCode() async throws {
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
        try await client.completeMultipartUpload(
            bucket: "bucket",
            key: "image1.jpg",
            uploadId: "test-upload-id",
            parts: [
                S3ObjectPart(partNumber: 1, eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"")
            ]
        )
    }
}

@Test
func abortMultipartUpload() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            completeMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:],
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    try await client.abortMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id"
    )

    #expect(urlRequest.httpMethod == "DELETE")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploadId=test-upload-id")
    #expect(urlRequest.allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(urlRequest.allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
}

@Test
func abortMultipartUpload_invalidStatusCode() async throws {
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
        try await client.abortMultipartUpload(
            bucket: "bucket",
            key: "image1.jpg",
            uploadId: "test-upload-id"
        )
    }
}

private let createMultipartUploadData = """
<?xml version="1.0" encoding="UTF-8"?>
<InitiateMultipartUploadResult>
    <Bucket>bucket</Bucket>
    <Key>ExampleImage.jpg</Key>
    <UploadId>test-upload-id</UploadId>
</InitiateMultipartUploadResult>
""".data(using: .utf8)!

private let completeMultipartUploadData = """
<?xml version="1.0" encoding="UTF-8"?>
<CompleteMultipartUploadResult>
    <Bucket>bucket</Bucket>
    <Key>ExampleImage.jpg</Key>
    <ETag>"e5a8627dc082f11998d9526e6bc1c542"</ETag>
</CompleteMultipartUploadResult>
""".data(using: .utf8)!
