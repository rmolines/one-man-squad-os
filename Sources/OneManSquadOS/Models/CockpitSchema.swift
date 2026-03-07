import SwiftData

enum CockpitSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [BacklogHypothesis.self, CockpitSettings.self]
    }
}

enum CockpitSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [CockpitSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

enum CockpitSchema {
    static let container: ModelContainer = {
        let schema = Schema(versionedSchema: CockpitSchemaV1.self)
        let config = ModelConfiguration("CockpitStore", schema: schema)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: CockpitSchemaMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("CockpitSchema: failed to create container — \(error)")
        }
    }()
}
