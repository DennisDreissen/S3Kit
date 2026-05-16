//
//  ObjectPartResponse.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 16/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

struct ObjectPartResponse: Sendable, Codable, Equatable {

    let partNumber: Int
    let eTag: String
    let size: Int
    let lastModified: Date

    enum CodingKeys: String, CodingKey {
        case partNumber = "PartNumber"
        case eTag = "ETag"
        case size = "Size"
        case lastModified = "LastModified"
    }
}

extension ObjectPartResponse {

    var s3ObjectPart: S3ObjectPart {
        S3ObjectPart(
            partNumber: partNumber,
            eTag: eTag,
            size: size,
            lastModified: lastModified
        )
    }
}
