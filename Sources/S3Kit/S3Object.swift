//
//  S3Object.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public struct S3Object: Sendable, Equatable {

    /// The object's key (path) within the bucket.
    public let key: String

    /// The entity tag of the object.
    public let eTag: String

    /// The size of the object in bytes.
    public let size: Int

    /// The date and time the object was last modified.
    public let lastModified: Date
}

extension S3Object: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        eTag = try container.decode(String.self, forKey: .eTag).trimmingCharacters(in: .init(charactersIn: "\""))
        size = try container.decode(Int.self, forKey: .size)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
    }

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case eTag = "ETag"
        case size = "Size"
        case lastModified = "LastModified"
    }
}
