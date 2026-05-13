//
//  S3ClientHeadBucketIntegrationTests.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 13/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Testing
import Foundation
@testable import S3Kit

@Test
func headBucket() async throws {
    let client = createS3Client()

    let bucket = "bucket01"

    try await client.headBucket(bucket: bucket)
}

@Test
func headBucket_invalidBucket() async throws {
    let client = createS3Client()

    let bucket = "non-existing-bucket"

    await #expect(throws: S3Error.responseError(statusCode: 404, errorData: nil)) {
        try await client.headBucket(bucket: bucket)
    }
}
