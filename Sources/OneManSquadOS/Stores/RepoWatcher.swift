import CoreServices
import Foundation

/// Thin wrapper around FSEventStreamRef.
/// Watches a directory tree recursively and fires `onChange` on the main thread.
final class RepoWatcher {
    private var stream: FSEventStreamRef?

    /// - Parameters:
    ///   - path: The root directory to watch (recursively).
    ///   - latency: Seconds to coalesce events before firing. Default 1.0s.
    ///   - onChange: Called on the main thread whenever the filesystem changes.
    init(path: String, latency: TimeInterval = 1.0, onChange: @escaping () -> Void) {
        let box = Unmanaged.passRetained(CallbackBox(onChange))

        var ctx = FSEventStreamContext(
            version: 0,
            info: box.toOpaque(),
            retain: nil,
            release: { ptr in
                guard let ptr else { return }
                Unmanaged<CallbackBox>.fromOpaque(ptr).release()
            },
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let b = Unmanaged<CallbackBox>.fromOpaque(info).takeUnretainedValue()
            // Already on main thread (scheduled on CFRunLoopGetMain).
            b.fire()
        }

        stream = FSEventStreamCreate(
            nil,
            callback,
            &ctx,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
        )

        guard let stream else { return }
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
    }

    deinit {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream) // triggers ctx.release → Unmanaged.release()
    }
}

// MARK: - Private helpers

/// Box to carry a Swift closure through the FSEvents C API via an opaque pointer.
private final class CallbackBox {
    private let fn: () -> Void
    init(_ fn: @escaping () -> Void) { self.fn = fn }
    func fire() { fn() }
}
