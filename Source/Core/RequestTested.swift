//
//  RequestTested.swift
//  Biu
//
//  Created by 朱禹杭 on 2020/3/13.
//  Copyright © 2020 Akizuki Hiyako. All rights reserved.
//

// swiftlint:disable identifier_name

// swiftlint:disable force_try

//Made for RequestTests.swift
//Fuck the KingfisherSwiftUI

import Foundation
import Alamofire
import Foundation

public func tr_testRequestResponse() {
    // Given
    let urlString = "https://httpbin.org/get"
    let expectation = self.expectation(description: "GET request should succeed: \(urlString)")
    var response: DataResponse<Data?, AFError>?

    // When
    AF.request(urlString, parameters: ["foo": "bar"])
        .response { resp in
            response = resp
            expectation.fulfill()
        }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertNotNil(response?.request)
    XCTAssertNotNil(response?.response)
    XCTAssertNotNil(response?.data)
    XCTAssertNil(response?.error)
}

public func tr_testRequestResponseWithProgress() {
    // Given
    let randomBytes = 1 * 25 * 1024
    let urlString = "https://httpbin.org/bytes/\(randomBytes)"

    let expectation = self.expectation(description: "Bytes download progress should be reported: \(urlString)")

    var progressValues: [Double] = []
    var response: DataResponse<Data?, AFError>?

    // When
    AF.request(urlString)
        .downloadProgress { progress in
            progressValues.append(progress.fractionCompleted)
        }
        .response { resp in
            response = resp
            expectation.fulfill()
        }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertNotNil(response?.request)
    XCTAssertNotNil(response?.response)
    XCTAssertNotNil(response?.data)
    XCTAssertNil(response?.error)

    var previousProgress: Double = progressValues.first ?? 0.0

    for progress in progressValues {
        XCTAssertGreaterThanOrEqual(progress, previousProgress)
        previousProgress = progress
    }

    if let lastProgressValue = progressValues.last {
        XCTAssertEqual(lastProgressValue, 1.0)
    } else {
        XCTFail("last item in progressValues should not be nil")
    }
}

public func tr_testPOSTRequestWithUnicodeParameters() {
    // Given
    let urlString = "https://httpbin.org/post"
    let parameters = ["french": "français",
                      "japanese": "日本語",
                      "arabic": "العربية",
                      "emoji": "😃"]

    let expectation = self.expectation(description: "request should succeed")

    var response: DataResponse<Any, AFError>?

    // When
    AF.request(urlString, method: .post, parameters: parameters)
        .responseJSON { closureResponse in
            response = closureResponse
            expectation.fulfill()
        }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertNotNil(response?.request)
    XCTAssertNotNil(response?.response)
    XCTAssertNotNil(response?.data)

    if let json = response?.result.success as? [String: Any], let form = json["form"] as? [String: String] {
        XCTAssertEqual(form["french"], parameters["french"])
        XCTAssertEqual(form["japanese"], parameters["japanese"])
        XCTAssertEqual(form["arabic"], parameters["arabic"])
        XCTAssertEqual(form["emoji"], parameters["emoji"])
    } else {
        XCTFail("form parameter in JSON should not be nil")
    }
}

public func tr_testPOSTRequestWithBase64EncodedImages() {
    // Given
    let urlString = "https://httpbin.org/post"

    let pngBase64EncodedString: String = {
        let URL = url(forResource: "unicorn", withExtension: "png")
        let data = try! Data(contentsOf: URL)

        return data.base64EncodedString(options: .lineLength64Characters)
    }()

    let jpegBase64EncodedString: String = {
        let URL = url(forResource: "rainbow", withExtension: "jpg")
        let data = try! Data(contentsOf: URL)

        return data.base64EncodedString(options: .lineLength64Characters)
    }()

    let parameters = ["email": "user@alamofire.org",
                      "png_image": pngBase64EncodedString,
                      "jpeg_image": jpegBase64EncodedString]

    let expectation = self.expectation(description: "request should succeed")

    var response: DataResponse<Any, AFError>?

    // When
    AF.request(urlString, method: .post, parameters: parameters)
        .responseJSON { closureResponse in
            response = closureResponse
            expectation.fulfill()
        }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertNotNil(response?.request)
    XCTAssertNotNil(response?.response)
    XCTAssertNotNil(response?.data)
    XCTAssertEqual(response?.result.isSuccess, true)

    if let json = response?.result.success as? [String: Any], let form = json["form"] as? [String: String] {
        XCTAssertEqual(form["email"], parameters["email"])
        XCTAssertEqual(form["png_image"], parameters["png_image"])
        XCTAssertEqual(form["jpeg_image"], parameters["jpeg_image"])
    } else {
        XCTFail("form parameter in JSON should not be nil")
    }
}

