# S3Kit for Swift

This is an S3 client for interacting with AWS S3 and S3-compatible storage services. This library is intentionally limited in scope as a lightweight alternative to larger SDKs like [Soto](https://github.com/soto-project/soto) or the [AWS SDK for Swift.](https://github.com/awslabs/aws-sdk-swift) Feature requests and pull requests are welcome, but please keep the minimal scope in mind.

 ```Swift
// AWS S3
let client = S3Client(
    region: "eu-west-3",
    credentials: StaticCredential(
        accessKeyId: "1234",
        secretAccessKey: "abcd"
    )
)

// S3-compatible
let client = S3Client(
    endpoint: "https://s3.compatible.service.com",
    credentials: StaticCredential(
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

 ```Swift
dependencies: [
    .package(url: "https://github.com/DennisDreissen/S3Kit.git", .upToNextMajor(from: "1.0.0"))
]
 ```

## Usage

### Head bucket

Check if a bucket exists and you're allowed to access it.

 ```Swift
try await client.headBucket(bucket: "bucket")
 ```
 
### Head object

Get metadata information about an object.

 ```Swift
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
let data = try await client.putObject(
    data: Data(),
    bucket: "bucket",
    key: "example.jpg",
    contentType: "image/jpeg"
 )
```

Add an object to a bucket using streamed data. Optionally a part size can be provided. The default part size is 5MB, for most providers this is the minimum allowed size except for the last part. The optional progress handler is called after uploading each part and contains the current total uploaded bytes.

```swift
let data = try await client.putObjectMultipart(
    stream: AsyncThrowingStream(),
    bucket: "bucket",
    key: "example.jpg",
    partSize: 5 * 1024 * 1024,
    contentType: "image/jpeg"
) { totalBytesUploaded in

}
```

### Delete object

```swift
let data = try await client.deleteObject(
    bucket: "bucket",
    key: "example.jpg"
 )
```

## Acknowledgements

The AWS Signature V4 signing implementation is based on code from [soto-core](https://github.com/soto-project/soto-core) by the Soto project authors, licensed under [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0).
