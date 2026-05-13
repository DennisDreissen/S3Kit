//
//  ListObjectsResponse.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

struct ListObjectsResponse: Sendable, Codable, Equatable {

    let contents: [ObjectResponse]
    let nextContinuationToken: String?
    let isTruncated: Bool

    enum CodingKeys: String, CodingKey {
        case contents = "Contents"
        case nextContinuationToken = "NextContinuationToken"
        case isTruncated = "IsTruncated"
    }
}

extension ListObjectsResponse {

    var s3ListObjects: S3ListObjects {
        S3ListObjects(
            contents: contents.map(\.s3Object),
            nextContinuationToken: nextContinuationToken,
            isTruncated: isTruncated
        )
    }
}
