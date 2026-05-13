//
//  Helpers.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 12/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation
import S3Kit

func createS3Client() -> S3Client {
    S3Client(
        endpoint: URL(string: "http://127.0.0.1:29145")!,
        credentials: S3Credentials(
            accessKeyId: "s3client_integration_tests",
            secretAccessKey: "s3client_integration_tests"
        )
    )
}

func randomData(megabytes: Int) -> Data {
    Data(repeating: 0, count: megabytes * 1024 * 1024)
}
