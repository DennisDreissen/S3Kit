//
//  S3ClientPutObjectMultipartIntegrationTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func createMultipartUpload() async throws {
    let client = createS3Client()

    let bucket = "bucket01"
    let key = #function

    let uploadId = try await client.createMultipartUpload(bucket: bucket, key: key).result

    #expect(uploadId.isEmpty == false)

    try await client.abortMultipartUpload(bucket: bucket, key: key, uploadId: uploadId)
}

@Test
func createMultipartUpload_invalidBucket() async throws {
    let client = createS3Client()

    let bucket = "non-existing-bucket"
    let key = #function

    await #expect {
        try await client.createMultipartUpload(bucket: bucket, key: key)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData?.code == "NoSuchBucket"
    }
}

@Test
func uploadPart() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 12)
    let bucket = "bucket01"
    let key = #function
    let chunkSize = 5 * 1024 * 1024

    let uploadId = try await client.createMultipartUpload(bucket: bucket, key: key).result

    let part1 = try await client.uploadPart(
        data: data.prefix(chunkSize),
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 1
    ).result

    #expect(part1.partNumber == 1)

    let part2 = try await client.uploadPart(
        data: data.dropFirst(chunkSize).prefix(chunkSize),
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 2
    ).result

    #expect(part2.partNumber == 2)

    let part3 = try await client.uploadPart(
        data: data.dropFirst(2 * chunkSize),
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 3
    ).result

    #expect(part3.partNumber == 3)

    try await client.completeMultipartUpload(
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        parts: [
            part1,
            part2,
            part3
        ]
    ).result

    let objectData = try await client.getObject(bucket: bucket, key: key).result

    #expect(objectData == data)

    try await client.deleteObject(bucket: bucket, key: key)
}

@Test
func uploadPart_withProgressHandler() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 10)
    let bucket = "bucket01"
    let key = #function

    nonisolated(unsafe) var progressHandlerCalls: [Double] = []

    let uploadId = try await client.createMultipartUpload(bucket: bucket, key: key).result

    let part = try await client.uploadPart(
        data: data,
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 1
    ) { progress in
        progressHandlerCalls.append(progress)
    }.result

    #expect(part.partNumber == 1)

    try await client.completeMultipartUpload(
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        parts: [part]
    )

    let objectData = try await client.getObject(bucket: bucket, key: key).result

    #expect(objectData == data)

    #expect(progressHandlerCalls.isEmpty == false)
    #expect(progressHandlerCalls.last == 1.0)
    #expect(progressHandlerCalls.allSatisfy { $0 >= 0.0 && $0 <= 1.0 })

    try await client.deleteObject(bucket: bucket, key: key)
}

@Test
func uploadPart_successWithContentType() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 12)
    let bucket = "bucket01"
    let key = #function
    let chunkSize = 5 * 1024 * 1024
    let contentType = "application/pdf"

    let uploadId = try await client.createMultipartUpload(
        bucket: bucket,
        key: key,
        contentType: contentType
    ).result

    let part1 = try await client.uploadPart(
        data: data.prefix(chunkSize),
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 1
    ).result

    #expect(part1.partNumber == 1)

    let part2 = try await client.uploadPart(
        data: data.dropFirst(chunkSize).prefix(chunkSize),
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 2
    ).result

    #expect(part2.partNumber == 2)

    let part3 = try await client.uploadPart(
        data: data.dropFirst(2 * chunkSize),
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 3
    ).result

    #expect(part3.partNumber == 3)

    try await client.completeMultipartUpload(
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        parts: [
            part1,
            part2,
            part3
        ]
    )

    let objectData = try await client.getObject(bucket: bucket, key: key).result

    #expect(objectData == data)

    let metadata = try await client.headObject(bucket: bucket, key: key).result

    #expect(metadata.eTag.isEmpty == false)
    #expect(metadata.size == data.count)
    #expect(metadata.lastModified.timeIntervalSinceNow > -10)
    #expect(metadata.contentType == contentType)

    try await client.deleteObject(bucket: bucket, key: key)
}

@Test
func uploadPart_abort() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 12)
    let bucket = "bucket01"
    let key = #function
    let chunkSize = 5 * 1024 * 1024

    let uploadId = try await client.createMultipartUpload(bucket: bucket, key: key).result

    let part1 = try await client.uploadPart(
        data: data.prefix(chunkSize),
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 1
    ).result

    #expect(part1.partNumber == 1)

    let part2 = try await client.uploadPart(
        data: data.dropFirst(chunkSize).prefix(chunkSize),
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 2
    ).result

    #expect(part2.partNumber == 2)

    let part3 = try await client.uploadPart(
        data: data.dropFirst(2 * chunkSize),
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: 3
    ).result

    #expect(part3.partNumber == 3)

    try await client.abortMultipartUpload(
        bucket: bucket,
        key: key,
        uploadId: uploadId
    ).result

    await #expect {
        _ = try await client.getObject(bucket: bucket, key: key)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData?.code == "NoSuchKey"
    }
}
