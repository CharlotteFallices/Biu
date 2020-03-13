//
//  Uploadable.swift
//  Biu
//
//  Created by 朱禹杭 on 2020/3/13.
//  Copyright © 2020 Akizuki Hiyako. All rights reserved.
//

// swiftlint:disable identifier_name

// swiftlint:disable file_length

import Foundation

open class SessionX{
    func upload(_ uploadable: UploadRequest.Uploadable,
                with convertible: URLRequestConvertible,
                interceptor: RequestInterceptor?,
                fileManager: FileManager) -> UploadRequest {
        let uploadable = Upload(request: convertible, uploadable: uploadable)

        return upload(uploadable, interceptor: interceptor, fileManager: fileManager)
    }

    func upload(_ upload: UploadConvertible, interceptor: RequestInterceptor?, fileManager: FileManager) -> UploadRequest {
        let request = UploadRequest(convertible: upload,
                                    underlyingQueue: rootQueue,
                                    serializationQueue: serializationQueue,
                                    eventMonitor: eventMonitor,
                                    interceptor: interceptor,
                                    fileManager: fileManager,
                                    delegate: self)

        perform(request)

        return request
    }

    // MARK: Perform

    /// Perform `Request`.
    ///
    /// - Note: Called during retry.
    ///
    /// - Parameter request: The `Request` to perform.
    func perform(_ request: Request) {
        switch request {
        case let r as DataRequest: perform(r)
        case let r as UploadRequest: perform(r)
        case let r as DownloadRequest: perform(r)
        default: fatalError("Attempted to perform unsupported Request subclass: \(type(of: request))")
        }
    }

    func perform(_ request: DataRequest) {
        requestQueue.async {
            guard !request.isCancelled else { return }

            self.activeRequests.insert(request)

            self.performSetupOperations(for: request, convertible: request.convertible)
        }
    }

    func perform(_ request: UploadRequest) {
        requestQueue.async {
            guard !request.isCancelled else { return }

            self.activeRequests.insert(request)

            do {
                let uploadable = try request.upload.createUploadable()
                self.rootQueue.async { request.didCreateUploadable(uploadable) }

                self.performSetupOperations(for: request, convertible: request.convertible)
            } catch {
                self.rootQueue.async { request.didFailToCreateUploadable(with: error.asAFError(or: .createUploadableFailed(error: error))) }
            }
        }
    }

    func perform(_ request: DownloadRequest) {
        requestQueue.async {
            guard !request.isCancelled else { return }

            self.activeRequests.insert(request)

            switch request.downloadable {
            case let .request(convertible):
                self.performSetupOperations(for: request, convertible: convertible)
            case let .resumeData(resumeData):
                self.rootQueue.async { self.didReceiveResumeData(resumeData, for: request) }
            }
        }
    }

    func performSetupOperations(for request: Request, convertible: URLRequestConvertible) {
        let initialRequest: URLRequest

        do {
            initialRequest = try convertible.asURLRequest()
            try initialRequest.validate()
        } catch {
            rootQueue.async { request.didFailToCreateURLRequest(with: error.asAFError(or: .createURLRequestFailed(error: error))) }
            return
        }

        rootQueue.async { request.didCreateInitialURLRequest(initialRequest) }

        guard !request.isCancelled else { return }

        guard let adapter = adapter(for: request) else {
            rootQueue.async { self.didCreateURLRequest(initialRequest, for: request) }
            return
        }

        adapter.adapt(initialRequest, for: self) { result in
            do {
                let adaptedRequest = try result.get()
                try adaptedRequest.validate()

                self.rootQueue.async {
                    request.didAdaptInitialRequest(initialRequest, to: adaptedRequest)
                    self.didCreateURLRequest(adaptedRequest, for: request)
                }
            } catch {
                self.rootQueue.async { request.didFailToAdaptURLRequest(initialRequest, withError: .requestAdaptationFailed(error: error)) }
            }
        }
    }
}
