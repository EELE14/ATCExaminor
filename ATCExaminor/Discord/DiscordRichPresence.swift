import Foundation

@Observable
final class DiscordRichPresence {

    enum Status: Equatable {
        case idle
        case connecting
        case connected
        case failed(String)
    }

    static let shared = DiscordRichPresence()


    private(set) var status: Status = .idle


    nonisolated(unsafe) private var activeFD: Int32 = -1
    nonisolated(unsafe) private var nonce: Int = 0
    nonisolated(unsafe) private var isRunning = false

    nonisolated(unsafe) private var lastActivity: [String: Any]? = nil

    private var loopTask: Task<Void, Never>?
    private let clientID = "1494626022270959748"

    private init() {}


    func start() {
        guard UserDefaults.standard.object(forKey: "discordRPCEnabled") as? Bool ?? true else { return }
        isRunning = true
        loopTask?.cancel()
        loopTask = Task.detached(priority: .background) { [weak self] in
            await self?.connectionLoop()
        }
    }

    func stop() {
        isRunning = false
        loopTask?.cancel()
        loopTask = nil
        let fd = activeFD
        if fd >= 0 { Darwin.close(fd); activeFD = -1 }
        Task { @MainActor in self.status = .idle }
    }

    func restart() {
        stop()
        Task.detached(priority: .background) { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            await self?.start()
        }
    }

    // MARK: - Presence

    func update(details: String, state: String? = nil, since: Date? = nil) {
        var activity: [String: Any] = ["details": details]
        if let s = state  { activity["state"] = s }
        if let d = since  { activity["timestamps"] = ["start": Int(d.timeIntervalSince1970)] }
        lastActivity = activity

        let fd = activeFD
        guard fd >= 0 else { return }
        sendActivity(activity, fd: fd)
    }

    func clear() {
        lastActivity = nil
        let fd = activeFD
        guard fd >= 0 else { return }
        sendClear(fd: fd)
    }

    // MARK: - Connection loop

    nonisolated private func connectionLoop() async {
        while isRunning && !Task.isCancelled {
            await MainActor.run { self.status = .connecting }

            if let fd = openSocket() {
                activeFD = fd
                writeFrame(fd: fd, opcode: 0, payload: ["v": 1, "client_id": clientID])

                try? await Task.sleep(nanoseconds: 400_000_000)

                await MainActor.run { self.status = .connected }

                if let activity = lastActivity {
                    sendActivity(activity, fd: fd)
                }

                await readUntilClosed(fd: fd)

                await MainActor.run { self.status = .idle }
                if activeFD == fd { Darwin.close(fd); activeFD = -1 }
            } else {
                await MainActor.run { self.status = .failed("Discord not found. Retrying…") }
            }

            guard isRunning && !Task.isCancelled else { break }
            try? await Task.sleep(nanoseconds: 5_000_000_000)
        }
        await MainActor.run { self.status = .idle }
    }

    // MARK: - Socket helpers

    nonisolated private func openSocket() -> Int32? {
        for dir in socketSearchDirs() {
            for i in 0..<10 {
                if let fd = tryConnect(path: "\(dir)/discord-ipc-\(i)") { return fd }
            }
        }
        return nil
    }

    nonisolated private func socketSearchDirs() -> [String] {
        var candidates: [String] = []

        var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
        if confstr(_CS_DARWIN_USER_TEMP_DIR, &buf, buf.count) > 0 {
            var path = String(cString: buf)
            while path.hasSuffix("/") { path.removeLast() }
            if !path.isEmpty { candidates.append(path) }
        }


        if var envTmp = ProcessInfo.processInfo.environment["TMPDIR"] {
            while envTmp.hasSuffix("/") { envTmp.removeLast() }
            if !envTmp.isEmpty && !candidates.contains(envTmp) { candidates.append(envTmp) }
        }

        print("[DiscordRPC] Searching in: \(candidates)")
        return candidates
    }

    nonisolated private func tryConnect(path: String) -> Int32? {
        let fd = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return nil }

        var addr = sockaddr_un()
        addr.sun_len    = UInt8(MemoryLayout<sockaddr_un>.size)
        addr.sun_family = sa_family_t(AF_UNIX)
        _ = withUnsafeMutableBytes(of: &addr.sun_path) { buf in
            path.withCString { src in
                strlcpy(buf.baseAddress!.assumingMemoryBound(to: CChar.self), src, buf.count)
            }
        }

        let ok = withUnsafePointer(to: addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) == 0
            }
        }

        if ok {
            print("[DiscordRPC] Connected on \(path)")
            return fd
        }
        Darwin.close(fd)
        return nil
    }

    nonisolated private func readUntilClosed(fd: Int32) async {
        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)

        var header = [UInt8](repeating: 0, count: 8)
        while activeFD == fd {
            let n = Darwin.recv(fd, &header, 8, 0)
            if n == 0 { break }
            if n < 0 {
                if errno == EAGAIN || errno == EWOULDBLOCK {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    continue
                }
                break
            }
            guard n == 8 else { break }
            let len = Int(header[4]) | Int(header[5]) << 8 | Int(header[6]) << 16 | Int(header[7]) << 24
            guard len > 0, len <= 65_536 else { break }
            var buf = [UInt8](repeating: 0, count: len)
            _ = Darwin.recv(fd, &buf, len, MSG_WAITALL)
        }
    }

    // MARK: - Frame I/O

    nonisolated private func sendActivity(_ activity: [String: Any], fd: Int32) {
        nonce += 1
        writeFrame(fd: fd, opcode: 1, payload: [
            "cmd": "SET_ACTIVITY",
            "args": [
                "pid": Int(ProcessInfo.processInfo.processIdentifier),
                "activity": activity
            ],
            "nonce": "\(nonce)"
        ])
    }

    nonisolated private func sendClear(fd: Int32) {
        nonce += 1
        writeFrame(fd: fd, opcode: 1, payload: [
            "cmd": "SET_ACTIVITY",
            "args": ["pid": Int(ProcessInfo.processInfo.processIdentifier)],
            "nonce": "\(nonce)"
        ])
    }

    nonisolated private func writeFrame(fd: Int32, opcode: Int32, payload: Any) {
        guard fd >= 0, let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var frame = Data(capacity: 8 + data.count)
        var op  = opcode.littleEndian
        var len = Int32(data.count).littleEndian
        withUnsafeBytes(of: &op)  { frame.append(contentsOf: $0) }
        withUnsafeBytes(of: &len) { frame.append(contentsOf: $0) }
        frame.append(data)
        _ = frame.withUnsafeBytes { Darwin.write(fd, $0.baseAddress!, $0.count) }
    }

    deinit {

        isRunning = false
        loopTask?.cancel()
        let fd = activeFD
        if fd >= 0 { Darwin.close(fd); activeFD = -1 }
    }
}
