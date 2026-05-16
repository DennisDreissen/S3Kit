//
//  S3ClientCopyObjectIntegrationTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func copyObject() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let sourceBucket = "bucket01"
    let destinationBucket = "bucket02"
    let key = #function
    let contentType = "application/pdf"

    try await client.putObject(
        data: data,
        bucket: sourceBucket,
        key: key,
        contentType: contentType
    )

    let sourceMetadata = try await client.headObject(bucket: sourceBucket, key: key).result

    await #expect(throws: S3Error.responseError(statusCode: 404, errorData: nil)) {
        try await client.headObject(bucket: destinationBucket, key: key)
    }

    #expect(sourceMetadata.eTag.isEmpty == false)
    #expect(sourceMetadata.size == data.count)
    #expect(sourceMetadata.lastModified.timeIntervalSinceNow > -10)
    #expect(sourceMetadata.contentType == contentType)

    try await client.copyObject(
        sourceBucket: sourceBucket,
        sourceKey: key,
        bucket: destinationBucket,
        key: key
    )

    let destinationMetadata = try await client.headObject(bucket: destinationBucket, key: key).result

    #expect(destinationMetadata.eTag.isEmpty == false)
    #expect(destinationMetadata.size == data.count)
    #expect(destinationMetadata.lastModified.timeIntervalSinceNow > -10)
    #expect(destinationMetadata.contentType == contentType)

    try await client.deleteObject(bucket: sourceBucket, key: key)
    try await client.deleteObject(bucket: destinationBucket, key: key)
}

@Test
func copyObject_withKeyWithSpaces() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let sourceBucket = "bucket01"
    let destinationBucket = "bucket02"
    let key = "some \(#function)"
    let contentType = "application/pdf"

    try await client.putObject(
        data: data,
        bucket: sourceBucket,
        key: key,
        contentType: contentType
    )

    let sourceMetadata = try await client.headObject(bucket: sourceBucket, key: key).result

    await #expect(throws: S3Error.responseError(statusCode: 404, errorData: nil)) {
        try await client.headObject(bucket: destinationBucket, key: key)
    }

    #expect(sourceMetadata.eTag.isEmpty == false)
    #expect(sourceMetadata.size == data.count)
    #expect(sourceMetadata.lastModified.timeIntervalSinceNow > -10)
    #expect(sourceMetadata.contentType == contentType)

    try await client.copyObject(
        sourceBucket: sourceBucket,
        sourceKey: key,
        bucket: destinationBucket,
        key: key
    )

    let destinationMetadata = try await client.headObject(bucket: destinationBucket, key: key).result

    #expect(destinationMetadata.eTag.isEmpty == false)
    #expect(destinationMetadata.size == data.count)
    #expect(destinationMetadata.lastModified.timeIntervalSinceNow > -10)
    #expect(destinationMetadata.contentType == contentType)

    try await client.deleteObject(bucket: sourceBucket, key: key)
    try await client.deleteObject(bucket: destinationBucket, key: key)
}

@Test
func copyObject_invalidKey() async throws {
    let client = createS3Client()

    let bucket = "bucket01"
    let key = #function

    await #expect {
        try await client.copyObject(sourceBucket: bucket, sourceKey: key, bucket: bucket, key: key)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData?.code == "NoSuchKey"
    }
}

@Test
func copyObject_invalidBucket() async throws {
    let client = createS3Client()

    let bucket = "non-existing-bucket"
    let key = #function

    await #expect {
        try await client.copyObject(sourceBucket: bucket, sourceKey: key, bucket: bucket, key: key)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData?.code == "NoSuchBucket"
    }
}
