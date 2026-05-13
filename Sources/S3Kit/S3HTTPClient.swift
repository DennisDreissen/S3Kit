//
//  S3HTTPClient.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 07/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation

public protocol S3HTTPClient: Sendable {

    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: S3HTTPClient {}
