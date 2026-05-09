//
//  S3ListObjectsResponse.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public struct S3ListObjectsResponse: Sendable, Equatable {

    /// The list of objects returned for this page.
    public let contents: [S3Object]

    /// A token to retrieve the next page of results. Pass this to the next
    /// `listObjects` call as `continuationToken`. `nil` if there are no more results.
    public let nextContinuationToken: String?

    /// Indicates whether the response was truncated. If `true`, use
    /// `nextContinuationToken` to retrieve the remaining objects.
    public let isTruncated: Bool
}

extension S3ListObjectsResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case contents = "Contents"
        case nextContinuationToken = "NextContinuationToken"
        case isTruncated = "IsTruncated"
    }
}
