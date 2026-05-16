//
//  S3ClientListObjectsIntegrationTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func listObjects() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let bucket = "list-objects-bucket01"
    let keys = ["\(#function)01", "\(#function)02"]

    for key in keys {
        try await client.putObject(
            data: data,
            bucket: bucket,
            key: key
        )
    }

    let listObjects = try await client.listObjects(bucket: bucket)

    #expect(listObjects.isTruncated == false)
    #expect(listObjects.nextContinuationToken == nil)
    #expect(listObjects.contents.map(\.key).sorted() == keys.sorted())
    #expect(listObjects.contents.allSatisfy { !$0.eTag.isEmpty })
    #expect(listObjects.contents.allSatisfy { $0.size == data.count })
    #expect(listObjects.contents.allSatisfy { $0.lastModified.timeIntervalSinceNow > -10 })

    for key in keys {
        try await client.deleteObject(bucket: bucket, key: key)
    }
}

@Test
func listObjects_withPrefix() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let bucket = "list-objects-bucket02"
    let keys = ["dir01/\(#function)01", "dir02/\(#function)02", "dir01/\(#function)03"]

    for key in keys {
        try await client.putObject(
            data: data,
            bucket: bucket,
            key: key
        )
    }

    let listObjects = try await client.listObjects(
        bucket: bucket,
        prefix: "dir01"
    )

    #expect(listObjects.isTruncated == false)
    #expect(listObjects.nextContinuationToken == nil)
    #expect(listObjects.contents.map(\.key).sorted() == ["dir01/\(#function)01", "dir01/\(#function)03"])

    for key in keys {
        try await client.deleteObject(bucket: bucket, key: key)
    }
}

@Test
func listObjects_maxKeysContinuationToken() async throws {
    let client = createS3Client()

    let data = randomData(megabytes: 1)
    let bucket = "list-objects-bucket03"
    let keys = [
        "\(#function)01", "\(#function)02", "\(#function)03", "\(#function)04", "\(#function)05",
        "\(#function)06", "\(#function)07", "\(#function)08", "\(#function)09", "\(#function)10",
        "\(#function)11"
    ]

    for key in keys {
        try await client.putObject(
            data: data,
            bucket: bucket,
            key: key
        )
    }

    let listObjects = try await client.listObjects(
        bucket: bucket,
        maxKeys: 5
    )

    #expect(listObjects.isTruncated == true)
    #expect(listObjects.nextContinuationToken != nil)
    #expect(listObjects.contents.map(\.key).sorted() == Array(keys[0..<5]))

    let listObjects2 = try await client.listObjects(
        bucket: bucket,
        continuationToken: listObjects.nextContinuationToken!,
        maxKeys: 5
    )

    #expect(listObjects2.isTruncated == true)
    #expect(listObjects2.nextContinuationToken != nil)
    #expect(listObjects2.contents.map(\.key).sorted()  == Array(keys[5..<10]))

    let listObjects3 = try await client.listObjects(
        bucket: bucket,
        continuationToken: listObjects2.nextContinuationToken!,
        maxKeys: 5
    )

    #expect(listObjects3.isTruncated == false)
    #expect(listObjects3.nextContinuationToken == nil)
    #expect(listObjects3.contents.map(\.key) == [keys.last])

    for key in keys {
        try await client.deleteObject(bucket: bucket, key: key)
    }
}

@Test
func listObjects_emptyBucket() async throws {
    let client = createS3Client()

    let bucket = "list-objects-bucket04"

    let listObjects = try await client.listObjects(bucket: bucket)

    #expect(listObjects.isTruncated == false)
    #expect(listObjects.nextContinuationToken == nil)
    #expect(listObjects.contents == [])
}

@Test
func listObjects_invalidBucket() async throws {
    let client = createS3Client()

    let bucket = "non-existing-bucket"

    await #expect {
        _ = try await client.listObjects(bucket: bucket)
    } throws: { error in
        guard let s3Error = error as? S3Error,
              case let .responseError(statusCode, errorData) = s3Error else {
            return false
        }

        return statusCode == 404 && errorData?.code == "NoSuchBucket"
    }
}
