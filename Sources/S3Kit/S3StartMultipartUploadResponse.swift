//
//  S3StartMultipartUploadResponse.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

struct S3StartMultipartUploadResponse: Sendable {

    let uploadId: String
}

extension S3StartMultipartUploadResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case uploadId = "UploadId"
    }
}