// MARK: Queues

public func tr_testThatResponseSerializationWorksWithSerializationQueue() {
    // Given
    let queue = DispatchQueue(label: "org.alamofire.testSerializationQueue")
    let manager = Session(serializationQueue: queue)
    let expectation = self.expectation(description: "request should complete")
    var response: DataResponse<Any, AFError>?

    // When
    manager.request("https://httpbin.org/get").responseJSON { resp in
        response = resp
        expectation.fulfill()
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(response?.result.isSuccess, true)
}

public func tr_testThatRequestsWorksWithRequestAndSerializationQueue() {
    // Given
    let requestQueue = DispatchQueue(label: "org.alamofire.testRequestQueue")
    let serializationQueue = DispatchQueue(label: "org.alamofire.testSerializationQueue")
    let manager = Session(requestQueue: requestQueue, serializationQueue: serializationQueue)
    let expectation = self.expectation(description: "request should complete")
    var response: DataResponse<Any, AFError>?

    // When
    manager.request("https://httpbin.org/get").responseJSON { resp in
        response = resp
        expectation.fulfill()
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(response?.result.isSuccess, true)
}

// MARK: Encodable Parameters

public func tr_testThatRequestsCanPassEncodableParametersAsJSONBodyData() {
    // Given
    let parameters = HTTPBinParameters(property: "one")
    let expect = expectation(description: "request should complete")
    var receivedResponse: DataResponse<HTTPBinResponse, AFError>?

    // When
    AF.request("https://httpbin.org/post", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
        .responseDecodable(of: HTTPBinResponse.self) { response in
            receivedResponse = response
            expect.fulfill()
        }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(receivedResponse?.result.success?.data, "{\"property\":\"one\"}")
}

public func tr_testThatRequestsCanPassEncodableParametersAsAURLQuery() {
    // Given
    let parameters = HTTPBinParameters(property: "one")
    let expect = expectation(description: "request should complete")
    var receivedResponse: DataResponse<HTTPBinResponse, AFError>?

    // When
    AF.request("https://httpbin.org/get", method: .get, parameters: parameters)
        .responseDecodable(of: HTTPBinResponse.self) { response in
            receivedResponse = response
            expect.fulfill()
        }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(receivedResponse?.result.success?.args, ["property": "one"])
}

public func tr_testThatRequestsCanPassEncodableParametersAsURLEncodedBodyData() {
    // Given
    let parameters = HTTPBinParameters(property: "one")
    let expect = expectation(description: "request should complete")
    var receivedResponse: DataResponse<HTTPBinResponse, AFError>?

    // When
    AF.request("https://httpbin.org/post", method: .post, parameters: parameters)
        .responseDecodable(of: HTTPBinResponse.self) { response in
            receivedResponse = response
            expect.fulfill()
        }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(receivedResponse?.result.success?.form, ["property": "one"])
}

// MARK: Lifetime Events

public func tr_testThatAutomaticallyResumedRequestReceivesAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(eventMonitors: [eventMonitor])

    let expect = expectation(description: "request should receive appropriate lifetime events")
    expect.expectedFulfillmentCount = 4

    eventMonitor.requestDidResumeTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidResume = { _ in expect.fulfill() }
    eventMonitor.requestDidFinish = { _ in expect.fulfill() }
    // Fulfill other events that would exceed the expected count. Inverted expectations require the full timeout.
    eventMonitor.requestDidSuspend = { _ in expect.fulfill() }
    eventMonitor.requestDidSuspendTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidCancel = { _ in expect.fulfill() }
    eventMonitor.requestDidCancelTask = { _, _ in expect.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest()).response { _ in expect.fulfill() }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .finished)
}

public func tr_testThatAutomaticallyAndManuallyResumedRequestReceivesAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(eventMonitors: [eventMonitor])

    let expect = expectation(description: "request should receive appropriate lifetime events")
    expect.expectedFulfillmentCount = 3

    eventMonitor.requestDidResumeTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidResume = { _ in expect.fulfill() }
    eventMonitor.requestDidFinish = { _ in expect.fulfill() }
    // Fulfill other events that would exceed the expected count. Inverted expectations require the full timeout.
    eventMonitor.requestDidSuspend = { _ in expect.fulfill() }
    eventMonitor.requestDidSuspendTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidCancel = { _ in expect.fulfill() }
    eventMonitor.requestDidCancelTask = { _, _ in expect.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest())
    for _ in 0..<100 {
        request.resume()
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .finished)
}

