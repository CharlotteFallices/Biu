//
//  SessionX.swift
//  Biu
//
//  Created by 朱禹杭 on 2020/3/13.
//  Copyright © 2020 Akizuki Hiyako. All rights reserved.
//

// swiftlint:disable identifier_name

// swiftlint:disable file_length

import Foundation

open class SessionX {
/// Shared singleton instance used by all `AF.request` APIs. Cannot be modified.
public static let `default` = SessionX()

/// Underlying `URLSession` used to create `URLSessionTasks` for this instance, and for which this instance's
/// `delegate` handles `URLSessionDelegate` callbacks.
public let session: URLSession
/// Instance's `SessionDelegate`, which handles the `URLSessionDelegate` methods and `Request` interaction.
public let delegate: SessionDelegate
/// Root `DispatchQueue` for all internal callbacks and state update. **MUST** be a serial queue.
public let rootQueue: DispatchQueue
/// Value determining whether this instance automatically calls `resume()` on all created `Request`s.
public let startRequestsImmediately: Bool
/// `DispatchQueue` on which `URLRequest`s are created asynchronously. By default this queue uses `rootQueue` as its
/// `target`, but a separate queue can be used if request creation is determined to be a bottleneck. Always profile
/// and test before introducing an additional queue.
public let requestQueue: DispatchQueue
/// `DispatchQueue` passed to all `Request`s on which they perform their response serialization. By default this
/// queue uses `rootQueue` as its `target` but a separate queue can be used if response serialization is determined
/// to be a bottleneck. Always profile and test before introducing an additional queue.
public let serializationQueue: DispatchQueue
/// `RequestInterceptor` used for all `Request` created by the instance. `RequestInterceptor`s can also be set on a
/// per-`Request` basis, in which case the `Request`'s interceptor takes precedence over this value.
public let interceptor: RequestInterceptor?
/// `ServerTrustManager` instance used to evaluate all trust challenges and provide certificate and key pinning.
public let serverTrustManager: ServerTrustManager?
/// `RedirectHandler` instance used to provide customization for request redirection.
public let redirectHandler: RedirectHandler?
/// `CachedResponseHandler` instance used to provide customization of cached response handling.
public let cachedResponseHandler: CachedResponseHandler?
/// `CompositeEventMonitor` used to compose Alamofire's `defaultEventMonitors` and any passed `EventMonitor`s.
public let eventMonitor: CompositeEventMonitor
/// `EventMonitor`s included in all instances. `[AlamofireNotifications()]` by default.
public let defaultEventMonitors: [EventMonitor] = [AlamofireNotifications()]

/// Internal map between `Request`s and any `URLSessionTasks` that may be in flight for them.
var requestTaskMap = RequestTaskMap()
/// Set of currently active `Request`s.
var activeRequests: Set<Request> = []

/// Creates a `Session` from a `URLSession` and other parameters.
///
/// - Note: When passing a `URLSession`, you must create the `URLSession` with a specific `delegateQueue` value and
///         pass the `delegateQueue`'s `underlyingQueue` as the `rootQueue` parameter of this initializer.
///
/// - Parameters:
///   - session:                  Underlying `URLSession` for this instance.
///   - delegate:                 `SessionDelegate` that handles `session`'s delegate callbacks as well as `Request`
///                               interaction.
///   - rootQueue:                Root `DispatchQueue` for all internal callbacks and state updates. **MUST** be a
///                               serial queue.
///   - startRequestsImmediately: Determines whether this instance will automatically start all `Request`s. `true`
///                               by default. If set to `false`, all `Request`s created must have `.resume()` called.
///                               on them for them to start.
///   - requestQueue:             `DispatchQueue` on which to perform `URLRequest` creation. By default this queue
///                               will use the `rootQueue` as its `target`. A separate queue can be used if it's
///                               determined request creation is a bottleneck, but that should only be done after
///                               careful testing and profiling. `nil` by default.
///   - serializationQueue:       `DispatchQueue` on which to perform all response serialization. By default this
///                               queue will use the `rootQueue` as its `target`. A separate queue can be used if
///                               it's determined response serialization is a bottleneck, but that should only be
///                               done after careful testing and profiling. `nil` by default.
///   - interceptor:              `RequestInterceptor` to be used for all `Request`s created by this instance. `nil`
///                               by default.
///   - serverTrustManager:       `ServerTrustManager` to be used for all trust evaluations by this instance. `nil`
///                               by default.
///   - redirectHandler:          `RedirectHandler` to be used by all `Request`s created by this instance. `nil` by
///                               default.
///   - cachedResponseHandler:    `CachedResponseHandler` to be used by all `Request`s created by this instance.
///                               `nil` by default.
///   - eventMonitors:            Additional `EventMonitor`s used by the instance. Alamofire always adds a
///                               `AlamofireNotifications` `EventMonitor` to the array passed here. `[]` by default.
public init(session: URLSession,
            delegate: SessionDelegate,
            rootQueue: DispatchQueue,
            startRequestsImmediately: Bool = true,
            requestQueue: DispatchQueue? = nil,
            serializationQueue: DispatchQueue? = nil,
            interceptor: RequestInterceptor? = nil,
            serverTrustManager: ServerTrustManager? = nil,
            redirectHandler: RedirectHandler? = nil,
            cachedResponseHandler: CachedResponseHandler? = nil,
            eventMonitors: [EventMonitor] = []) {
    precondition(session.configuration.identifier == nil,
                 "Alamofire does not support background URLSessionConfigurations.")
    precondition(session.delegateQueue.underlyingQueue === rootQueue,
                 "Session(session:) initializer must be passed the DispatchQueue used as the delegateQueue's underlyingQueue as rootQueue.")

    self.session = session
    self.delegate = delegate
    self.rootQueue = rootQueue
    self.startRequestsImmediately = startRequestsImmediately
    self.requestQueue = requestQueue ?? DispatchQueue(label: "\(rootQueue.label).requestQueue", target: rootQueue)
    self.serializationQueue = serializationQueue ?? DispatchQueue(label: "\(rootQueue.label).serializationQueue", target: rootQueue)
    self.interceptor = interceptor
    self.serverTrustManager = serverTrustManager
    self.redirectHandler = redirectHandler
    self.cachedResponseHandler = cachedResponseHandler
    eventMonitor = CompositeEventMonitor(monitors: defaultEventMonitors + eventMonitors)
    delegate.eventMonitor = eventMonitor
    delegate.stateProvider = self
}

/// Creates a `Session` from a `URLSessionConfiguration`.
///
/// - Note: This initializer lets Alamofire handle the creation of the underlying `URLSession` and its
///         `delegateQueue`, and is the recommended initializer for most uses.
///
/// - Parameters:
///   - configuration:            `URLSessionConfiguration` to be used to create the underlying `URLSession`. Changes
///                               to this value after being passed to this initializer will have no effect.
///                               `URLSessionConfiguration.af.default` by default.
///   - delegate:                 `SessionDelegate` that handles `session`'s delegate callbacks as well as `Request`
///                               interaction. `SessionDelegate()` by default.
///   - rootQueue:                Root `DispatchQueue` for all internal callbacks and state updates. **MUST** be a
///                               serial queue. `DispatchQueue(label: "org.alamofire.session.rootQueue")` by default.
///   - startRequestsImmediately: Determines whether this instance will automatically start all `Request`s. `true`
///                               by default. If set to `false`, all `Request`s created must have `.resume()` called.
///                               on them for them to start.
///   - requestQueue:             `DispatchQueue` on which to perform `URLRequest` creation. By default this queue
///                               will use the `rootQueue` as its `target`. A separate queue can be used if it's
///                               determined request creation is a bottleneck, but that should only be done after
///                               careful testing and profiling. `nil` by default.
///   - serializationQueue:       `DispatchQueue` on which to perform all response serialization. By default this
///                               queue will use the `rootQueue` as its `target`. A separate queue can be used if
///                               it's determined response serialization is a bottleneck, but that should only be
///                               done after careful testing and profiling. `nil` by default.
///   - interceptor:              `RequestInterceptor` to be used for all `Request`s created by this instance. `nil`
///                               by default.
///   - serverTrustManager:       `ServerTrustManager` to be used for all trust evaluations by this instance. `nil`
///                               by default.
///   - redirectHandler:          `RedirectHandler` to be used by all `Request`s created by this instance. `nil` by
///                               default.
///   - cachedResponseHandler:    `CachedResponseHandler` to be used by all `Request`s created by this instance.
///                               `nil` by default.
///   - eventMonitors:            Additional `EventMonitor`s used by the instance. Alamofire always adds a
///                               `AlamofireNotifications` `EventMonitor` to the array passed here. `[]` by default.
public convenience init(configuration: URLSessionConfiguration = URLSessionConfiguration.af.default,
                        delegate: SessionDelegate = SessionDelegate(),
                        rootQueue: DispatchQueue = DispatchQueue(label: "org.alamofire.session.rootQueue"),
                        startRequestsImmediately: Bool = true,
                        requestQueue: DispatchQueue? = nil,
                        serializationQueue: DispatchQueue? = nil,
                        interceptor: RequestInterceptor? = nil,
                        serverTrustManager: ServerTrustManager? = nil,
                        redirectHandler: RedirectHandler? = nil,
                        cachedResponseHandler: CachedResponseHandler? = nil,
                        eventMonitors: [EventMonitor] = []) {
    precondition(configuration.identifier == nil, "Alamofire does not support background URLSessionConfigurations.")

    let delegateQueue = OperationQueue(maxConcurrentOperationCount: 1, underlyingQueue: rootQueue, name: "org.alamofire.session.sessionDelegateQueue")
    let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)

    self.init(session: session,
              delegate: delegate,
              rootQueue: rootQueue,
              startRequestsImmediately: startRequestsImmediately,
              requestQueue: requestQueue,
              serializationQueue: serializationQueue,
              interceptor: interceptor,
              serverTrustManager: serverTrustManager,
              redirectHandler: redirectHandler,
              cachedResponseHandler: cachedResponseHandler,
              eventMonitors: eventMonitors)
}

deinit {
    finishRequestsForDeinit()
    session.invalidateAndCancel()
}
}
