//
//  S3CredentialsProvider.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

public protocol S3CredentialsProvider: Sendable {

    var accessKeyId: String { get }
    var secretAccessKey: String { get }
    var sessionToken: String? { get }
}