public func tr_testThatManuallyResumedRequestReceivesAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(startRequestsImmediately: false, eventMonitors: [eventMonitor])

    let expect = expectation(description: "request should receive appropriate lifetime events")
    expect.expectedFulfillmentCount = 3

    eventMonitor.requestDidResumeTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidResume = { _ in expect.fulfill() }
    eventMonitor.requestDidFinish = { _ in expect.fulfill() }
    // Fulfill other events that would exceed the expected count. Inverted expectations require the full timeout.
    eventMonitor.requestDidSuspend = { _ in expect.fulfill() }
    eventMonitor.requestDidSuspendTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidCancel = { _ in expect.fulfill() }
    eventMonitor.requestDidCancelTask = { _, _ in expect.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest())
    for _ in 0..<100 {
        request.resume()
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .finished)
}

public func tr_testThatRequestManuallyResumedManyTimesOnlyReceivesAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(startRequestsImmediately: false, eventMonitors: [eventMonitor])

    let expect = expectation(description: "request should receive appropriate lifetime events")
    expect.expectedFulfillmentCount = 3

    eventMonitor.requestDidResumeTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidResume = { _ in expect.fulfill() }
    eventMonitor.requestDidFinish = { _ in expect.fulfill() }
    // Fulfill other events that would exceed the expected count. Inverted expectations require the full timeout.
    eventMonitor.requestDidSuspend = { _ in expect.fulfill() }
    eventMonitor.requestDidSuspendTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidCancel = { _ in expect.fulfill() }
    eventMonitor.requestDidCancelTask = { _, _ in expect.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest())
    for _ in 0..<100 {
        request.resume()
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .finished)
}

public func tr_testThatRequestManuallySuspendedManyTimesAfterAutomaticResumeOnlyReceivesAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(startRequestsImmediately: false, eventMonitors: [eventMonitor])

    let expect = expectation(description: "request should receive appropriate lifetime events")
    expect.expectedFulfillmentCount = 2

    eventMonitor.requestDidSuspendTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidSuspend = { _ in expect.fulfill() }
    // Fulfill other events that would exceed the expected count. Inverted expectations require the full timeout.
    eventMonitor.requestDidCancel = { _ in expect.fulfill() }
    eventMonitor.requestDidCancelTask = { _, _ in expect.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest())
    for _ in 0..<100 {
        request.suspend()
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .suspended)
}

public func tr_testThatRequestManuallySuspendedManyTimesOnlyReceivesAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(startRequestsImmediately: false, eventMonitors: [eventMonitor])

    let expect = expectation(description: "request should receive appropriate lifetime events")
    expect.expectedFulfillmentCount = 2

    eventMonitor.requestDidSuspendTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidSuspend = { _ in expect.fulfill() }
    // Fulfill other events that would exceed the expected count. Inverted expectations require the full timeout.
    eventMonitor.requestDidResume = { _ in expect.fulfill() }
    eventMonitor.requestDidResumeTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidCancel = { _ in expect.fulfill() }
    eventMonitor.requestDidCancelTask = { _, _ in expect.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest())
    for _ in 0..<100 {
        request.suspend()
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .suspended)
}

public func tr_testThatRequestManuallyCancelledManyTimesAfterAutomaticResumeOnlyReceivesAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(eventMonitors: [eventMonitor])

    let expect = expectation(description: "request should receive appropriate lifetime events")
    expect.expectedFulfillmentCount = 2

    eventMonitor.requestDidCancelTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidCancel = { _ in expect.fulfill() }
    // Fulfill other events that would exceed the expected count. Inverted expectations require the full timeout.
    eventMonitor.requestDidSuspend = { _ in expect.fulfill() }
    eventMonitor.requestDidSuspendTask = { _, _ in expect.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest())
    // Cancellation stops task creation, so don't cancel the request until the task has been created.
    eventMonitor.requestDidCreateTask = { _, _ in
        for _ in 0..<100 {
            request.cancel()
        }
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .cancelled)
}

public func tr_testThatRequestManuallyCancelledManyTimesOnlyReceivesAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(startRequestsImmediately: false, eventMonitors: [eventMonitor])

    let expect = expectation(description: "request should receive appropriate lifetime events")
    expect.expectedFulfillmentCount = 2

    eventMonitor.requestDidCancelTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidCancel = { _ in expect.fulfill() }
    // Fulfill other events that would exceed the expected count. Inverted expectations require the full timeout.
    eventMonitor.requestDidResume = { _ in expect.fulfill() }
    eventMonitor.requestDidResumeTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidSuspend = { _ in expect.fulfill() }
    eventMonitor.requestDidSuspendTask = { _, _ in expect.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest())
    // Cancellation stops task creation, so don't cancel the request until the task has been created.
    eventMonitor.requestDidCreateTask = { _, _ in
        for _ in 0..<100 {
            request.cancel()
        }
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .cancelled)
}

