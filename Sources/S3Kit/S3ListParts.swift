//
//  S3ListParts.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 16/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public struct S3ListParts: Sendable, Equatable {

    /// The list of parts.
    public let contents: [S3ObjectPart]

    /// A token to retrieve the next set of results if there are more results than the `maxParts` from the request.
    /// Pass this to the next `listParts` call as the `nextPartNumberMarker`.
    public let nextPartNumberMarker: Int?

    /// Indicates whether the response was truncated. If `true`, use
    /// `nextPartNumberMarker` to retrieve the remaining parts.
    public let isTruncated: Bool

    public init(contents: [S3ObjectPart], nextPartNumberMarker: Int? = nil, isTruncated: Bool = false) {
        self.contents = contents
        self.nextPartNumberMarker = nextPartNumberMarker
        self.isTruncated = isTruncated
    }
}
