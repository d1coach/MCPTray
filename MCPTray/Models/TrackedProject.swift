import Foundation

struct TrackedProject: Codable, Identifiable, Hashable {
    let id: UUID
    var path: URL
    var displayName: String

    init(id: UUID = UUID(), path: URL, displayName: String? = nil) {
        self.id = id
        self.path = path
        self.displayName = displayName ?? path.lastPathComponent
    }

    var exists: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path.path, isDirectory: &isDir) && isDir.boolValue
    }
}
