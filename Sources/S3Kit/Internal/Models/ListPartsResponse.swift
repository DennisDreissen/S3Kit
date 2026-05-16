//
//  ListPartsResponse.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 16/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

struct ListPartsResponse: Sendable, Codable, Equatable {

    let contents: [ObjectPartResponse]
    let nextPartNumberMarker: Int?
    let isTruncated: Bool

    enum CodingKeys: String, CodingKey {
        case contents = "Part"
        case nextPartNumberMarker = "NextPartNumberMarker"
        case isTruncated = "IsTruncated"
    }
}

extension ListPartsResponse {

    var s3ListParts: S3ListParts {
        S3ListParts(
            contents: contents.map(\.s3ObjectPart),
            nextPartNumberMarker: nextPartNumberMarker,
            isTruncated: isTruncated
        )
    }
}
