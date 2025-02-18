import AsyncHTTPClient
import CollectionConcurrencyKit
import Fluent
import Vapor

public extension Sequence {
//    func limitedConcurrentForEach(
//        maxConcurrent limit: Int = 30,
//        withPriority priority: TaskPriority? = nil,
//        _ operation: @escaping (Element) async -> Void
//    ) async {
//        var i = 0
//        await withTaskGroup(of: Void.self) { group in
//            for element in self {
//                if i >= limit {
//                    await group.next()
//                }
//                i += 1
//
//                group.addTask(priority: priority) {
//                    await operation(element)
//                }
//            }
//        }
//    }

    func limitedConcurrentForEach(
        maxConcurrent limit: Int = 30,
        withPriority priority: TaskPriority? = nil,
        _ operation: @escaping (Element) async throws -> Void
    ) async rethrows {
        var i = 0
        try await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                if i >= limit {
                    try await group.next()
                }
                i += 1

                group.addTask(priority: priority) {
                    try await operation(element)
                }
            }
        }
    }
}

enum ConLimits {
    static let network = 1000
    static let db = 500
}

class ScanHandler {
    var client: HTTPClient = .init(eventLoopGroupProvider: .createNew)
    let logger: Logger
    let server: String
    let db: Database

    init(_ logger: Logger, url server: String, db: Database) {
        self.logger = logger
        self.server = server
        self.db = db
    }

    deinit {
        logger.error("Shutting down client")
        try? client.syncShutdown()
    }

    func scan() async throws {
        logger.info("\(Date()) Getting manga comments...")
        try await getMangaComments()

        logger.info("\(Date()) Finished, getting discussions...")
        await getDiscussions()

        logger.info("\(Date()) Finished getting comments")
    }
}
