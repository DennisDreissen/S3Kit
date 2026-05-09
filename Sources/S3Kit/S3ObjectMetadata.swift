//
//  S3ObjectMetadata.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public struct S3ObjectMetadata: Sendable, Equatable {

    /// The entity tag of the object.
    public let eTag: String

    /// The size of the object in bytes.
    public let size: Int

    /// The date and time the object was last modified.
    public let lastModified: Date

    /// The MIME type of the object.
    public let contentType: String?
}
