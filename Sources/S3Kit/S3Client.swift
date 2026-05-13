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

    /// Endpoint URL of the S3 service.
    public let endpoint: URL

    /// S3 region. Not required for all S3-compatible providers.
    public let region: String?

    /// Algorithm used to sign requests.
    public let signerAlgorithm: S3SignerAlgorithm

    /// Credentials provider to authenticate requests.
    public let credentials: S3CredentialsProvider

    /// HTTP client used by S3Client.
    public let httpClient: S3HTTPClient

    /// Create an S3 client.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint URL of the S3 service.
    ///   - region: The region. Not required for all S3-compatible providers.
    ///   - credentials: The credentials used to sign requests.
    ///   - httpClient: The HTTPClient used to execute the requests. Defaults to URLSession.shared.
    public init(
        endpoint: URL,
        region: String? = nil,
        signerAlgorithm: S3SignerAlgorithm = .sigV4,
        credentials: S3CredentialsProvider,
        httpClient: S3HTTPClient = URLSession.shared
    ) {
        self.endpoint = endpoint
        self.region = region
        self.signerAlgorithm = signerAlgorithm
        self.credentials = credentials
        self.httpClient = httpClient
    }

    /// Check if a bucket exists and caller has access to it.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket.
    public func headBucket(
        bucket: String
    ) async throws {
        let request = try createRequest(
            method: "HEAD",
            path: "/\(bucket)"
        )

        try await executeRequest(request)
    }

    /// Retrieve metadata for an object without downloading its contents.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    /// - Returns: Metadata for the object.
    public func headObject(
        bucket: String,
        key: String
    ) async throws -> S3ObjectMetadata {
        let request = try createRequest(
            method: "HEAD",
            path: "/\(bucket)/\(key)"
        )

        let (_, http) = try await executeRequest(request)

        guard let contentLengthString = http.value(forHTTPHeaderField: "Content-Length"),
              let contentLength = Int(contentLengthString)
        else {
            throw S3Error.missingResponseHeader("Content-Length")
        }

        guard let eTag = http.value(forHTTPHeaderField: "ETag") else {
            throw S3Error.missingResponseHeader("ETag")
        }

        guard let lastModifiedString = http.value(forHTTPHeaderField: "Last-Modified"),
              let lastModified = DateFormatter.rfc2822.date(from: lastModifiedString)
        else {
            throw S3Error.missingResponseHeader("Last-Modified")
        }

        return S3ObjectMetadata(
            eTag: eTag,
            size: contentLength,
            lastModified: lastModified,
            contentType: http.value(forHTTPHeaderField: "Content-Type")
        )
    }

    /// List objects.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - prefix: Limits the response to keys that begin with the specified prefix.
    ///   - continuationToken: The token returned by a previous `listObjects` call to retrieve the next page of results.
    ///   - maxKeys: The maximum number of objects to return per page.
    /// - Returns: A response containing the list of objects and a continuation token if more results are available.
    public func listObjects(
        bucket: String,
        prefix: String? = nil,
        continuationToken: String? = nil,
        maxKeys: Int? = nil
    ) async throws -> S3ListObjects {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "list-type", value: "2"),
            URLQueryItem(name: "prefix", value: prefix),
            URLQueryItem(name: "continuation-token", value: continuationToken),
            URLQueryItem(name: "max-keys", value: maxKeys.map(String.init))
        ]

        let request = try createRequest(
            method: "GET",
            path: "/\(bucket)",
            queryItems: queryItems.filter { $0.value != nil }
        )

        let (data, _) = try await executeRequest(request)

        return try decode(
            ListObjectsResponse.self,
            from: data,
            dateDecodingStrategy: .formatted(.iso8601)
        ).s3ListObjects
    }

    /// Download an object.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    /// - Returns: The object's content as `Data`.
    public func getObject(
        bucket: String,
        key: String
    ) async throws -> Data {
        let request = try createRequest(
            method: "GET",
            path: "/\(bucket)/\(key)"
        )

        let (data, _) = try await executeRequest(request)

        return data
    }

    /// Upload an object.
    ///
    /// - Parameters:
    ///   - data: The object data.
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - contentType: A MIME type describing the format of the object data.
    public func putObject(
        data: Data,
        bucket: String,
        key: String,
        contentType: String? = nil
    ) async throws {
        let headers = [
            "Content-Type": contentType
        ]

        let request = try createRequest(
            method: "PUT",
            path: "/\(bucket)/\(key)",
            headers: HTTPHeaders(headers.compactMapValues { $0 }),
            body: data
        )

        try await executeRequest(request)
    }

    /// Initiate a new multipart upload.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - contentType: A MIME type describing the format of the object data.
    /// - Returns: A string containing the upload ID.
    public func createMultipartUpload(
        bucket: String,
        key: String,
        contentType: String? = nil,
    ) async throws -> String {
        let headers = [
            "Content-Type": contentType
        ]

        let queryItems = [
            URLQueryItem(name: "uploads", value: nil)
        ]

        let request = try createRequest(
            method: "POST",
            path: "/\(bucket)/\(key)",
            queryItems: queryItems,
            headers: HTTPHeaders(headers.compactMapValues { $0 })
        )

        let (data, _) = try await executeRequest(request)

        return try decode(StartMultipartUploadResponse.self, from: data).uploadId
    }

    /// Upload a part for a multipart upload.
    ///
    /// - Parameters:
    ///   - data: The part data.
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - uploadId: The upload ID returned by the`createMultipartUpload`.
    ///   - partNumber: Part number of part being uploaded.
    /// - Returns: An object containing the `partNumber` and `eTag` of the uploaded part.  Pass these to `completeMultipartUpload` when all parts are uploaded.
    public func uploadPart(
        data: Data,
        bucket: String,
        key: String,
        uploadId: String,
        partNumber: Int
    ) async throws -> S3ObjectPart {
        let headers = [
            "Content-Type": "application/octet-stream"
        ]

        let queryItems = [
            URLQueryItem(name: "partNumber", value: "\(partNumber)"),
            URLQueryItem(name: "uploadId", value: uploadId)
        ]

        let request = try createRequest(
            method: "PUT",
            path: "/\(bucket)/\(key)",
            queryItems: queryItems,
            headers: HTTPHeaders(headers),
            body: data
        )

        let (_, http) = try await executeRequest(request)

        guard let eTag = http.value(forHTTPHeaderField: "ETag") else {
            throw S3Error.missingResponseHeader("ETag")
        }

        return S3ObjectPart(
            partNumber: partNumber,
            eTag: eTag
        )
    }

    /// Complete a multipart upload.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - uploadId: The upload ID returned by the`createMultipartUpload`.
    ///   - parts: The list of parts returned by all the `uploadPart` calls.
    public func completeMultipartUpload(
        bucket: String,
        key: String,
        uploadId: String,
        parts: [S3ObjectPart]
    ) async throws {
        let headers = [
            "Content-Type": "application/xml"
        ]

        let queryItems = [
            URLQueryItem(name: "uploadId", value: uploadId)
        ]

        let request = try createRequest(
            method: "POST",
            path: "/\(bucket)/\(key)",
            queryItems: queryItems,
            headers: HTTPHeaders(headers),
            body: try CompleteMultipartUploadRequest(parts: parts)
                .encode()
        )

        let (data, response) = try await executeRequest(request)

        if data.range(of: Data("<Error>".utf8)) != nil {
            let errorData = try decode(ErrorDataResponse.self, from: data)
            throw S3Error.responseError(statusCode: response.statusCode, errorData: errorData.s3ErrorData)
        }
    }

    /// Abort a multipart upload.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - uploadId: The upload ID returned by the`createMultipartUpload`.
    public func abortMultipartUpload(
        bucket: String,
        key: String,
        uploadId: String
    ) async throws {
        let request = try createRequest(
            method: "DELETE",
            path: "/\(bucket)/\(key)",
            queryItems: [
                URLQueryItem(name: "uploadId", value: uploadId)
            ]
        )

        try await executeRequest(request)
    }

    /// Copy an object.
    ///
    /// - Parameters:
    ///   - sourceBucket: The name of the bucket where the object is copied from.
    ///   - sourceKey: The key of the object to be copied.
    ///   - bucket: The name of the bucket where the object is copied to.
    ///   - key: The key of the copied object.
    public func copyObject(
        sourceBucket: String,
        sourceKey: String,
        bucket: String,
        key: String
    ) async throws {
        let encodedBucket = sourceBucket.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? sourceBucket
        let encodedKey = sourceKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? sourceKey

        let headers = [
            "x-amz-copy-source": "/\(encodedBucket)/\(encodedKey)"
        ]

        let request = try createRequest(
            method: "PUT",
            path: "/\(bucket)/\(key)",
            headers: HTTPHeaders(headers)
        )

        try await executeRequest(request)
    }

    /// Delete an object.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    public func deleteObject(
        bucket: String,
        key: String
    ) async throws {
        let request = try createRequest(
            method: "DELETE",
            path: "/\(bucket)/\(key)",
        )

        try await executeRequest(request)
    }
}

