//
//  Helpers.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 07/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation
import S3Kit

let someData = "some data".data(using: .utf8)!
let someErrorData = "error data".data(using: .utf8)!

let rfcDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "GMT")
    return formatter
}()

let iso8601DateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    return formatter
}()

func createS3Client(
    endpoint: String = "https://example.local",
    region: String = "",
    accessKeyId: String = "accessKeyId",
    secretAccessKey: String = "secretAccessKey",
    httpClient: MockHTTPClient
) -> S3Client {
    S3Client(
        endpoint: endpoint,
        region: region,
        credentials: StaticCredential(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey
        ),
        httpClient: httpClient
    )
}
