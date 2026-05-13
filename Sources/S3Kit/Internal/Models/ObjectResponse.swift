//
//  ObjectResponse.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

struct ObjectResponse: Sendable, Codable, Equatable {

    let key: String
    let eTag: String
    let size: Int
    let lastModified: Date

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case eTag = "ETag"
        case size = "Size"
        case lastModified = "LastModified"
    }
}

extension ObjectResponse {

    var s3Object: S3Object {
        S3Object(
            key: key,
            eTag: eTag,
            size: size,
            lastModified: lastModified
        )
    }
}