private extension S3Client {

    func createRequest(
        method: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: HTTPHeaders = HTTPHeaders(),
        body: Data? = nil
    ) throws -> URLRequest {
        let body = body ?? Data()
        var headers = headers

        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw S3Error.invalidURL
        }

        components.path = path

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw S3Error.invalidURL
        }

        let signer = AWSSigner(
            credentials: credentials,
            name: "s3",
            region: region ?? "",
            algorithm: signerAlgorithm == .sigV4 ? .sigV4 : .sigV4a
        )

        guard let processedUrl = signer.processURL(url: url) else {
            throw S3Error.invalidURL
        }

        var request = URLRequest(url: processedUrl)
        request.httpMethod = method
        request.httpBody = body.isEmpty ? nil : body

        if !body.isEmpty {
            headers["Content-Length"] = "\(body.count)"
        }

        signer.signHeaders(
            url: processedUrl,
            method: method,
            headers: headers,
            body: body.isEmpty ? nil : .data(body)
        )
        .forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        return request
    }

    @discardableResult
    func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, urlResponse) = try await httpClient.data(for: request)

        guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
            throw S3Error.invalidResponse
        }

        guard (200..<300).contains(httpUrlResponse.statusCode) else {
            throw S3Error.responseError(
                statusCode: httpUrlResponse.statusCode,
                errorData: try? decode(ErrorDataResponse.self, from: data).s3ErrorData
            )
        }

        return (data, httpUrlResponse)
    }

    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        dateDecodingStrategy: XMLDecoder.DateDecodingStrategy = .secondsSince1970
    ) throws -> T {
        do {
            let decoder = XMLDecoder()
            decoder.dateDecodingStrategy = dateDecodingStrategy
            return try decoder.decode(type.self, from: data)
        } catch {
            throw S3Error.decodingResponseFailed
        }
    }
}
