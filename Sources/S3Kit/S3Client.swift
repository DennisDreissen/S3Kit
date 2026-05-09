//
//  S3Client.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation
import XMLCoder

public struct S3Client: Sendable {

    /// The endpoint URL of the S3 service.
    /// For AWS this is `https://s3.<region>.amazonaws.com`.
    /// For S3-compatible services this is the provider's endpoint.
    public let endpoint: String

    /// The AWS region, e.g. `us-east-1`. Not required for all S3-compatible providers.
    public let region: String?

    private let credentials: Credential
    private let httpClient: HTTPClient

    private let rfcDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter
    }()

    private let iso8601DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    /// Creates an S3 client for use with S3-compatible storage services.
    /// - Parameters:
    ///   - endpoint: The endpoint URL of the S3 service.
    ///   - region: The region. Not required for all S3-compatible providers.
    ///   - credentials: The credentials used to sign requests.
    public init(
        endpoint: String,
        region: String? = nil,
        credentials: Credential,
        httpClient: HTTPClient = URLSession.shared
    ) {
        self.endpoint = endpoint
        self.region = region
        self.credentials = credentials
        self.httpClient = httpClient
    }

    /// Creates an S3 client for use with AWS S3 storage services.
    /// - Parameters:
    ///   - region: The region.
    ///   - credentials: The credentials used to sign requests.
    public init(
        region: String,
        credentials: Credential,
        httpClient: HTTPClient = URLSession.shared
    ) {
        self.endpoint = "https://s3.\(region).amazonaws.com"
        self.region = region
        self.credentials = credentials
        self.httpClient = httpClient
    }

    /// Checks if a bucket exists and caller has access to it.
    /// - Parameters:
    ///   - bucket: The name of the bucket.
    /// - Throws: `S3Error.invalidEndpoint` if the endpoint is invalid.
    /// - Throws: `S3Error.invalidURL` if the URL built to create the S3 request is not valid.
    /// - Throws: `S3Error.invalidResponse` if the response from the server is not valid
    /// - Throws: `S3Error.errorResponse` if the server returns a non-2xx status code.
    /// - Throws: `URLError` if the network request fails.
    public func headBucket(
        bucket: String
    ) async throws {
        let request = try createRequest(
            method: "HEAD",
            bucket: bucket
        )

        try await executeRequest(request)
    }

    /// Retrieves metadata for an object without downloading its contents.
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    /// - Returns: Metadata for the object.
    /// - Throws: `S3Error.invalidEndpoint` if the endpoint is invalid.
    /// - Throws: `S3Error.invalidURL` if the URL built to create the S3 request is not valid.
    /// - Throws: `S3Error.invalidResponse` if the response from the server is not valid
    /// - Throws: `S3Error.errorResponse` if the server returns a non-2xx status code.
    /// - Throws: `S3Error.missingHeader` if a headers expected in the response is missing.
    /// - Throws: `URLError` if the network request fails.
    public func headObject(
        bucket: String,
        key: String
    ) async throws -> S3ObjectMetadata {
        let request = try createRequest(
            method: "HEAD",
            bucket: bucket,
            key: key
        )

        let (_, http) = try await executeRequest(request)

        guard let contentLengthString = http.value(forHTTPHeaderField: "Content-Length"),
              let contentLength = Int(contentLengthString)
        else {
            throw S3Error.missingHeader("Content-Length")
        }

        guard let eTag = http.value(forHTTPHeaderField: "ETag")?
            .trimmingCharacters(in: .init(charactersIn: "\""))
        else {
            throw S3Error.missingHeader("ETag")
        }

        guard let lastModifiedString = http.value(forHTTPHeaderField: "Last-Modified"),
              let lastModified = rfcDateFormatter.date(from: lastModifiedString)
        else {
            throw S3Error.missingHeader("Last-Modified")
        }

        return S3ObjectMetadata(
            eTag: eTag,
            size: contentLength,
            lastModified: lastModified,
            contentType: http.value(forHTTPHeaderField: "Content-Type")
        )
    }

    /// Lists objects in a bucket.
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - prefix: Limits the response to keys that begin with the specified prefix.
    ///   - continuationToken: The token returned by a previous `listObjects` call to retrieve the next page of results.
    ///   - maxKeys: The maximum number of objects to return per page.
    /// - Returns: A response containing the list of objects and a continuation token if more results are available.
    /// - Throws: `S3Error.invalidEndpoint` if the endpoint is invalid.
    /// - Throws: `S3Error.invalidURL` if the URL built to create the S3 request is not valid.
    /// - Throws: `S3Error.invalidResponse` if the response from the server is not valid
    /// - Throws: `S3Error.errorResponse` if the server returns a non-2xx status code.
    /// - Throws: `DecodingError` if the response cannot be decoded.
    /// - Throws: `URLError` if the network request fails.
    public func listObjects(
        bucket: String,
        prefix: String? = nil,
        continuationToken: String? = nil,
        maxKeys: Int? = nil
    ) async throws -> S3ListObjectsResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "list-type", value: "2")
        ]

        if let prefix {
            queryItems.append(URLQueryItem(name: "prefix", value: prefix))
        }

        if let continuationToken {
            queryItems.append(URLQueryItem(name: "continuation-token", value: continuationToken))
        }

        if let maxKeys {
            queryItems.append(URLQueryItem(name: "max-keys", value: "\(maxKeys)"))
        }

        let request = try createRequest(
            method: "GET",
            bucket: bucket,
            key: "",
            queryItems: queryItems
        )

        let (data, _) = try await executeRequest(request)
        
        let decoder = XMLDecoder()
        decoder.dateDecodingStrategy = .formatted(iso8601DateFormatter)

        let response = try decoder.decode(S3ListObjectsResponse.self, from: data)

        return response
    }

    /// Downloads an object from a bucket.
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    /// - Returns: The object's content as `Data`.
    /// - Throws: `S3Error.invalidEndpoint` if the endpoint is invalid.
    /// - Throws: `S3Error.invalidURL` if the URL built to create the S3 request is not valid.
    /// - Throws: `S3Error.invalidResponse` if the response from the server is not valid
    /// - Throws: `S3Error.errorResponse` if the server returns a non-2xx status code.
    /// - Throws: `URLError` if the network request fails.
    public func getObject(
        bucket: String,
        key: String
    ) async throws -> Data {
        let request = try createRequest(
            method: "GET",
            bucket: bucket,
            key: key
        )

        let (data, _) = try await executeRequest(request)

        return data
    }

    /// Uploads an object to a bucket.
    /// - Parameters:
    ///   - data: The data to upload.
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    ///   - contentType: The MIME type of the object.
    /// - Throws: `S3Error.invalidEndpoint` if the endpoint is invalid.
    /// - Throws: `S3Error.invalidURL` if the URL built to create the S3 request is not valid.
    /// - Throws: `S3Error.invalidResponse` if the response from the server is not valid
    /// - Throws: `S3Error.errorResponse` if the server returns a non-2xx status code.
    /// - Throws: `URLError` if the network request fails.
    public func putObject(
        data: Data,
        bucket: String,
        key: String,
        contentType: String? = nil
    ) async throws {
        var headers: HTTPHeaders = HTTPHeaders()

        if let contentType {
            headers["Content-Type"] = contentType
        }

        let request = try createRequest(
            method: "PUT",
            bucket: bucket,
            key: key,
            headers: headers,
            body: data
        )

        try await executeRequest(request)
    }

    /// Uploads an object to a bucket using multipart upload.
    /// Suitable for large files as it uploads the data in chunks, with a minimum part size of 5 MB.
    /// - Parameters:
    ///   - stream: An async stream of data chunks to upload.
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    ///   - partSize: The size of each part in bytes. Defaults to 5 MB, which is the minimum allowed by S3.
    ///   - contentType: The MIME type of the object.
    ///   - onProgress: An optional closure called with the total number of bytes uploaded so far after each part completes.
    /// - Throws: `S3Error.invalidEndpoint` if the endpoint is invalid.
    /// - Throws: `S3Error.invalidURL` if the URL built to create the S3 request is not valid.
    /// - Throws: `S3Error.invalidResponse` if the response from the server is not valid
    /// - Throws: `S3Error.errorResponse` if the server returns a non-2xx status code.
    /// - Throws: `DecodingError` if the response cannot be decoded.
    /// - Throws: `URLError` if the network request fails.
    public func putObjectMultipart(
        stream: AsyncThrowingStream<Data, any Error>,
        bucket: String,
        key: String,
        partSize: Int = 5 * 1024 * 1024,
        contentType: String? = nil,
        onProgress: (@Sendable (Int) -> Void)? = nil
    ) async throws {
        let uploadId = try await startMultipartUpload(
            bucket: bucket,
            key: key,
            contentType: contentType
        )

        var parts: [(partNumber: Int, eTag: String)] = []
        var partNumber = 1
        var buffer = Data()
        var totalBytesUploaded = 0

        do {
            for try await chunk in stream {
                buffer.append(chunk)

                while buffer.count >= partSize {
                    let part = Data(buffer.prefix(partSize))
                    buffer = buffer.dropFirst(partSize)

                    let eTag = try await uploadPart(
                        bucket: bucket,
                        key: key,
                        uploadId: uploadId,
                        partNumber: partNumber,
                        data: part
                    )

                    totalBytesUploaded += part.count
                    parts.append((partNumber, eTag))
                    onProgress?(totalBytesUploaded)
                    partNumber += 1
                }
            }

            if !buffer.isEmpty {
                let eTag = try await uploadPart(
                    bucket: bucket,
                    key: key,
                    uploadId: uploadId,
                    partNumber: partNumber,
                    data: buffer
                )

                totalBytesUploaded += buffer.count
                parts.append((partNumber, eTag))
                onProgress?(totalBytesUploaded)
            }

            try await completeMultipartUpload(
                bucket: bucket,
                key: key,
                uploadId: uploadId,
                parts: parts
            )
        } catch {
            try? await abortMultipartUpload(
                bucket: bucket,
                key: key,
                uploadId: uploadId
            )

            throw error
        }
    }

    /// Deletes an object from a bucket.
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    /// - Throws: `S3Error.invalidEndpoint` if the endpoint is invalid.
    /// - Throws: `S3Error.invalidURL` if the URL built to create the S3 request is not valid.
    /// - Throws: `S3Error.invalidResponse` if the response from the server is not valid
    /// - Throws: `S3Error.errorResponse` if the server returns a non-2xx status code.
    public func deleteObject(
        bucket: String,
        key: String
    ) async throws {
        let request = try createRequest(
            method: "DELETE",
            bucket: bucket,
            key: key
        )

        try await executeRequest(request)
    }
}

