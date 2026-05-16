//
//  S3ClientPutObjectIntegrationTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func putObject() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let bucket = "bucket01"
    let key = #function
    let contentType = "application/pdf"

    try await client.putObject(
        data: data,
        bucket: bucket,
        key: key,
        contentType: contentType
    )

    let metadata = try await client.headObject(bucket: bucket, key: key)

    #expect(metadata.eTag.isEmpty == false)
    #expect(metadata.size == data.count)
    #expect(metadata.lastModified.timeIntervalSinceNow > -10)
    #expect(metadata.contentType == contentType)

    try await client.deleteObject(bucket: bucket, key: key)
}

@Test
func putObject_withProgressHandler() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 10)
    let bucket = "bucket01"
    let key = #function
    let contentType = "application/pdf"

    nonisolated(unsafe) var progressHandlerCalls: [Double] = []

    try await client.putObject(
        data: data,
        bucket: bucket,
        key: key,
        contentType: contentType
    ) { progress in
        progressHandlerCalls.append(progress)
    }

    let metadata = try await client.headObject(bucket: bucket, key: key)

    #expect(metadata.eTag.isEmpty == false)
    #expect(metadata.size == data.count)
    #expect(metadata.lastModified.timeIntervalSinceNow > -10)
    #expect(metadata.contentType == contentType)

    #expect(progressHandlerCalls.isEmpty == false)
    #expect(progressHandlerCalls.last == 1.0)
    #expect(progressHandlerCalls.allSatisfy { $0 >= 0.0 && $0 <= 1.0 })

    try await client.deleteObject(bucket: bucket, key: key)
}

@Test
func putObject_withoutContentType() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let bucket = "bucket01"
    let key = #function

    try await client.putObject(
        data: data,
        bucket: bucket,
        key: key
    )

    let metadata = try await client.headObject(bucket: bucket, key: key)

    #expect(metadata.eTag.isEmpty == false)
    #expect(metadata.size == data.count)
    #expect(metadata.lastModified.timeIntervalSinceNow > -10)
    #expect(metadata.contentType == "binary/octet-stream")

    try await client.deleteObject(bucket: bucket, key: key)
}

@Test
func putObject_invalidBucket() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let bucket = "non-existing-bucket"
    let key = #function

    await #expect {
        try await client.putObject(data: data, bucket: bucket, key: key)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData?.code == "NoSuchBucket"
    }
}
