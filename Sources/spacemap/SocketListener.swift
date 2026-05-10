import Foundation

final class SocketListener {
    private let socketPath: String
    private let onEvent: () -> Void
    private var serverFd: Int32 = -1
    private var source: DispatchSourceRead?

    init(socketPath: String, onEvent: @escaping () -> Void) {
        self.socketPath = socketPath
        self.onEvent = onEvent
        start()
    }

    private func start() {
        unlink(socketPath)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return }

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
        guard bound == 0, listen(fd, 8) == 0 else { close(fd); return }

        serverFd = fd
        let src = DispatchSource.makeReadSource(fileDescriptor: fd, queue: .global())
        src.setEventHandler { [weak self] in self?.accept() }
        src.resume()
        source = src
    }

    private func accept() {
        let clientFd = Darwin.accept(serverFd, nil, nil)
        guard clientFd >= 0 else { return }
        var buf = [UInt8](repeating: 0, count: 4)
        read(clientFd, &buf, buf.count)
        close(clientFd)
        DispatchQueue.main.async { self.onEvent() }
    }

    func stop() {
        source?.cancel()
        source = nil
        if serverFd >= 0 { close(serverFd); serverFd = -1 }
        unlink(socketPath)
    }

    deinit { stop() }
}
