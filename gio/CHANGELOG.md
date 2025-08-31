## 0.2.0

### New Features
- **File Transfer Support**: Added comprehensive upload and download capabilities
  - `uploadFile()` - Upload files with multipart/form-data format and progress tracking
  - `uploadData()` - Upload raw data as request body with progress tracking
  - `uploadFromStream()` - Upload from stream for large files
  - `downloadFile()` - Download files to disk with progress tracking
  - `downloadBytes()` - Download content to memory with size limits
  - `downloadWithChunkCallback()` - Process download chunks in real-time
  - `downloadToSink()` - Download to custom sink
- **Background JSON Processing**: Added support for background JSON encoding to prevent UI blocking
  - Global `parallelJson` configuration in `GioOption` for request body JSON encoding
  - `jsonBody` parameter for clean JSON object handling
  - `GioJsonCodec` with configurable idle timeout for background isolate management
  - `toJsonAs<T>()` method for parsing JSON responses to typed objects in background isolates
- **Enhanced Progress Tracking**: 
  - `TransferProgress` class with accurate percentage calculation (0.5% threshold)
  - Optimized progress callbacks to prevent duplicate reports
  - High-precision percentage display (2 decimal places)

### Improvements
- **Content-Type Standardization**: Automatic `application/json` header for `jsonBody` requests

### Breaking Changes
- Recommended to use `jsonBody` parameter instead of manual `jsonEncode()` for JSON requests

## 0.1.0
- Upgrade dart to the minimum supported version 3.4
- Remove the http protocol implementation and use package:http

## 0.0.4
- Add tutorial
- Fix interceptor bug
- Request to add queryParameters parameter option

## 0.0.3
- lower the version number

## 0.0.2
- Add support for setting certificate private key.


## 0.0.1

- Initial version.
