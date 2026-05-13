//
//  S3Error.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public enum S3Error: Error, Sendable, Equatable {

    /// The URL built to create the S3 request is not valid.
    case invalidURL

    /// The response from the server is not valid.
    case invalidResponse

    /// A header expected in the response is missing. Contains the missing header key.
    case missingResponseHeader(String)

    /// Encoding the request body failed.
    case encodingRequestFailed

    /// Decoding the response body failed.
    case decodingResponseFailed

    /// The server returned an error. Contains the status code and an optional error data, not all operations return error data.
    case responseError(statusCode: Int, errorData: S3ErrorData?)
}