public func tr_testThatRequestManuallyCancelledManyTimesOnManyQueuesOnlyReceivesAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(eventMonitors: [eventMonitor])

    let expect = expectation(description: "request should receive appropriate lifetime events")
    expect.expectedFulfillmentCount = 6

    eventMonitor.requestDidCancelTask = { _, _ in expect.fulfill() }
    eventMonitor.requestDidCancel = { _ in expect.fulfill() }
    eventMonitor.requestDidResume = { _ in expect.fulfill() }
    eventMonitor.requestDidResumeTask = { _, _ in expect.fulfill() }
    // Fulfill other events that would exceed the expected count. Inverted expectations require the full timeout.
    eventMonitor.requestDidSuspend = { _ in expect.fulfill() }
    eventMonitor.requestDidSuspendTask = { _, _ in expect.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest(path: "delay/5")).response { _ in expect.fulfill() }
    // Cancellation stops task creation, so don't cancel the request until the task has been created.
    eventMonitor.requestDidCreateTask = { _, _ in
        DispatchQueue.concurrentPerform(iterations: 100) { i in
            request.cancel()

            if i == 99 { expect.fulfill() }
        }
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .cancelled)
}

public func tr_testThatRequestTriggersAllAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(eventMonitors: [eventMonitor])

    let didReceiveChallenge = expectation(description: "didReceiveChallenge should fire")
    let taskDidFinishCollecting = expectation(description: "taskDidFinishCollecting should fire")
    let didReceiveData = expectation(description: "didReceiveData should fire")
    let willCacheResponse = expectation(description: "willCacheResponse should fire")
    let didCreateURLRequest = expectation(description: "didCreateInitialURLRequest should fire")
    let didCreateTask = expectation(description: "didCreateTask should fire")
    let didGatherMetrics = expectation(description: "didGatherMetrics should fire")
    let didComplete = expectation(description: "didComplete should fire")
    let didFinish = expectation(description: "didFinish should fire")
    let didResume = expectation(description: "didResume should fire")
    let didResumeTask = expectation(description: "didResumeTask should fire")
    let didParseResponse = expectation(description: "didParseResponse should fire")
    let responseHandler = expectation(description: "responseHandler should fire")

    var dataReceived = false

    eventMonitor.taskDidReceiveChallenge = { _, _, _ in didReceiveChallenge.fulfill() }
    eventMonitor.taskDidFinishCollectingMetrics = { _, _, _ in taskDidFinishCollecting.fulfill() }
    eventMonitor.dataTaskDidReceiveData = { _, _, _ in
        guard !dataReceived else { return }
        // Data may be received many times, fulfill only once.
        dataReceived = true
        didReceiveData.fulfill()
    }
    eventMonitor.dataTaskWillCacheResponse = { _, _, _ in willCacheResponse.fulfill() }
    eventMonitor.requestDidCreateInitialURLRequest = { _, _ in didCreateURLRequest.fulfill() }
    eventMonitor.requestDidCreateTask = { _, _ in didCreateTask.fulfill() }
    eventMonitor.requestDidGatherMetrics = { _, _ in didGatherMetrics.fulfill() }
    eventMonitor.requestDidCompleteTaskWithError = { _, _, _ in didComplete.fulfill() }
    eventMonitor.requestDidFinish = { _ in didFinish.fulfill() }
    eventMonitor.requestDidResume = { _ in didResume.fulfill() }
    eventMonitor.requestDidResumeTask = { _, _ in didResumeTask.fulfill() }
    eventMonitor.requestDidParseResponse = { _, _ in didParseResponse.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest()).response { _ in
        responseHandler.fulfill()
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .finished)
}

