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

    public init(key: String, eTag: String, size: Int, lastModified: Date) {
        self.key = key
        self.eTag = eTag
        self.size = size
        self.lastModified = lastModified
    }
}
