//
//  S3ClientDownloadObjectIntegrationTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 21/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func downloadObject() async throws {
    let client = createS3Client()

    let data = testData(kilobytes: 50)
    let bucket = "bucket01"
    let key = #function

    try await client.putObject(
        data: data,
        bucket: bucket,
        key: key
    )

    let objectData = try await client.downloadObject(bucket: bucket, key: key)

    #expect(try Data(contentsOf: objectData.result) == data)

    try await client.deleteObject(bucket: bucket, key: key)
}

@Test
func downloadObject_withInvalidKey() async throws {
    let client = createS3Client()

    let bucket = "bucket01"
    let key = "non-existing-key"

    await #expect {
        _ = try await client.downloadObject(bucket: bucket, key: key)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData == nil
    }
}

@Test
func downloadObject_withInvalidBucket() async throws {
    let client = createS3Client()

    let bucket = "non-existing-bucket"
    let key = #function

    await #expect {
        _ = try await client.downloadObject(bucket: bucket, key: key)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData == nil
    }
}
