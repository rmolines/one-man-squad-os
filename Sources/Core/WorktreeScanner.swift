import Foundation

public struct WorktreeInfo: Sendable {
    public let path: String
    public let branch: String?
    public let isMain: Bool

    public init(path: String, branch: String?, isMain: Bool) {
        self.path = path
        self.branch = branch
        self.isMain = isMain
    }
}

public func listWorktrees(repoPath: String) throws -> [WorktreeInfo] {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    proc.arguments = ["-C", repoPath, "worktree", "list", "--porcelain"]
    proc.environment = ["LANG": "en_US.UTF-8"]

    let pipe = Pipe()
    proc.standardOutput = pipe
    try proc.run()
    proc.waitUntilExit()

    let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    return parseWorktreePorcelain(output)
}

private func parseWorktreePorcelain(_ output: String) -> [WorktreeInfo] {
    var results: [WorktreeInfo] = []
    var path: String?
    var branch: String?
    var isMain = false

    for line in output.components(separatedBy: "\n") {
        if line.hasPrefix("worktree ") {
            if let p = path {
                results.append(WorktreeInfo(path: p, branch: branch, isMain: isMain))
            }
            path = String(line.dropFirst("worktree ".count))
            branch = nil
            isMain = results.isEmpty
        } else if line.hasPrefix("branch ") {
            branch = String(line.dropFirst("branch refs/heads/".count))
        }
    }
    if let p = path {
        results.append(WorktreeInfo(path: p, branch: branch, isMain: isMain))
    }
    return results
}
