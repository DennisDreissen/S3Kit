//
//  CompleteMultipartUploadRequest.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation
import XMLCoder

struct CompleteMultipartUploadRequest: Encodable {

    let part: [Part]

    struct Part: Encodable {
        let partNumber: Int
        let eTag: String

        enum CodingKeys: String, CodingKey {
            case partNumber = "PartNumber"
            case eTag = "ETag"
        }
    }

    enum CodingKeys: String, CodingKey {
        case part = "Part"
    }
}

extension CompleteMultipartUploadRequest {

    init(parts: [S3ObjectPart]) {
        self.part = parts
            .sorted { $0.partNumber < $1.partNumber }
            .map { Part(partNumber: $0.partNumber, eTag: $0.eTag) }
    }

    func encode() throws -> Data {
        do {
            return try XMLEncoder().encode(self, withRootKey: "CompleteMultipartUpload")
        } catch {
            throw S3Error.encodingRequestFailed
        }
    }
}
