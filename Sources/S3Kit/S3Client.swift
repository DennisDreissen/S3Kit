//
//  S3Client.swift
//  S3Kit
//
//  Created by Dennis Dreissen on 06/05/2026.
//  Copyright © 2026 Dennis Dreissen
//

import Foundation
import XMLCoder

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
    ///   - signerAlgorithm: The algorithm used to sign requests.
    ///   - credentials: The credentials used to sign requests.
    ///   - httpClient: The S3HTTPClient used to execute the requests.
    public init(
        endpoint: URL,
        region: String? = nil,
        signerAlgorithm: S3SignerAlgorithm = .sigV4,
        credentials: S3CredentialsProvider,
        httpClient: S3HTTPClient = S3DefaultHTTPClient()
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
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    @discardableResult
    public func headBucket(
        bucket: String,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<Void> {
        let request = try createRequest(
            method: "HEAD",
            path: "/\(bucket)",
            headers: sanitize(customHeaders)
        )

        let (_, http) = try await executeRequest(request)

        return S3Response(
            result: (),
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Retrieve metadata for an object without downloading its contents.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    /// - Returns: Metadata for the object.
    public func headObject(
        bucket: String,
        key: String,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<S3ObjectMetadata> {
        let request = try createRequest(
            method: "HEAD",
            path: "/\(bucket)/\(key)",
            headers: sanitize(customHeaders)
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

        return S3Response(
            result: S3ObjectMetadata(
                eTag: eTag,
                size: contentLength,
                lastModified: lastModified,
                contentType: http.value(forHTTPHeaderField: "Content-Type")
            ),
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// List objects.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - prefix: Limits the response to keys that begin with the specified prefix.
    ///   - continuationToken: The token returned by a previous `listObjects` call to retrieve the next page of results.
    ///   - maxKeys: The maximum number of objects to return per page.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    /// - Returns: A response containing the list of objects and a continuation token if more results are available.
    public func listObjects(
        bucket: String,
        prefix: String? = nil,
        continuationToken: String? = nil,
        maxKeys: Int? = nil,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<S3ListObjects> {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "list-type", value: "2"),
            URLQueryItem(name: "prefix", value: prefix),
            URLQueryItem(name: "continuation-token", value: continuationToken),
            URLQueryItem(name: "max-keys", value: maxKeys.map(String.init))
        ]

        let request = try createRequest(
            method: "GET",
            path: "/\(bucket)",
            queryItems: queryItems.filter { $0.value != nil },
            headers: sanitize(customHeaders)
        )

        let (data, http) = try await executeRequest(request)

        return S3Response(
            result: try decode(
                ListObjectsResponse.self,
                from: data
            ).s3ListObjects,
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Download an object.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    /// - Returns: The object's content as `Data`.
    public func getObject(
        bucket: String,
        key: String,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<Data> {
        let request = try createRequest(
            method: "GET",
            path: "/\(bucket)/\(key)",
            headers: sanitize(customHeaders)
        )

        let (data, http) = try await executeRequest(request)

        return S3Response(
            result: data,
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Download an object to the disk.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    /// - Returns: The `URL` to where the object has been downloaded.
    public func downloadObject(
        bucket: String,
        key: String,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<URL> {
        let request = try createRequest(
            method: "GET",
            path: "/\(bucket)/\(key)",
            headers: sanitize(customHeaders)
        )

        let (url, http) = try await executeDownloadRequest(request)

        return S3Response(
            result: url,
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Upload an object.
    ///
    /// - Parameters:
    ///   - data: The object data.
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - contentType: A MIME type describing the format of the object data.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    ///   - progressHandler: A callback that reports the upload progress as a Double from 0-1.
    @discardableResult
    public func putObject(
        data: Data,
        bucket: String,
        key: String,
        contentType: String? = nil,
        customHeaders: [String: String] = [:],
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async throws -> S3Response<Void> {
        var headers = sanitize(customHeaders)
        headers.setIfMissing(contentType, for: "Content-Type")

        var request = try createRequest(
            method: "PUT",
            path: "/\(bucket)/\(key)",
            headers: headers,
            body: data
        )

        request.httpBody = nil

        let (_, http) = try await executeUploadRequest(request, data: data, progressHandler: progressHandler)

        return S3Response(
            result: (),
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Initiate a new multipart upload.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - contentType: A MIME type describing the format of the object data.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    /// - Returns: A string containing the upload ID.
    public func createMultipartUpload(
        bucket: String,
        key: String,
        contentType: String? = nil,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<String> {
        var headers = sanitize(customHeaders)
        headers.setIfMissing(contentType, for: "Content-Type")

        let queryItems = [
            URLQueryItem(name: "uploads", value: nil)
        ]

        let request = try createRequest(
            method: "POST",
            path: "/\(bucket)/\(key)",
            queryItems: queryItems,
            headers: headers
        )

        let (data, http) = try await executeRequest(request)

        return S3Response(
            result: try decode(StartMultipartUploadResponse.self, from: data).uploadId,
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Upload a part for a multipart upload.
    ///
    /// - Parameters:
    ///   - data: The part data.
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - uploadId: The upload ID returned by the`createMultipartUpload`.
    ///   - partNumber: Part number of part being uploaded.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    ///   - progressHandler: A callback that reports the upload progress as a Double from 0-1.
    /// - Returns: An object containing the `partNumber` and `eTag` of the uploaded part.  Pass these to `completeMultipartUpload` when all parts are uploaded.
    public func uploadPart(
        data: Data,
        bucket: String,
        key: String,
        uploadId: String,
        partNumber: Int,
        customHeaders: [String: String] = [:],
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async throws -> S3Response<S3ObjectPart> {
        var headers = sanitize(customHeaders)
        headers.setIfMissing("application/octet-stream", for: "Content-Type")

        let queryItems = [
            URLQueryItem(name: "partNumber", value: "\(partNumber)"),
            URLQueryItem(name: "uploadId", value: uploadId)
        ]

        var request = try createRequest(
            method: "PUT",
            path: "/\(bucket)/\(key)",
            queryItems: queryItems,
            headers: headers,
            body: data
        )

        request.httpBody = nil

        let (_, http) = try await executeUploadRequest(request, data: data, progressHandler: progressHandler)

        guard let eTag = http.value(forHTTPHeaderField: "ETag") else {
            throw S3Error.missingResponseHeader("ETag")
        }

        return S3Response(
            result: S3ObjectPart(
                partNumber: partNumber,
                eTag: eTag
            ),
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// List parts.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the part.
    ///   - key: The key of the object.
    ///   - uploadId: The upload ID returned by the`createMultipartUpload`.
    ///   - partNumberMarker: The marker returned by a previous `listParts` call to retrieve the next page of results.
    ///   - maxParts: The maximum number of parts to return per page.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    /// - Returns: A response containing the list of parts and a part number marker if more results are available.
    public func listParts(
        bucket: String,
        key: String,
        uploadId: String,
        partNumberMarker: Int? = nil,
        maxParts: Int? = nil,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<S3ListParts> {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "uploadId", value: uploadId),
            URLQueryItem(name: "part-number-marker", value: partNumberMarker.map(String.init)),
            URLQueryItem(name: "max-parts", value: maxParts.map(String.init))
        ]

        let request = try createRequest(
            method: "GET",
            path: "/\(bucket)/\(key)",
            queryItems: queryItems.filter { $0.value != nil },
            headers: sanitize(customHeaders)
        )

        let (data, http) = try await executeRequest(request)

        return S3Response(
            result: try decode(
                ListPartsResponse.self,
                from: data
            ).s3ListParts,
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Complete a multipart upload.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - uploadId: The upload ID returned by the`createMultipartUpload`.
    ///   - parts: The list of parts returned by all the `uploadPart` calls.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    @discardableResult
    public func completeMultipartUpload(
        bucket: String,
        key: String,
        uploadId: String,
        parts: [S3ObjectPart],
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<Void> {
        var headers = sanitize(customHeaders)
        headers.setIfMissing("application/xml", for: "Content-Type")

        let queryItems = [
            URLQueryItem(name: "uploadId", value: uploadId)
        ]

        let request = try createRequest(
            method: "POST",
            path: "/\(bucket)/\(key)",
            queryItems: queryItems,
            headers: headers,
            body: try CompleteMultipartUploadRequest(parts: parts)
                .encode()
        )

        let (data, http) = try await executeRequest(request)

        if data.range(of: Data("<Error>".utf8)) != nil {
            let errorData = try decode(ErrorDataResponse.self, from: data)
            throw S3Error.responseError(statusCode: http.statusCode, errorData: errorData.s3ErrorData)
        }

        return S3Response(
            result: (),
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Abort a multipart upload.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket where the object is uploaded to.
    ///   - key: The key of the object.
    ///   - uploadId: The upload ID returned by the`createMultipartUpload`.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    @discardableResult
    public func abortMultipartUpload(
        bucket: String,
        key: String,
        uploadId: String,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<Void> {
        let request = try createRequest(
            method: "DELETE",
            path: "/\(bucket)/\(key)",
            queryItems: [
                URLQueryItem(name: "uploadId", value: uploadId)
            ],
            headers: sanitize(customHeaders)
        )

        let (_, http) = try await executeRequest(request)

        return S3Response(
            result: (),
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Copy an object.
    ///
    /// - Parameters:
    ///   - sourceBucket: The name of the bucket where the object is copied from.
    ///   - sourceKey: The key of the object to be copied.
    ///   - bucket: The name of the bucket where the object is copied to.
    ///   - key: The key of the copied object.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    @discardableResult
    public func copyObject(
        sourceBucket: String,
        sourceKey: String,
        bucket: String,
        key: String,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<Void> {
        let encodedBucket = sourceBucket.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? sourceBucket
        let encodedKey = sourceKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? sourceKey

        var headers = sanitize(customHeaders)
        headers["x-amz-copy-source"] = "/\(encodedBucket)/\(encodedKey)"

        let request = try createRequest(
            method: "PUT",
            path: "/\(bucket)/\(key)",
            headers: headers
        )

        let (_, http) = try await executeRequest(request)

        return S3Response(
            result: (),
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }

    /// Delete an object.
    ///
    /// - Parameters:
    ///   - bucket: The name of the bucket containing the object.
    ///   - key: The key of the object to retrieve metadata for.
    ///   - customHeaders: Custom headers passed in the request to the S3 service.
    @discardableResult
    public func deleteObject(
        bucket: String,
        key: String,
        customHeaders: [String: String] = [:]
    ) async throws -> S3Response<Void> {
        let request = try createRequest(
            method: "DELETE",
            path: "/\(bucket)/\(key)",
            headers: sanitize(customHeaders)
        )

        let (_, http) = try await executeRequest(request)

        return S3Response(
            result: (),
            statusCode: http.statusCode,
            headers: http.stringHeaders
        )
    }
}

private extension S3Client {

    static let reservedHeaders: Set<String> = [
        "authorization",
        "host",
        "content-length",
        "x-amz-date",
        "x-amz-content-sha256",
        "x-amz-copy-source"
    ]

    func sanitize(_ customHeaders: [String: String]) -> HTTPHeaders {
        HTTPHeaders(
            customHeaders.filter { !Self.reservedHeaders.contains($0.key.lowercased()) }
        )
    }

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

        return (data, try httpURLResponse(from: urlResponse, data: data))
    }

    @discardableResult
    func executeDownloadRequest(_ request: URLRequest) async throws -> (URL, HTTPURLResponse) {
        let (url, urlResponse) = try await httpClient.download(for: request)

        return (url, try httpURLResponse(from: urlResponse))
    }

    @discardableResult
    func executeUploadRequest(
        _ request: URLRequest,
        data: Data,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, urlResponse) = try await httpClient.upload(
            for: request,
            from: data
        ) { _, totalBytesSent, totalBytesExpectedToSend in
            progressHandler?(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
        }

        return (data, try httpURLResponse(from: urlResponse, data: data))
    }

    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        dateDecodingStrategy: XMLDecoder.DateDecodingStrategy? = nil
    ) throws -> T {
        do {
            let decoder = XMLDecoder()

            if let dateDecodingStrategy {
                decoder.dateDecodingStrategy = dateDecodingStrategy
            } else {
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let string = try container.decode(String.self)

                    if let date = DateFormatter.iso8601WithFractional.date(from: string) {
                        return date
                    }
                    
                    if let date = DateFormatter.iso8601WithoutFractional.date(from: string) {
                        return date
                    }

                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Invalid ISO 8601 date: \(string)"
                    )
                }
            }

            return try decoder.decode(type.self, from: data)
        } catch {
            throw S3Error.decodingResponseFailed
        }
    }

    func httpURLResponse(from urlResponse: URLResponse, data: Data? = nil) throws -> HTTPURLResponse {
        guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
            throw S3Error.invalidResponse
        }

        guard (200..<300).contains(httpUrlResponse.statusCode) else {
            throw S3Error.responseError(
                statusCode: httpUrlResponse.statusCode,
                errorData: data.flatMap { try? decode(ErrorDataResponse.self, from: $0).s3ErrorData }
            )
        }

        return httpUrlResponse
    }
}