private extension S3Client {

    func createRequest(
        method: String,
        bucket: String,
        key: String? = nil,
        queryItems: [URLQueryItem] = [],
        headers: HTTPHeaders = HTTPHeaders(),
        body: Data? = nil
    ) throws -> URLRequest {
        let body = body ?? Data()

        guard var components = URLComponents(string: endpoint) else {
            throw S3Error.invalidEndpoint(endpoint)
        }

        if let key, !key.isEmpty {
            components.path = "/\(bucket)/\(key)"
        } else {
            components.path = "/\(bucket)"
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            let description = key.map { "\(endpoint)/\(bucket)/\($0)" } ?? "\(endpoint)/\(bucket)"
            throw S3Error.invalidURL(description)
        }

        let signer = AWSSigner(
            credentials: credentials,
            name: "s3",
            region: region ?? ""
        )

        guard let processedUrl = signer.processURL(url: url) else {
            throw S3Error.invalidURL(url.absoluteString)
        }

        var request = URLRequest(url: processedUrl)
        request.httpMethod = method
        request.httpBody = body.isEmpty ? nil : body

        var allHeaders = headers

        if !body.isEmpty {
            allHeaders["Content-Length"] = "\(body.count)"
        }

        signer.signHeaders(
            url: processedUrl,
            method: method,
            headers: allHeaders,
            body: body.isEmpty ? nil : .data(body)
        )
        .forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        return request
    }

