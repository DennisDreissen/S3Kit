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

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
                headerFields: [
                    "test-header": "test-value"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.createMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg"
    )

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploads=")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)

    #expect(response.result == "test-upload-id")
    #expect(response.value(forHeaderField: "test-header") == "test-value")
}

@Test
func createMultipartUpload_withCustomHeaders() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            createMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let uploadId = try await client.createMultipartUpload(
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
    ).result

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploads=")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-aws-custom-header") == "custom-header-value")

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
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let uploadId = try await client.createMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg",
        contentType: "some/content-type"
    ).result

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploads=")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "some/content-type")

    #expect(uploadId == "test-upload-id")
}

@Test
func createMultipartUpload_returnsInvalidResponseMalformedXML() async throws {
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
func createMultipartUpload_returnsInvalidStatusCode() async throws {
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
                    "test-header": "test-value"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.uploadPart(
        data: someData,
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        partNumber: 1
    )

    let data = response.result

    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?partNumber=1&uploadId=test-upload-id")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/octet-stream")
    
    #expect(httpClient.capturedBody == someData)

    #expect(data.eTag == "\"e5a8627dc082f11998d9526e6bc1c542\"")
    #expect(data.partNumber == 1)
    #expect(response.value(forHeaderField: "test-header") == "test-value")
}

@Test
func uploadPart_withCustomHeaders() async throws {
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
                    "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\""
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.uploadPart(
        data: someData,
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        partNumber: 1,
        customHeaders: [
            "x-aws-custom-header": "custom-header-value",
            "Authorization": "reserved-header",
            "Host": "reserved-header",
            "Content-Length": "reserved-header",
            "x-amz-date": "reserved-header",
            "x-amz-content-sha256": "reserved-header",
            "Content-Type": "custom/content-type"
        ]
    )

    let data = response.result

    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?partNumber=1&uploadId=test-upload-id")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-aws-custom-header") == "custom-header-value")
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "custom/content-type")

    #expect(httpClient.capturedBody == someData)

    #expect(data.eTag == "\"e5a8627dc082f11998d9526e6bc1c542\"")
    #expect(data.partNumber == 1)
}

@Test
func uploadPart_withProgressHandler() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!
    nonisolated(unsafe) var progressHandlerCalls: [Double] = []

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            createMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\""
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.uploadPart(
        data: someData,
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        partNumber: 1
    ) { progress in
        progressHandlerCalls.append(progress)
    }

    let data = response.result
    
    #expect(urlRequest.httpMethod == "PUT")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?partNumber=1&uploadId=test-upload-id")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/octet-stream")

    #expect(httpClient.capturedBody == someData)

    #expect(data.eTag == "\"e5a8627dc082f11998d9526e6bc1c542\"")
    #expect(data.partNumber == 1)

    #expect(progressHandlerCalls.first ?? .infinity < 1.0)
    #expect(progressHandlerCalls.last == 1.0)
}

@Test
func uploadPart_returnsWithoutETagHeader() async throws {
    let httpClient = MockS3HTTPClient { request in
        return (
            createMultipartUploadData,
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
func uploadPart_returnsInvalidStatusCode() async throws {
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
                headerFields: [
                    "test-header": "test-value"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.completeMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        parts: [
            S3ObjectPart(partNumber: 1, eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"")
        ]
    )

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploadId=test-upload-id")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/xml")

    #expect(urlRequest.httpBody == (
        "<CompleteMultipartUpload>" +
        "<Part>" +
        "<PartNumber>1</PartNumber>" +
        "<ETag>&quot;e5a8627dc082f11998d9526e6bc1c542&quot;</ETag>" +
        "</Part>" +
        "</CompleteMultipartUpload>"
    ).data(using: .utf8))

    #expect(response.value(forHeaderField: "test-header") == "test-value")
}

@Test
func completeMultipartUpload_withCustomHeaders() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            completeMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
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
        ],
        customHeaders: [
            "x-aws-custom-header": "custom-header-value",
            "Authorization": "reserved-header",
            "Host": "reserved-header",
            "Content-Length": "reserved-header",
            "x-amz-date": "reserved-header",
            "x-amz-content-sha256": "reserved-header",
            "Content-Type": "custom/content-type"
        ]
    )

    #expect(urlRequest.httpMethod == "POST")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploadId=test-upload-id")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "custom/content-type")
    #expect(urlRequest.value(forHTTPHeaderField: "x-aws-custom-header") == "custom-header-value")

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
func completeMultipartUpload_withMultipleParts() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            completeMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
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
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/xml")

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
func completeMultipartUpload_returnsErrorWithSuccessStatusCode() async throws {
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
func completeMultipartUpload_returnsInvalidStatusCode() async throws {
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
                headerFields: [
                    "test-header": "test-value"
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.abortMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id"
    )

    #expect(urlRequest.httpMethod == "DELETE")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploadId=test-upload-id")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)

    #expect(response.value(forHeaderField: "test-header") == "test-value")
}

@Test
func abortMultipartUpload_withCustomHeaders() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            completeMultipartUploadData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    try await client.abortMultipartUpload(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        customHeaders: [
            "x-aws-custom-header": "custom-header-value",
            "Authorization": "reserved-header",
            "Host": "reserved-header",
            "Content-Length": "reserved-header",
            "x-amz-date": "reserved-header",
            "x-amz-content-sha256": "reserved-header"
        ]
    )

    #expect(urlRequest.httpMethod == "DELETE")
    #expect(urlRequest.url?.absoluteString == "https://example.local/bucket/image1.jpg?uploadId=test-upload-id")
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-aws-custom-header") == "custom-header-value")
}

@Test
func abortMultipartUpload_returnsInvalidStatusCode() async throws {
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
