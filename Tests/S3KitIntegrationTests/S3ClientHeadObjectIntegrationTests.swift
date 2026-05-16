//
//  S3ClientHeadObjectIntegrationTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 13/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func headObject() async throws {
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

    let metadata = try await client.headObject(bucket: bucket, key: key).result

    #expect(metadata.eTag.isEmpty == false)
    #expect(metadata.size == data.count)
    #expect(metadata.lastModified.timeIntervalSinceNow > -10)
    #expect(metadata.contentType == contentType)

    try await client.deleteObject(bucket: bucket, key: key)
}

@Test
func headObject_invalidKey() async throws {
    let client = createS3Client()

    let bucket = "bucket01"
    let key = "non-existing-key"

    await #expect(throws: S3Error.responseError(statusCode: 404, errorData: nil)) {
        try await client.headObject(bucket: bucket, key: key)
    }
}

@Test
func headObject_invalidBucket() async throws {
    let client = createS3Client()

    let bucket = "non-existing-bucket"
    let key = #function

    await #expect(throws: S3Error.responseError(statusCode: 404, errorData: nil)) {
        try await client.headObject(bucket: bucket, key: key)
    }
}
