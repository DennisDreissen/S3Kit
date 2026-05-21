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
let someErrorData = """
<?xml version="1.0" encoding="UTF-8"?>
<Error>
    <Code>ExmpleCode</Code>
    <Message>ExampleMessage</Message>
    <RequestId>ExampleRequestID</RequestId>
</Error>
""".data(using: .utf8)!

let someError = S3ErrorData(
    code: "ExmpleCode",
    message: "ExampleMessage",
    requestId: "ExampleRequestID"
)

func testData(kilobytes: Int) -> Data {
    var data = Data(count: kilobytes * 1024)
    data.withUnsafeMutableBytes {
        arc4random_buf($0.baseAddress!, $0.count)
    }
    return data
}

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

let iso8601WithoutFractional: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    return formatter
}()

func createS3Client(
    endpoint: String = "https://example.local",
    region: String = "",
    signerAlgorithm: S3SignerAlgorithm = .sigV4,
    accessKeyId: String = "accessKeyId",
    secretAccessKey: String = "secretAccessKey",
    httpClient: MockS3HTTPClient
) -> S3Client {
    S3Client(
        endpoint: URL(string: endpoint)!,
        region: region,
        signerAlgorithm: signerAlgorithm,
        credentials: S3Credentials(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey
        ),
        httpClient: httpClient
    )
}

extension AsyncThrowingStream where Element == Data {

    func collect() async throws -> Data {
        try await reduce(into: Data()) { @Sendable in $0.append($1) }
    }
}
