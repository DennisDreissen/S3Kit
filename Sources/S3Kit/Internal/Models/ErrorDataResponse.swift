//
//  ErrorDataResponse.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

struct ErrorDataResponse: Sendable, Codable, Equatable {

    let code: String
    let message: String?
    let requestId: String?

    enum CodingKeys: String, CodingKey {
        case code = "Code"
        case message = "Message"
        case requestId = "RequestId"
    }
}

extension ErrorDataResponse {

    var s3ErrorData: S3ErrorData {
        S3ErrorData(
            code: code,
            message: message,
            requestId: requestId
        )
    }
}