public func tr_testThatCancelledRequestTriggersAllAppropriateLifetimeEvents() {
    // Given
    let eventMonitor = ClosureEventMonitor()
    let session = Session(startRequestsImmediately: false, eventMonitors: [eventMonitor])

    let taskDidFinishCollecting = expectation(description: "taskDidFinishCollecting should fire")
    let didCreateURLRequest = expectation(description: "didCreateInitialURLRequest should fire")
    let didCreateTask = expectation(description: "didCreateTask should fire")
    let didGatherMetrics = expectation(description: "didGatherMetrics should fire")
    let didComplete = expectation(description: "didComplete should fire")
    let didFinish = expectation(description: "didFinish should fire")
    let didResume = expectation(description: "didResume should fire")
    let didResumeTask = expectation(description: "didResumeTask should fire")
    let didParseResponse = expectation(description: "didParseResponse should fire")
    let didCancel = expectation(description: "didCancel should fire")
    let didCancelTask = expectation(description: "didCancelTask should fire")
    let responseHandler = expectation(description: "responseHandler should fire")

    eventMonitor.taskDidFinishCollectingMetrics = { _, _, _ in taskDidFinishCollecting.fulfill() }
    eventMonitor.requestDidCreateInitialURLRequest = { _, _ in didCreateURLRequest.fulfill() }
    eventMonitor.requestDidCreateTask = { _, _ in didCreateTask.fulfill() }
    eventMonitor.requestDidGatherMetrics = { _, _ in didGatherMetrics.fulfill() }
    eventMonitor.requestDidCompleteTaskWithError = { _, _, _ in didComplete.fulfill() }
    eventMonitor.requestDidFinish = { _ in didFinish.fulfill() }
    eventMonitor.requestDidResume = { _ in didResume.fulfill() }
    eventMonitor.requestDidParseResponse = { _, _ in didParseResponse.fulfill() }
    eventMonitor.requestDidCancel = { _ in didCancel.fulfill() }
    eventMonitor.requestDidCancelTask = { _, _ in didCancelTask.fulfill() }

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest(path: "delay/5")).response { _ in
        responseHandler.fulfill()
    }

    eventMonitor.requestDidResumeTask = { _, _ in
        request.cancel()
        didResumeTask.fulfill()
    }

    request.resume()

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(request.state, .cancelled)
}

public func tr_testThatAppendingResponseSerializerToCancelledRequestCallsCompletion() {
    // Given
    let session = Session()

    var response1: DataResponse<Any, AFError>?
    var response2: DataResponse<Any, AFError>?

    let expect = expectation(description: "both response serializer completions should be called")
    expect.expectedFulfillmentCount = 2

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest())

    request.responseJSON { resp in
        response1 = resp
        expect.fulfill()

        request.responseJSON { resp in
            response2 = resp
            expect.fulfill()
        }
    }

    request.cancel()

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertEqual(response1?.error?.isExplicitlyCancelledError, true)
    XCTAssertEqual(response2?.error?.isExplicitlyCancelledError, true)
}

public func tr_testThatAppendingResponseSerializerToCompletedRequestInsideCompletionResumesRequest() {
    // Given
    let session = Session()

    var response1: DataResponse<Any, AFError>?
    var response2: DataResponse<Any, AFError>?
    var response3: DataResponse<Any, AFError>?

    let expect = expectation(description: "all response serializer completions should be called")
    expect.expectedFulfillmentCount = 3

    // When
    let request = session.request(URLRequest.makeHTTPBinRequest())

    request.responseJSON { resp in
        response1 = resp
        expect.fulfill()

        request.responseJSON { resp in
            response2 = resp
            expect.fulfill()

            request.responseJSON { resp in
                response3 = resp
                expect.fulfill()
            }
        }
    }

    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertNotNil(response1?.value)
    XCTAssertNotNil(response2?.value)
    XCTAssertNotNil(response3?.value)
}

public func tr_testThatAppendingResponseSerializerToCompletedRequestOutsideCompletionResumesRequest() {
    // Given
    let session = Session()
    let request = session.request(URLRequest.makeHTTPBinRequest())

    var response1: DataResponse<Any, AFError>?
    var response2: DataResponse<Any, AFError>?
    var response3: DataResponse<Any, AFError>?

    // When
    let expect1 = expectation(description: "response serializer 1 completion should be called")
    request.responseJSON { response1 = $0; expect1.fulfill() }
    waitForExpectations(timeout: timeout, handler: nil)

    let expect2 = expectation(description: "response serializer 2 completion should be called")
    request.responseJSON { response2 = $0; expect2.fulfill() }
    waitForExpectations(timeout: timeout, handler: nil)

    let expect3 = expectation(description: "response serializer 3 completion should be called")
    request.responseJSON { response3 = $0; expect3.fulfill() }
    waitForExpectations(timeout: timeout, handler: nil)

    // Then
    XCTAssertNotNil(response1?.value)
    XCTAssertNotNil(response2?.value)
    XCTAssertNotNil(response3?.value)
}
