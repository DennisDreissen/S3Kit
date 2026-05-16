//
//  S3ListObjects.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public struct S3ListObjects: Sendable, Equatable {

    /// The list of objects.
    public let contents: [S3Object]

    /// A token to retrieve the next set of results if there are more results than the `maxKeys` from the request.
    /// Pass this to the next `listObjects` call as the `continuationToken`.
    public let nextContinuationToken: String?

    /// Indicates whether the response was truncated. If `true`, use
    /// `nextContinuationToken` to retrieve the remaining objects.
    public let isTruncated: Bool

    public init(contents: [S3Object], nextContinuationToken: String? = nil, isTruncated: Bool = false) {
        self.contents = contents
        self.nextContinuationToken = nextContinuationToken
        self.isTruncated = isTruncated
    }
}
