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
func putObjectMultipart_validResponseOneChunk() async throws {
    nonisolated(unsafe) var requestCount = 0
    nonisolated(unsafe) var capturedRequests: [URLRequest] = []

    let httpClient = MockHTTPClient { request in
        capturedRequests.append(request)
        requestCount += 1

        let query = request.url?.query ?? ""

        if query.contains("uploads") {
            // Start
            return (
                initiateResponse,
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            )
        } else if query.contains("partNumber") {
            // Upload part
            return (
                Data(),
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: [
                        "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\""
                    ]
                )!
            )
        } else if query.contains("uploadId") {
            // Complete
            return (
                completeResponse,
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            )
        } else {
            // Abort
            Issue.record("Abort should not have been called")
            throw URLError(.unknown)
        }
    }

    let client = createS3Client(httpClient: httpClient)

    let imageData = Data(repeating: 0, count: 2 * 1024 * 1024)
    let stream = AsyncThrowingStream<Data, Error> { continuation in
        continuation.yield(imageData)
        continuation.finish()
    }

    nonisolated(unsafe) var progressValues: [Int] = []

    try await client.putObjectMultipart(
        stream: stream,
        bucket: "bucket",
        key: "image1.jpg",
        contentType: "image/jpeg"
    ) { progress in
        progressValues.append(progress)
    }

    #expect(capturedRequests.count == 3)
    #expect(progressValues.count == 1)
    #expect(progressValues.last == 2 * 1024 * 1024)

    // Start multipart upload
    #expect(capturedRequests[0].httpMethod == "POST")
    #expect(capturedRequests[0].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[0].url?.absoluteString.contains("uploads") == true)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Content-Type"] == "image/jpeg")

    var totalChunksSize = 0

    // Upload chuck 1/1
    #expect(capturedRequests[1].httpMethod == "PUT")
    #expect(capturedRequests[1].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("partNumber=1") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Content-Type"] == "application/octet-stream")
    totalChunksSize += Int(capturedRequests[1].allHTTPHeaderFields?["Content-Length"] ?? "0") ?? 0

    #expect(totalChunksSize == 2 * 1024 * 1024)

    // Complete upload
    #expect(capturedRequests[2].httpMethod == "POST")
    #expect(capturedRequests[2].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[2].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[2].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["Content-Type"] == "application/xml")
}

@Test
func putObjectMultipart_validResponseThreeChunks() async throws {
    nonisolated(unsafe) var requestCount = 0
    nonisolated(unsafe) var capturedRequests: [URLRequest] = []

    let httpClient = MockHTTPClient { request in
        capturedRequests.append(request)
        requestCount += 1

        let query = request.url?.query ?? ""

        if query.contains("uploads") {
            // Start
            return (
                initiateResponse,
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            )
        } else if query.contains("partNumber") {
            // Upload part
            return (
                Data(),
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: [
                        "ETag": "\"e5a8627dc082f11998d9526e6bc1c542\""
                    ]
                )!
            )
        } else if query.contains("uploadId") {
            // Complete
            return (
                completeResponse,
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            )
        } else {
            // Abort
            Issue.record("Abort should not have been called")
            throw URLError(.unknown)
        }
    }

    let client = createS3Client(httpClient: httpClient)

    let imageData = Data(repeating: 0, count: 12 * 1024 * 1024)
    let stream = AsyncThrowingStream<Data, Error> { continuation in
        continuation.yield(imageData)
        continuation.finish()
    }

    nonisolated(unsafe) var progressValues: [Int] = []

    try await client.putObjectMultipart(
        stream: stream,
        bucket: "bucket",
        key: "image1.jpg",
        contentType: "image/jpeg"
    ) { progress in
        progressValues.append(progress)
    }

    #expect(capturedRequests.count == 5)
    #expect(progressValues.count == 3)
    #expect(progressValues.last == 12 * 1024 * 1024)

    // Start multipart upload
    #expect(capturedRequests[0].httpMethod == "POST")
    #expect(capturedRequests[0].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[0].url?.absoluteString.contains("uploads") == true)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Content-Type"] == "image/jpeg")

    var totalChunksSize = 0

    // Upload chuck 1/3
    #expect(capturedRequests[1].httpMethod == "PUT")
    #expect(capturedRequests[1].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("partNumber=1") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Content-Type"] == "application/octet-stream")
    totalChunksSize += Int(capturedRequests[1].allHTTPHeaderFields?["Content-Length"] ?? "0") ?? 0

    // Upload chuck 2/3
    #expect(capturedRequests[2].httpMethod == "PUT")
    #expect(capturedRequests[2].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[2].url?.absoluteString.contains("partNumber=2") == true)
    #expect(capturedRequests[2].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[2].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["Content-Type"] == "application/octet-stream")
    totalChunksSize += Int(capturedRequests[2].allHTTPHeaderFields?["Content-Length"] ?? "0") ?? 0

    // Upload chuck 3/3
    #expect(capturedRequests[3].httpMethod == "PUT")
    #expect(capturedRequests[3].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[3].url?.absoluteString.contains("partNumber=3") == true)
    #expect(capturedRequests[3].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[3].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[3].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[3].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[3].allHTTPHeaderFields?["Content-Type"] == "application/octet-stream")
    totalChunksSize += Int(capturedRequests[3].allHTTPHeaderFields?["Content-Length"] ?? "0") ?? 0

    #expect(totalChunksSize == 12 * 1024 * 1024)

    // Complete upload
    #expect(capturedRequests[4].httpMethod == "POST")
    #expect(capturedRequests[4].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[4].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[4].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[4].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[4].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[4].allHTTPHeaderFields?["Content-Type"] == "application/xml")
}

