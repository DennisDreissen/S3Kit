//===----------------------------------------------------------------------===//
//
// This source file is based on code from the Soto for AWS open source project
// https://github.com/soto-project/soto-core
//
// Copyright (c) 2017-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Protocol for providing credential details for accessing S3 services.
public protocol Credential: Sendable {
    var accessKeyId: String { get }
    var secretAccessKey: String { get }
    var sessionToken: String? { get }
}

/// Static implementation of Credential where you supply the credentials.
public struct StaticCredential: Credential, Equatable {
    public let accessKeyId: String
    public let secretAccessKey: String
    public let sessionToken: String?

    public init(accessKeyId: String, secretAccessKey: String, sessionToken: String? = nil) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = sessionToken
    }
}
