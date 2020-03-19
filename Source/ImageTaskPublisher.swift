// The MIT License (MIT)
//
// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).

import Foundation
import Nuke
import Combine

public extension ImagePipeline {
    /// Returns a publisher which starts a new `ImageTask` when a subscriber is added.
    ///
    /// - note: For more information, see `ImageTaskPublisher`.
    func imageTaskPublisher(with url: URL) -> ImageTaskPublisher {
        imageTaskPublisher(with: ImageRequest(url: url))
    }

    /// Returns a publisher which starts a new `ImageTask` when a subscriber is added.
    ///
    /// - note: For more information, see `ImageTaskPublisher`.
    func imageTaskPublisher(with request: ImageRequest) -> ImageTaskPublisher {
        ImageTaskPublisher(request: request, pipeline: self)
    }
}

/// A publisher that starts a new `ImageTask` when a subscriber is added and delivers
/// the result of the task to the subscriber. If the requested image is available
/// in the memory cache, the value is delivered immediately. When the subscription
/// is cancelled, the task also gets cancelled.
///
/// - note: In case the pipeline has `isProgressiveDecodingEnabled` option enabled
/// and the image being downloaded supports progressive decoding, the publisher
/// might emit more than a single value.
public struct ImageTaskPublisher: Publisher {
    public typealias Output = ImageResponse
    public typealias Failure = ImagePipeline.Error

    public let request: ImageRequest
    public let pipeline: ImagePipeline

    public init(request: ImageRequest, pipeline: ImagePipeline) {
        self.request = request
        self.pipeline = pipeline
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = ImageTaskSubscription()
        subscriber.receive(subscription: subscription)

        if let response = pipeline.cachedResponse(for: request) {
            _ = subscriber.receive(response)
            subscriber.receive(completion: .finished)
            return
        }

        subscription.task = pipeline.loadImage(
             with: request,
             queue: nil,
             progress: { response, _, _ in
                 if let response = response {
                    // Send progressively decoded image (if enabled and if any)
                     _ = subscriber.receive(response)
                 }
             },
             completion: { result in
                 switch result {
                 case let .success(response):
                     _ = subscriber.receive(response)
                     subscriber.receive(completion: .finished)
                 case let .failure(error):
                     subscriber.receive(completion: .failure(error))
                 }
             }
         )
    }
}

private final class ImageTaskSubscription: Subscription {
    var task: ImageTask?

    func request(_ demand: Subscribers.Demand) {
        // Ignore the demand
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
