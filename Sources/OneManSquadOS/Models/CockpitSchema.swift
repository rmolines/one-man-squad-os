import SwiftData

enum CockpitSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [BacklogHypothesis.self, CockpitSettings.self]
    }
}

// No migration plan needed — BacklogHypothesis V1 data was never surfaced in
// the UI. The store is renamed ("CockpitStoreV2") which creates a fresh V2
// store; the old V1 store file is abandoned harmlessly on disk.
enum CockpitSchema {
    static let container: ModelContainer = {
        let schema = Schema(versionedSchema: CockpitSchemaV2.self)
        let config = ModelConfiguration("CockpitStoreV2", schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("CockpitSchema: failed to create container — \(error)")
        }
    }()
}