@Test
func putObjectMultipart_abortsOnPartUploadError() async throws {
    nonisolated(unsafe) var capturedRequests: [URLRequest] = []

    let httpClient = MockHTTPClient { request in
        capturedRequests.append(request)

        let query = request.url?.query ?? ""

        if query.contains("uploads") {
            return (
                initiateResponse,
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            )
        } else if query.contains("partNumber") {
            return (
                someErrorData,
                HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            )
        } else {
            // Abort
            return (
                Data(),
                HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            )
        }
    }

    let client = createS3Client(httpClient: httpClient)

    let imageData = Data(repeating: 0, count: 12 * 1024 * 1024)
    let stream = AsyncThrowingStream<Data, Error> { continuation in
        continuation.yield(imageData)
        continuation.finish()
    }

    await #expect(throws: S3Error.errorResponse(statusCode: 500, body: someErrorData)) {
        try await client.putObjectMultipart(
            stream: stream,
            bucket: "bucket",
            key: "image1.jpg",
            contentType: "image/jpeg"
        )
    }

    #expect(capturedRequests.count == 3)

    // Start multipart upload
    #expect(capturedRequests[0].httpMethod == "POST")
    #expect(capturedRequests[0].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[0].url?.absoluteString.contains("uploads") == true)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Content-Type"] == "image/jpeg")

    // Upload chuck 1/1
    #expect(capturedRequests[1].httpMethod == "PUT")
    #expect(capturedRequests[1].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("partNumber=1") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Content-Type"] == "application/octet-stream")

    // Abort upload
    #expect(capturedRequests[2].httpMethod == "DELETE")
    #expect(capturedRequests[2].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[2].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[2].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
}

