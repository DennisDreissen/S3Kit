//
//  S3ClientListPartsIntegrationTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 16/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func listParts() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let bucket = "list-parts-bucket01"
    let key = #function

    let uploadId = try await client.createMultipartUpload(bucket: bucket, key: key).result

    for partNumber in 1...3 {
        _ = try await client.uploadPart(
            data: data,
            bucket: bucket,
            key: key,
            uploadId: uploadId,
            partNumber: partNumber
        )
    }

    let listParts = try await client.listParts(bucket: bucket, key: key, uploadId: uploadId).result

    #expect(listParts.isTruncated == false)
    #expect(listParts.nextPartNumberMarker == nil || listParts.nextPartNumberMarker == 0)
    #expect(listParts.contents.map(\.partNumber).sorted() == [1, 2, 3])
    #expect(listParts.contents.allSatisfy { !$0.eTag.isEmpty })
    #expect(listParts.contents.allSatisfy { $0.size == data.count })
    #expect(listParts.contents.allSatisfy { $0.lastModified!.timeIntervalSinceNow > -10 })

    try await client.abortMultipartUpload(bucket: bucket, key: key, uploadId: uploadId)
}

@Test
func listParts_maxKeysContinuationToken() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let bucket = "list-objects-bucket02"
    let key = #function

    let uploadId = try await client.createMultipartUpload(bucket: bucket, key: key).result

    for partNumber in 1...11 {
        _ = try await client.uploadPart(
            data: data,
            bucket: bucket,
            key: key,
            uploadId: uploadId,
            partNumber: partNumber
        )
    }

    let listParts = try await client.listParts(
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        maxParts: 5
    ).result

    #expect(listParts.isTruncated == true)
    #expect(listParts.nextPartNumberMarker != nil)
    #expect(listParts.contents.map(\.partNumber).sorted() == [1, 2, 3, 4, 5])

    let listParts2 = try await client.listParts(
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumberMarker: listParts.nextPartNumberMarker!,
        maxParts: 5
    ).result

    #expect(listParts2.isTruncated == true)
    #expect(listParts2.nextPartNumberMarker != nil)
    #expect(listParts2.contents.map(\.partNumber).sorted() == [6, 7, 8, 9, 10])

    let listParts3 = try await client.listParts(
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumberMarker: listParts2.nextPartNumberMarker!,
        maxParts: 5
    ).result

    let partNumbers3 = listParts3.contents.map(\.partNumber)

    #expect(listParts2.isTruncated == true)
    #expect(listParts2.nextPartNumberMarker != nil)
    #expect(partNumbers3 == [11])

    try await client.abortMultipartUpload(bucket: bucket, key: key, uploadId: uploadId)
}

@Test
func listParts_emptyPartsUpload() async throws {
    let client = createS3Client()

    let bucket = "list-parts-bucket03"
    let key = #function

    let uploadId = try await client.createMultipartUpload(bucket: bucket, key: key).result
    let listObjects = try await client.listParts(bucket: bucket, key: key, uploadId: uploadId).result

    #expect(listObjects.isTruncated == false)
    #expect(listObjects.nextPartNumberMarker == nil || listObjects.nextPartNumberMarker == 0)
    #expect(listObjects.contents == [])
}

@Test
func listParts_invalidUploadId() async throws {
    let client = createS3Client()

    let bucket = "list-parts-bucket03"
    let key = #function
    let uploadId = "non-upload-id"

    await #expect {
        _ = try await client.listParts(bucket: bucket, key: key, uploadId: uploadId)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData?.code == "NoSuchUpload"
    }
}
