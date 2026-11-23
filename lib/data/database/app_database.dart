import 'package:drift/drift.dart';

import 'app_database_connection.dart';

part 'app_database.g.dart';

@DataClassName('ConversationRow')
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get modelId => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MessageRow')
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(Conversations, #id)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  IntColumn get createdAt => integer()();
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GeneratedMediaRow')
class GeneratedMedia extends Table {
  TextColumn get id => text()();
  TextColumn get messageId =>
      text().references(Messages, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();
  TextColumn get mimeType => text()();
  TextColumn get modelId => text()();
  BlobColumn get bytes => blob()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Conversations, Messages, GeneratedMedia])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(generatedMedia);
    },
  );
}

LazyDatabase _openConnection() {
  return openAppDatabaseConnection();
}
