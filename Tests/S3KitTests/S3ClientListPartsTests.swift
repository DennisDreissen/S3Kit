//
//  S3ClientListPartsTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 16/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Test
func listParts() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listPartsData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "test-header": "test-value",
                ]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let data = try await client.listParts(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id"
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)

    #expect(data.isTruncated == false)
    #expect(data.nextPartNumberMarker == nil || data.nextPartNumberMarker == 0)
    #expect(data.contents.count == 2)
    #expect(data.contents[0] == S3ObjectPart(
        partNumber: 1,
        eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"",
        size: 7195686,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
    #expect(data.contents[1] == S3ObjectPart(
        partNumber: 2,
        eTag: "\"a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6\"",
        size: 1234567,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
    #expect(data.value(forHeaderField: "test-header") == "test-value")
}

@Test
func listParts_withCustomHeaders() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listPartsData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let data = try await client.listParts(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        customHeaders: [
            "x-aws-custom-header": "custom-header-value",
            "Authorization": "reserved-header",
            "Host": "reserved-header",
            "Content-Length": "reserved-header",
            "x-amz-date": "reserved-header",
            "x-amz-content-sha256": "reserved-header",
        ]
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-aws-custom-header") == "custom-header-value")

    #expect(data.isTruncated == false)
    #expect(data.nextPartNumberMarker == nil || data.nextPartNumberMarker == 0)
    #expect(data.contents.count == 2)
    #expect(data.contents[0] == S3ObjectPart(
        partNumber: 1,
        eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"",
        size: 7195686,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
    #expect(data.contents[1] == S3ObjectPart(
        partNumber: 2,
        eTag: "\"a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6\"",
        size: 1234567,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
}

@Test
func listParts_validResponseTrunecated() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listPartsTruncatedData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let data = try await client.listParts(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id"
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)

    #expect(data.isTruncated == true)
    #expect(data.nextPartNumberMarker == 1)
    #expect(data.contents.count == 1)
    #expect(data.contents[0] == S3ObjectPart(
        partNumber: 1,
        eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"",
        size: 7195686,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
}

@Test
func listParts_validResponseContinuationToken() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listPartsTruncatedData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    _ = try await client.listParts(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        partNumberMarker: 1234
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(urlRequest.url?.absoluteString.contains("part-number-marker=1234") == true)
}

@Test
func listParts_validResponseMaxKeys() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listPartsTruncatedData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    _ = try await client.listParts(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        maxParts: 999
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(urlRequest.url?.absoluteString.contains("max-parts=999") == true)
}

@Test
func listParts_allOptions() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listPartsTruncatedData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    _ = try await client.listParts(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id",
        partNumberMarker: 1234,
        maxParts: 999
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("uploadId=test-upload-id") == true)
    #expect(urlRequest.url?.absoluteString.contains("part-number-marker=1234") == true)
    #expect(urlRequest.url?.absoluteString.contains("max-parts=999") == true)
}

@Test
func listParts_emptyList() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listPartsEmptyListData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let data = try await client.listParts(
        bucket: "bucket",
        key: "image1.jpg",
        uploadId: "test-upload-id"
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("uploadId=test-upload-id") == true)

    #expect(data.isTruncated == false)
    #expect(data.nextPartNumberMarker == nil)
    #expect(data.contents.isEmpty)
}

@Test
func listParts_invalidStatusCode() async throws {
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
        try await client.listParts(
            bucket: "bucket",
            key: "image1.jpg",
            uploadId: "test-upload-id"
        )
    }
}

@Test
func listParts_invalidResponseMissingETAGXML() async throws {
    let httpClient = MockS3HTTPClient { request in
        return (
            listPartsMissingETAGData,
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
        try await client.listParts(
            bucket: "bucket",
            key: "image1.jpg",
            uploadId: "test-upload-id"
        )
    }
}

@Test
func listParts_invalidResponseMalformedXML() async throws {
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
        try await client.listParts(
            bucket: "bucket",
            key: "image1.jpg",
            uploadId: "test-upload-id"
        )
    }
}

private let listPartsData = """
<?xml version="1.0" encoding="UTF-8"?>
<ListPartsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Bucket>bucket</Bucket>
    <Key>large-file.zip</Key>
    <UploadId>VXBsb2FkIElEIGZvciA2aWWpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZA</UploadId>
    <PartNumberMarker>0</PartNumberMarker>
    <NextPartNumberMarker>0</NextPartNumberMarker>
    <MaxParts>1000</MaxParts>
    <IsTruncated>false</IsTruncated>
    <Part>
        <PartNumber>1</PartNumber>
        <ETag>&quot;e5a8627dc082f11998d9526e6bc1c542&quot;</ETag>
        <Size>7195686</Size>
        <LastModified>2026-05-01T18:30:59.962Z</LastModified>
    </Part>
    <Part>
        <PartNumber>2</PartNumber>
        <ETag>&quot;a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6&quot;</ETag>
        <Size>1234567</Size>
        <LastModified>2026-05-01T18:30:59.962Z</LastModified>
    </Part>
</ListPartsResult>
""".data(using: .utf8)!

private let listPartsTruncatedData = """
<?xml version="1.0" encoding="UTF-8"?>
<ListPartsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Bucket>my-bucket</Bucket>
    <Key>large-file.zip</Key>
    <UploadId>VXBsb2FkIElEIGZvciA2aWWpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZA</UploadId>
    <PartNumberMarker>0</PartNumberMarker>
    <NextPartNumberMarker>1</NextPartNumberMarker>
    <MaxParts>1</MaxParts>
    <IsTruncated>true</IsTruncated>
    <Part>
        <PartNumber>1</PartNumber>
        <ETag>&quot;e5a8627dc082f11998d9526e6bc1c542&quot;</ETag>
        <Size>7195686</Size>
        <LastModified>2026-05-01T18:30:59.962Z</LastModified>
    </Part>
</ListPartsResult>
""".data(using: .utf8)!

private let listPartsEmptyListData = """
<?xml version="1.0" encoding="UTF-8"?>
<ListPartsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Bucket>my-bucket</Bucket>
    <Key>large-file.zip</Key>
    <UploadId>VXBsb2FkIElEIGZvciA2aWWpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZA</UploadId>
    <PartNumberMarker>0</PartNumberMarker>
    <MaxParts>1000</MaxParts>
    <IsTruncated>false</IsTruncated>
</ListPartsResult>
""".data(using: .utf8)!

private let listPartsMissingETAGData = """
<?xml version="1.0" encoding="UTF-8"?>
<ListPartsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Bucket>bucket</Bucket>
    <Key>large-file.zip</Key>
    <UploadId>VXBsb2FkIElEIGZvciA2aWWpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZA</UploadId>
    <PartNumberMarker>0</PartNumberMarker>
    <MaxParts>1000</MaxParts>
    <IsTruncated>false</IsTruncated>
    <Part>
        <PartNumber>1</PartNumber>
        <Size>7195686</Size>
        <LastModified>2026-05-01T18:30:59.962Z</LastModified>
    </Part>
    <Part>
        <PartNumber>2</PartNumber>
        <Size>1234567</Size>
""".data(using: .utf8)!