    @discardableResult
    func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await httpClient.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw S3Error.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            throw S3Error.errorResponse(statusCode: http.statusCode, body: data)
        }

        return (data, http)
    }

    func startMultipartUpload(
        bucket: String,
        key: String,
        contentType: String? = nil
    ) async throws -> String {
        var headers: HTTPHeaders = HTTPHeaders()

        if let contentType {
            headers["Content-Type"] = contentType
        }

        let request = try createRequest(
            method: "POST",
            bucket: bucket,
            key: key,
            queryItems: [
                URLQueryItem(name: "uploads", value: nil)
            ],
            headers: headers
        )

        let (data, _) = try await executeRequest(request)

        let response = try XMLDecoder().decode(S3StartMultipartUploadResponse.self, from: data)
        
        return response.uploadId
    }

    func uploadPart(
        bucket: String,
        key: String,
        uploadId: String,
        partNumber: Int,
        data: Data
    ) async throws -> String {
        let request = try createRequest(
            method: "PUT",
            bucket: bucket,
            key: key,
            queryItems: [
                URLQueryItem(name: "partNumber", value: "\(partNumber)"),
                URLQueryItem(name: "uploadId", value: uploadId),
            ],
            headers: HTTPHeaders([
                "Content-Type": "application/octet-stream"
            ]),
            body: data
        )

        let (_, http) = try await executeRequest(request)

        guard let eTag = http.value(forHTTPHeaderField: "ETag") else {
            throw S3Error.missingHeader("ETag")
        }

        return eTag
    }

    func completeMultipartUpload(
        bucket: String,
        key: String,
        uploadId: String,
        parts: [(partNumber: Int, eTag: String)]
    ) async throws {
        let partsXML = parts
            .sorted { $0.partNumber < $1.partNumber }
            .map { "<Part><PartNumber>\($0.partNumber)</PartNumber><ETag>\($0.eTag)</ETag></Part>" }
            .joined()

        let body = Data("<CompleteMultipartUpload>\(partsXML)</CompleteMultipartUpload>".utf8)

        let request = try createRequest(
            method: "POST",
            bucket: bucket,
            key: key,
            queryItems: [
                URLQueryItem(name: "uploadId", value: uploadId)
            ],
            headers: HTTPHeaders([
                "Content-Type": "application/xml"
            ]),
            body: body
        )

        try await executeRequest(request)
    }

    func abortMultipartUpload(
        bucket: String,
        key: String,
        uploadId: String
    ) async throws {
        let request = try createRequest(
            method: "DELETE",
            bucket: bucket,
            key: key,
            queryItems: [
                URLQueryItem(name: "uploadId", value: uploadId)
            ]
        )

        try await executeRequest(request)
    }
}
