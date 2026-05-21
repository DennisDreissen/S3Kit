//
//  S3ClientDeleteObjectIntegrationTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 13/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func deleteObject() async throws {
    let client = createS3Client()

    let data = testData(kilobytes: 50)
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

    #expect(metadata.size == data.count)

    try await client.deleteObject(bucket: bucket, key: key)

    await #expect(throws: S3Error.responseError(statusCode: 404, errorData: nil)) {
        try await client.headObject(bucket: bucket, key: key)
    }
}

@Test
func deleteObject_withInvalidBucket() async throws {
    let client = createS3Client()

    let bucket = "non-existing-bucket"
    let key = #function

    await #expect {
        try await client.deleteObject(bucket: bucket, key: key)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData?.code == "NoSuchBucket"
    }
}
