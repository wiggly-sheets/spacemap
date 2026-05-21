import Foundation

final class SocketListener {
    private let socketPath: String
    private let healthInterval: Int
    private let onEvent: () -> Void
    private var serverFd: Int32 = -1
    private var source: DispatchSourceRead?
    private var healthTimer: DispatchSourceTimer?
    private var isStopped = false
    private let listenerQueue = DispatchQueue(label: "com.spacemap.socketlistener")

    init(socketPath: String, healthInterval: Int = 60, onEvent: @escaping () -> Void) {
        self.socketPath = socketPath
        self.healthInterval = healthInterval
        self.onEvent = onEvent
        listenerQueue.async { self.start() }
    }

    private func start() {
        guard !isStopped else { return }
        unlink(socketPath)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            fputs("spacemap/SocketListener: socket() failed\n", stderr)
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = socketPath.utf8CString
        withUnsafeMutableBytes(of: &addr.sun_path) { dest in
            pathBytes.withUnsafeBytes { src in
                dest.copyMemory(from: UnsafeRawBufferPointer(start: src.baseAddress,
                                                              count: min(src.count, dest.count - 1)))
            }
        }

        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bound == 0, listen(fd, 8) == 0 else {
            fputs("spacemap/SocketListener: bind/listen failed\n", stderr)
            close(fd)
            return
        }

        serverFd = fd
        let src = DispatchSource.makeReadSource(fileDescriptor: fd, queue: listenerQueue)
        src.setEventHandler { [weak self] in self?.accept() }
        src.resume()
        source = src

        startHealthTimer()
    }

    private func accept() {
        let clientFd = Darwin.accept(serverFd, nil, nil)
        guard clientFd >= 0 else {
            let err = errno
            fputs("spacemap/SocketListener: accept() failed: \(String(cString: strerror(err))) — restarting\n", stderr)
            scheduleRestart()
            return
        }
        var buf = [UInt8](repeating: 0, count: 4)
        read(clientFd, &buf, buf.count)
        close(clientFd)
        DispatchQueue.main.async { self.onEvent() }
    }

    private func scheduleRestart() {
        guard !isStopped else { return }
        tearDownSocket()
        fputs("spacemap/SocketListener: restarting in 0.5s\n", stderr)
        listenerQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.start() }
    }

    private func tearDownSocket() {
        healthTimer?.cancel(); healthTimer = nil
        source?.cancel(); source = nil
        if serverFd >= 0 { close(serverFd); serverFd = -1 }
        unlink(socketPath)
    }

    private func startHealthTimer() {
        let timer = DispatchSource.makeTimerSource(queue: listenerQueue)
        timer.schedule(deadline: .now() + .seconds(healthInterval), repeating: .seconds(healthInterval))
        timer.setEventHandler { [weak self] in self?.checkHealth() }
        timer.resume()
        healthTimer = timer
    }

    private func checkHealth() {
        let fdValid = serverFd >= 0 && fcntl(serverFd, F_GETFD) != -1
        let fileExists = FileManager.default.fileExists(atPath: socketPath)
        guard fdValid && fileExists else {
            fputs("spacemap/SocketListener: health check failed (fdValid=\(fdValid) fileExists=\(fileExists)) — restarting\n", stderr)
            scheduleRestart()
            return
        }
    }

    func stop() {
        listenerQueue.sync {
            isStopped = true
            tearDownSocket()
        }
    }

    deinit { stop() }
}
