import SwiftData

enum CockpitSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [BacklogHypothesis.self, CockpitSettings.self]
    }
}

enum CockpitSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [BacklogHypothesis.self, CockpitSettings.self]
    }
}

enum CockpitSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CockpitSchemaV1.self, CockpitSchemaV2.self]
    }
    static var stages: [MigrationStage] { [migrateV1toV2] }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: CockpitSchemaV1.self,
        toVersion: CockpitSchemaV2.self,
        willMigrate: { context in
            // BacklogHypothesis V1 data is not surfaced in the UI.
            // Delete all V1 records so the schema upgrade to V2 (which adds
            // the non-optional unique `slug` field) proceeds cleanly.
            let all = try context.fetch(FetchDescriptor<BacklogHypothesis>())
            for h in all { context.delete(h) }
            try context.save()
        },
        didMigrate: nil
    )
}

enum CockpitSchema {
    static let container: ModelContainer = {
        let schema = Schema(versionedSchema: CockpitSchemaV2.self)
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