@Test
func putObjectMultipart_abortsOnCompleteError() async throws {
    nonisolated(unsafe) var capturedRequests: [URLRequest] = []

    let httpClient = MockHTTPClient { request in
        capturedRequests.append(request)

        let query = request.url?.query ?? ""

        if query.contains("uploads") {
            return (
                initiateResponse,
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            )
        } else if query.contains("partNumber") {
            return (
                Data(),
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["ETag": "\"e5a8627dc082f11998d9526e6bc1c542\""]
                )!
            )
        } else if request.httpMethod == "POST" {
            // Complete
            return (
                someErrorData,
                HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            )
        } else {
            // Abort
            return (
                Data(),
                HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            )
        }
    }

    let client = createS3Client(httpClient: httpClient)

    let imageData = Data(repeating: 0, count: 2 * 1024 * 1024)
    let stream = AsyncThrowingStream<Data, Error> { continuation in
        continuation.yield(imageData)
        continuation.finish()
    }

    await #expect(throws: S3Error.errorResponse(statusCode: 500, body: someErrorData)) {
        try await client.putObjectMultipart(
            stream: stream,
            bucket: "bucket",
            key: "image1.jpg",
            contentType: "image/jpeg"
        )
    }

    #expect(capturedRequests.count == 4)

    // Start multipart upload
    #expect(capturedRequests[0].httpMethod == "POST")
    #expect(capturedRequests[0].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[0].url?.absoluteString.contains("uploads") == true)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Content-Type"] == "image/jpeg")

    // Upload chuck 1/1
    #expect(capturedRequests[1].httpMethod == "PUT")
    #expect(capturedRequests[1].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("partNumber=1") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Content-Type"] == "application/octet-stream")

    // Complete upload
    #expect(capturedRequests[2].httpMethod == "POST")
    #expect(capturedRequests[2].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[2].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[2].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)

    // Abort upload
    #expect(capturedRequests[3].httpMethod == "DELETE")
    #expect(capturedRequests[3].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[3].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[3].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[3].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[3].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
}

@Test
func putObjectMultipart_abortsOnMissingETAGInPartUpload() async throws {
    nonisolated(unsafe) var capturedRequests: [URLRequest] = []

    let httpClient = MockHTTPClient { request in
        capturedRequests.append(request)

        let query = request.url?.query ?? ""

        if query.contains("uploads") {
            return (
                initiateResponse,
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            )
        } else if query.contains("partNumber") {
            return (
                Data(),
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: [:]
                )!
            )
        } else if request.httpMethod == "POST" {
            // Complete
            Issue.record("Complete should not have been called")
            throw URLError(.unknown)
        } else {
            // Abort
            return (
                Data(),
                HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
            )
        }
    }

    let client = createS3Client(httpClient: httpClient)

    let imageData = Data(repeating: 0, count: 2 * 1024 * 1024)
    let stream = AsyncThrowingStream<Data, Error> { continuation in
        continuation.yield(imageData)
        continuation.finish()
    }

    await #expect(throws: S3Error.missingHeader("ETag")) {
        try await client.putObjectMultipart(
            stream: stream,
            bucket: "bucket",
            key: "image1.jpg",
            contentType: "image/jpeg"
        )
    }

    #expect(capturedRequests.count == 3)

    // Start multipart upload
    #expect(capturedRequests[0].httpMethod == "POST")
    #expect(capturedRequests[0].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[0].url?.absoluteString.contains("uploads") == true)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[0].allHTTPHeaderFields?["Content-Type"] == "image/jpeg")

    // Upload chuck 1/1
    #expect(capturedRequests[1].httpMethod == "PUT")
    #expect(capturedRequests[1].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("partNumber=1") == true)
    #expect(capturedRequests[1].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
    #expect(capturedRequests[1].allHTTPHeaderFields?["Content-Type"] == "application/octet-stream")

    // Abort upload
    #expect(capturedRequests[2].httpMethod == "DELETE")
    #expect(capturedRequests[2].url?.absoluteString.contains("https://example.local/bucket/image1.jpg") == true)
    #expect(capturedRequests[2].url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(capturedRequests[2].allHTTPHeaderFields?["Authorization"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-date"]?.isEmpty == false)
    #expect(capturedRequests[2].allHTTPHeaderFields?["x-amz-content-sha256"]?.isEmpty == false)
}

private let initiateResponse = """
<?xml version="1.0" encoding="UTF-8"?>
<InitiateMultipartUploadResult>
    <Bucket>bucket</Bucket>
    <Key>ExampleImage.jpg</Key>
    <UploadId>test-upload-id</UploadId>
</InitiateMultipartUploadResult>
""".data(using: .utf8)!

private let completeResponse = """
<?xml version="1.0" encoding="UTF-8"?>
<CompleteMultipartUploadResult>
    <Bucket>bucket</Bucket>
    <Key>ExampleImage.jpg</Key>
    <ETag>"e5a8627dc082f11998d9526e6bc1c542"</ETag>
</CompleteMultipartUploadResult>
""".data(using: .utf8)!
