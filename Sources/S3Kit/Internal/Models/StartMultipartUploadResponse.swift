//
//  StartMultipartUploadResponse.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

struct StartMultipartUploadResponse: Sendable, Codable {

    let uploadId: String

    enum CodingKeys: String, CodingKey {
        case uploadId = "UploadId"
    }
}
