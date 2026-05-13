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

    public init(partNumber: Int, eTag: String) {
        self.partNumber = partNumber
        self.eTag = eTag
    }
}
