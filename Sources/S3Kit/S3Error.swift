//
//  S3Error.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public enum S3Error: Error, Sendable, Equatable {

    /// The endpoint is not valid. Contains the invalid endpoint.
    case invalidEndpoint(String)

    /// The URL built to create the S3 request is not valid. Contains the invalid URL.
    case invalidURL(String)

    /// The response from the server is not valid.
    case invalidResponse

    /// A headers expected in the response is missing. Contains the missing header key.
    case missingHeader(String)

    /// The response from the server returned a status code outside the 2xx range. Contains the returned status code and the response body.
    case errorResponse(statusCode: Int, body: Data)
}
