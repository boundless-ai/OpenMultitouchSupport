# OpenMultitouchSupport
This enables you easily to observe global multitouch events on the trackpad (Built-In only).  
I created this framework to make MultitouchSupport.framework (Private Framework) easy to use.  
This framework refers to [M5MultitouchSupport.framework](https://github.com/mhuusko5/M5MultitouchSupport) very much.

## References
- [natevw / TouchSynthesis](https://github.com/calftrail/Touch/blob/master/TouchSynthesis/MultitouchSupport.h)
- [asmagill / hammerspoon_asm.undocumented](https://github.com/asmagill/hammerspoon_asm.undocumented/blob/master/touchdevice/MultitouchSupport.h)

## Usage (Swift)

- Prepare manager

```swift
import OpenMultitouchSupport

let manager = OpenMTManager.shared()
```

- Register listener

```swift
let listener = manager?.addListener(withTarget: self, selector: #selector(process))

@objc func process(_ event: OpenMTEvent) {
	guard let touches = event.touches as NSArray as? [OpenMTTouch] else { return }
	// ・・・
}
```

- Remove listener

```swift
manager?.remove(listener)
```

- Toggle listening

```swift
listener.listening = [true / false]
```

- The data you can get are as follows:

```swift
OpenMTTouch
.posX // Float
.posY // Float
.angle // Float
.majorAxis // Float
.minorAxis // Float
.velX // Float
.velY // Float
.size // Float
.density // Float
.state // OpenMTState

OpenMTState
.notTouching
.starting
.hovering
.making
.touching
.breaking
.lingering
.leaving
```