//
//  S3ClientListObjectsTests.swift
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
func listObjects() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listObjectsData,
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

    let response = try await client.listObjects(
        bucket: "bucket"
    )

    let data = response.result

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("list-type=2") == true)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)

    #expect(data.isTruncated == false)
    #expect(data.nextContinuationToken == nil)
    #expect(data.contents.count == 2)
    #expect(data.contents[0] == S3Object(
        key: "image1.jpg",
        eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"",
        size: 7195686,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
    #expect(data.contents[1] == S3Object(
        key: "image2.jpg",
        eTag: "\"a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6\"",
        size: 1234567,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
    #expect(response.value(forHeaderField: "test-header") == "test-value")
}

@Test
func listObjects_withCustomHeaders() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listObjectsData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.listObjects(
        bucket: "bucket",
        customHeaders: [
            "x-aws-custom-header": "custom-header-value",
            "Authorization": "reserved-header",
            "Host": "reserved-header",
            "Content-Length": "reserved-header",
            "x-amz-date": "reserved-header",
            "x-amz-content-sha256": "reserved-header",
        ]
    )

    let data = response.result

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("list-type=2") == true)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256") != "reserved-header")
    #expect(urlRequest.value(forHTTPHeaderField: "x-aws-custom-header") == "custom-header-value")

    #expect(data.isTruncated == false)
    #expect(data.nextContinuationToken == nil)
    #expect(data.contents.count == 2)
    #expect(data.contents[0] == S3Object(
        key: "image1.jpg",
        eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"",
        size: 7195686,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
    #expect(data.contents[1] == S3Object(
        key: "image2.jpg",
        eTag: "\"a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6\"",
        size: 1234567,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
}

@Test
func listObjects_validResponseTrunecated() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listObjectsTrunecatedData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.listObjects(
        bucket: "bucket"
    )

    let data = response.result

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("list-type=2") == true)
    #expect(urlRequest.value(forHTTPHeaderField: "Authorization")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-date")?.isEmpty == false)
    #expect(urlRequest.value(forHTTPHeaderField: "x-amz-content-sha256")?.isEmpty == false)

    #expect(data.isTruncated == true)
    #expect(data.nextContinuationToken == "image1.jpg")
    #expect(data.contents.count == 1)
    #expect(data.contents[0] == S3Object(
        key: "image1.jpg",
        eTag: "\"e5a8627dc082f11998d9526e6bc1c542\"",
        size: 7195686,
        lastModified: iso8601DateFormatter.date(from: "2026-05-01T18:30:59.962Z")!
    ))
}

@Test
func listObjects_validResponsePrefix() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listObjectsTrunecatedData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    _ = try await client.listObjects(
        bucket: "bucket",
        prefix: "abcd"
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("list-type=2") == true)
    #expect(urlRequest.url?.absoluteString.contains("prefix=abcd") == true)
}

@Test
func listObjects_validResponseContinuationToken() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listObjectsTrunecatedData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    _ = try await client.listObjects(
        bucket: "bucket",
        continuationToken: "1234"
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("list-type=2")  == true)
    #expect(urlRequest.url?.absoluteString.contains("continuation-token=1234") == true)
}

@Test
func listObjects_validResponseMaxKeys() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listObjectsTrunecatedData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    _ = try await client.listObjects(
        bucket: "bucket",
        maxKeys: 999
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("list-type=2")  == true)
    #expect(urlRequest.url?.absoluteString.contains("max-keys=999") == true)
}

@Test
func listObjects_allOptions() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listObjectsTrunecatedData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    _ = try await client.listObjects(
        bucket: "bucket",
        prefix: "abcd",
        continuationToken: "1234",
        maxKeys: 999
    )

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("list-type=2")  == true)
    #expect(urlRequest.url?.absoluteString.contains("prefix=abcd") == true)
    #expect(urlRequest.url?.absoluteString.contains("continuation-token=1234") == true)
    #expect(urlRequest.url?.absoluteString.contains("max-keys=999") == true)
}

@Test
func listObjects_emptyList() async throws {
    nonisolated(unsafe) var urlRequest: URLRequest!

    let httpClient = MockS3HTTPClient { request in
        urlRequest = request

        return (
            listObjectsEmptyListData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
        )
    }

    let client = createS3Client(httpClient: httpClient)

    let response = try await client.listObjects(
        bucket: "bucket"
    )

    let data = response.result

    #expect(urlRequest.httpMethod == "GET")
    #expect(urlRequest.url?.absoluteString.contains("https://example.local/bucket") == true)
    #expect(urlRequest.url?.absoluteString.contains("list-type=2")  == true)

    #expect(data.isTruncated == false)
    #expect(data.nextContinuationToken == nil)
    #expect(data.contents.isEmpty)
}

@Test
func listObjects_invalidStatusCode() async throws {
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
        try await client.listObjects(
            bucket: "bucket"
        )
    }
}

@Test
func listObjects_invalidResponseMissingETAGXML() async throws {
    let httpClient = MockS3HTTPClient { request in
        return (
            listObjectsMissingETAGData,
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
        try await client.listObjects(
            bucket: "bucket"
        )
    }
}

@Test
func listObjects_invalidResponseMalformedXML() async throws {
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
        try await client.listObjects(
            bucket: "bucket"
        )
    }
}

private let listObjectsData = """
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Name>bucket</Name>
    <Prefix></Prefix>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
    <Contents>
        <Key>image1.jpg</Key>
        <ETag>&quot;e5a8627dc082f11998d9526e6bc1c542&quot;</ETag>
        <Size>7195686</Size>
        <LastModified>2026-05-01T18:30:59.962Z</LastModified>
    </Contents>
    <Contents>
        <Key>image2.jpg</Key>
        <ETag>&quot;a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6&quot;</ETag>
        <Size>1234567</Size>
        <LastModified>2026-05-01T18:30:59.962Z</LastModified>
    </Contents>
</ListBucketResult>
""".data(using: .utf8)!

private let listObjectsTrunecatedData = """
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Name>my-bucket</Name>
    <Prefix>bucket</Prefix>
    <MaxKeys>1</MaxKeys>
    <IsTruncated>true</IsTruncated>
    <Contents>
        <Key>image1.jpg</Key>
        <ETag>&quot;e5a8627dc082f11998d9526e6bc1c542&quot;</ETag>
        <Size>7195686</Size>
        <LastModified>2026-05-01T18:30:59.962Z</LastModified>
    </Contents>
    <NextContinuationToken>image1.jpg</NextContinuationToken>
</ListBucketResult>
""".data(using: .utf8)!

private let listObjectsEmptyListData = """
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Name>my-bucket</Name>
    <Prefix></Prefix>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
</ListBucketResult>
""".data(using: .utf8)!

private let listObjectsMissingETAGData = """
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Name>bucket</Name>
    <Prefix></Prefix>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
    <Contents>
        <Key>image1.jpg</Key>
        <Size>7195686</Size>
        <LastModified>2026-05-01T18:30:59.962Z</LastModified>
    </Contents>
    <Contents>
        <Key>image2.jpg</Key>
        <Size>1234567</Size>
        <LastModified>2026-05-01T18:30:59.962Z</LastModified>
    </Contents>
</ListBucketResult>
""".data(using: .utf8)!
