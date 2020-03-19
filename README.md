<br/>

<p align="left"><img src="https://cloud.githubusercontent.com/assets/1567433/13918338/f8670eea-ef7f-11e5-814d-f15bdfd6b2c0.png" height="180"/>

# ImageTaskPublisher

`ImageTaskPublisher` is a publisher that wraps [Nuke](https://github.com/kean/Nuke)'s image tasks (`ImageTask`).

> **Note**. This is an API preview. It is not battle-tested yet and might change in the future.

## Overview

`ImageTaskPublisher`  starts a new `ImageTask` when a subscriber is added and delivers the result of the task to the subscriber. If the requested image is available in the memory cache, the value is delivered immediately. When the subscription is cancelled, the task also gets cancelled.

>  In case the pipeline has `isProgressiveDecodingEnabled` option enabled and the image being downloaded supports progressive decoding, the publisher might emit more than a single value.

## Usage

To create `ImageTaskPublisher`, use one of the following APIs added to `ImagePipeline`:

```swift
public extension ImagePipeline {
    func imageTaskPublisher(with url: URL) -> ImageTaskPublisher
    func imageTaskPublisher(with request: ImageRequest) -> ImageTaskPublisher
}
```

Here's a basic example where we load an image and display the result on success:

```swift
cancellable = pipeline.imageTaskPublisher(with: url)
    .sink(receiveCompletion: { _ in /* Ignore errors */ },
          receiveValue: { imageView.image = $0.image })
```

### Going From Low to High Resolution

Let's say you want to show a user a high-resolution image which takes a while to loads. Rather than let them stare a spinner for a while, you might want to quickly download a smaller thumbnail first.

> As an alternative, Nuke also supports progressive JPEG. For more information see `isProgressiveDecodingEnabled` option.

You can implement this using `append` operator. This operator results in a serial execution. It starts a thumbnail request, waits until it finishes, and only then starts a request for a high-resolution image.

```swift
let lowResImage = pipeline.imageTaskPublisher(with: lowResUrl).orEmpty
let highResImage = pipeline.imageTaskPublisher(with: lowResUrl).orEmpty

cancellable = lowResImage.append(highResImage)
    .sink(receiveCompletion: { _ in /* Ignore errors */ },
          receiveValue: { imageView.image = $0.image })
```

> `orEmpty` is a custom property which catches the errors and immediately completes the publishes instead.s
> 
>     extension Publisher {
>        public var orEmpty: AnyPublisher<Output, Never> {
>            self.catch { _ in Empty<Output, Never>() }.eraseToAnyPublisher()
>        }
>    }

### Loading the First Available Image

Let's say you have multiple URLs for the same image. For example, you uploaded the image takes by the camera to the server, and now you have both the image stored locally and the image on the server. In this case, it would be beneficial to first try to get the local URL, and if that fails - let's say you delete the least recent images - try to get the image from the network. It would be a shame to download the image that we may already have stored locally.

This use case is very similar [Going From Low to High Resolution](#going-from-low-to-high-resolution), but addition of `first()` operator that stops the execution as soon as the fist value is received.

```swift
let localImage = pipeline.imageTaskPublisher(with: localUrl).orEmpty
let networkImage = pipeline.imageTaskPublisher(with: networkUrl).orEmpty

cancellable = localImage.append(networkImage)
    .first()
    .sink(receiveCompletion: { _ in /* Ignore errors */ },
          receiveValue: { imageView.image = $0.image })
```

### Load Multiple Images, Display All at Once

Let's say you want to load two icons for a button, one icon for a `.normal` state and one for a `.selected` state. You want to update the button, only when both icons are fully loaded. This can be achieved using a `combine` operator.

```swift
let iconImage = pipeline.imageTaskPublisher(with: iconUrl)
let iconSelectedImage = pipeline.imageTaskPublisher(with: iconSelectedUrl)

cancellable = iconImage.combineLatest(iconSelectedImage)
    .sink(receiveCompletion: { _ in /* Ignore errors */ },
          receiveValue: { icon, iconSelected in
            button.isHidden = false
            button.setImage(icon.image, for: .normal)
            button.setImage(iconSelected.image, for: .selected)
         })
```

> Notice there is no `orEmpty` in this example since we want both requests to succeed.

### Showing Stale Image While Validating It

Let's you want to show the user a stale image stored in disk cache (`Foundation.URLCache`) while you go to the server to validate if the image is still fresh. This can be implemented using the same `append` operator that we covered [previosuly](#going-from-low-to-high-resolution).

```swift
let cacheRequest = URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad)
let networkRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)

let cachedImage = pipeline.imageTaskPublisher(with: ImageRequest(urlRequest: cacheRequest)).orEmpty
let networkImage = pipeline.imageTaskPublisher(with: ImageRequest(urlRequest: networkRequest)).orEmpty

cancellable = cachedImage.append(networkImage)
    .sink(receiveCompletion: { _ in /* Ignore errors */ },
          receiveValue: { imageView.image = $0.image })
```

> See [Image Caching](https://kean.github.io/post/image-caching) to learn more about HTTP cache

# Requirements

| Nuke          | Swift           | Xcode           | Platforms                                         |
|---------------|-----------------|-----------------|---------------------------------------------------|
| ImageTaskPublisher     | Swift 5.1       | Xcode 11.3      | iOS 13.0 / watchOS 6.0 / macOS 10.15 / tvOS 13.0  |

# License

ImageTaskPublisher is available under the MIT license. See the LICENSE file for more info.
