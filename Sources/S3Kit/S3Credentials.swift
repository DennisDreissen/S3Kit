//
//  S3Credentials.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 11/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

public struct S3Credentials: S3CredentialsProvider, Equatable {

    public let accessKeyId: String
    public let secretAccessKey: String
    public let sessionToken: String?

    public init(accessKeyId: String, secretAccessKey: String, sessionToken: String? = nil) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = sessionToken
    }
}
