//
//  S3ObjectPart.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public struct S3ObjectPart: Sendable, Equatable {

    /// The number of the part assigned when calling `uploadPart`.
    public let partNumber: Int
    
    /// The entity tag of the part.
    public let eTag: String

    /// The size of the part in bytes. Only present in the `listParts` call.
    public let size: Int?

    /// The date and time the part was last modified. Only present in the `listParts` call.
    public let lastModified: Date?

    public init(partNumber: Int, eTag: String, size: Int? = nil, lastModified: Date? = nil) {
        self.partNumber = partNumber
        self.eTag = eTag
        self.size = size
        self.lastModified = lastModified
    }
}
