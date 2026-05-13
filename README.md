# S3Kit for Swift

This is an S3 client for interacting with AWS S3 and S3-compatible storage services. This library is intentionally limited in scope as a lightweight alternative to larger SDKs like [Soto](https://github.com/soto-project/soto) or the [AWS SDK for Swift.](https://github.com/awslabs/aws-sdk-swift) Feature requests and pull requests are welcome, but please keep the minimal scope in mind.

 ```swift
let client = S3Client(
    endpoint: URL(string: "https://s3.compatible.service.com")!,
    region: "region",
    credentials: S3Credentials(
        accessKeyId: "1234",
        secretAccessKey: "abcd"
    )
)

try await client.putObject(
    data: Data(),
    bucket: "my_bucket",
    key: "example.jpg",
    contentType: "image/jpeg"
)
 ```
## Setup using SPM

 ```swift
dependencies: [
    .package(url: "https://github.com/DennisDreissen/S3Kit.git", .upToNextMajor(from: "1.0.0"))
]
 ```

## Usage

### Head bucket

Check if a bucket exists and you're allowed to access it.

 ```swift
try await client.headBucket(bucket: "bucket")
 ```
 
### Head object

Get metadata information about an object.

 ```swift
let metadata = try await client.headObject(bucket: "bucket", key: "example.jpg")
 ```

### List objects

List all objects in a bucket. The max keys and continuation token can be used to achieve pagination. The prefix limits items that have a name starting with the prefix.

```swift
let objectsData = try await client.listObjects(bucket: "bucket")
```

```swift
let objectsData = try await client.listObjects(
    bucket: "bucket",
    prefix: "prefix",
    continuationToken: "token",
    maxKeys: 25
)
```

### Get object

```swift
let data = try await client.getObject(bucket: "bucket", key: "example.jpg")
```

### Put object

```swift
try await client.putObject(
    data: Data(),
    bucket: "bucket",
    key: "example.jpg",
    contentType: "image/jpeg"
)
```

### Multipart object uploads

Initiate a new multipart upload. The `uploadId` should be passed to all other multipart related calls.

```swift
let uploadId = try await client.createMultipartUpload(
    bucket: "bucket",
    key: "example.jpg",
    contentType: "image/jpeg"
)
```

Upload a part. The returned `objectPart` from all parts uploaded should be passed to the `completeMultipartUpload` method.

```swift
let objectPart = try await client.uploadPart(
    data: Data(),
    bucket: "bucket",
    key: "example.jpg",
    uploadId: "uploadId",
    partNumber: 1
)
```

Complete a multipart upload. Pass all the parts received from the `uploadPart` methods. The order of the parts in the array does not matter, parts will be sorted based on their `partNumber` before being sent to the S3 service.

```swift
try await client.completeMultipartUpload(
    bucket: "bucket",
    key: "example.jpg",
    uploadId: "uploadId",
    parts: [objectPart1, objectPart2]
)
```

Abort a multipart upload. This should be called to cancel an initiated multipart upload. Make sure to call this method when receiving an error on `uploadPart` or `completeMultipartUpload` to let the server know to clean up remaining state for the multipart upload.

```swift
try await client.abortMultipartUpload(
    bucket: "bucket",
    key: "example.jpg",
    uploadId: "uploadId"
)
```

### Copy object

```swift
try await client.copyObject(
    sourceBucket: "bucket01",
    sourceKey: "example.jpg",
    bucket: "bucket02",
    key: "example.jpg"
)
```

### Delete object

```swift
try await client.deleteObject(
    bucket: "bucket",
    key: "example.jpg"
)
```

### Errors

```swift
public enum S3Error: Error, Sendable, Equatable {

    /// The URL built to create the S3 request is not valid.
    case invalidURL

    /// The response from the server is not valid.
    case invalidResponse

    /// A header expected in the response is missing. Contains the missing header key.
    case missingResponseHeader(String)

    /// Encoding the request body failed.
    case encodingRequestFailed

    /// Decoding the response body failed.
    case decodingResponseFailed

    /// The server returned an error. Contains the status code and an optional error data, not all operations return error data.
    case responseError(statusCode: Int, errorData: S3ErrorData?)
}
```

## Acknowledgements

The AWS Signature V4 signing implementation is based on code from [soto-core](https://github.com/soto-project/soto-core) by the Soto project authors, licensed under [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0).
