import Foundation
import Observation

@MainActor
@Observable
final class ProjectStore {
    private static let defaultsKey = "trackedProjects.v1"

    private(set) var projects: [TrackedProject] = []

    init() { load() }

    func add(_ url: URL) {
        let std = url.standardizedFileURL
        guard !projects.contains(where: { $0.path.standardizedFileURL == std }) else { return }
        projects.append(TrackedProject(path: std))
        save()
    }

    func remove(_ project: TrackedProject) {
        projects.removeAll { $0.id == project.id }
        save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([TrackedProject].self, from: data) {
            projects = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
