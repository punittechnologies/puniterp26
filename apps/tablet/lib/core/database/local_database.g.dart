// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $LocalSyncQueueTable extends LocalSyncQueue
    with TableInfo<$LocalSyncQueueTable, LocalSyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountScopeMeta = const VerificationMeta(
    'accountScope',
  );
  @override
  late final GeneratedColumn<String> accountScope = GeneratedColumn<String>(
    'account_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountScope,
    entityType,
    operation,
    idempotencyKey,
    payloadJson,
    status,
    attemptCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_scope')) {
      context.handle(
        _accountScopeMeta,
        accountScope.isAcceptableOrUnknown(
          data['account_scope']!,
          _accountScopeMeta,
        ),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_scope'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalSyncQueueTable createAlias(String alias) {
    return $LocalSyncQueueTable(attachedDatabase, alias);
  }
}

class LocalSyncQueueData extends DataClass
    implements Insertable<LocalSyncQueueData> {
  final String id;
  final String accountScope;
  final String entityType;
  final String operation;
  final String idempotencyKey;
  final String payloadJson;
  final String status;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalSyncQueueData({
    required this.id,
    required this.accountScope,
    required this.entityType,
    required this.operation,
    required this.idempotencyKey,
    required this.payloadJson,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_scope'] = Variable<String>(accountScope);
    map['entity_type'] = Variable<String>(entityType);
    map['operation'] = Variable<String>(operation);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSyncQueueCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncQueueCompanion(
      id: Value(id),
      accountScope: Value(accountScope),
      entityType: Value(entityType),
      operation: Value(operation),
      idempotencyKey: Value(idempotencyKey),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      accountScope: serializer.fromJson<String>(json['accountScope']),
      entityType: serializer.fromJson<String>(json['entityType']),
      operation: serializer.fromJson<String>(json['operation']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountScope': serializer.toJson<String>(accountScope),
      'entityType': serializer.toJson<String>(entityType),
      'operation': serializer.toJson<String>(operation),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSyncQueueData copyWith({
    String? id,
    String? accountScope,
    String? entityType,
    String? operation,
    String? idempotencyKey,
    String? payloadJson,
    String? status,
    int? attemptCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalSyncQueueData(
    id: id ?? this.id,
    accountScope: accountScope ?? this.accountScope,
    entityType: entityType ?? this.entityType,
    operation: operation ?? this.operation,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalSyncQueueData copyWithCompanion(LocalSyncQueueCompanion data) {
    return LocalSyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      accountScope: data.accountScope.present
          ? data.accountScope.value
          : this.accountScope,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      operation: data.operation.present ? data.operation.value : this.operation,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncQueueData(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('entityType: $entityType, ')
          ..write('operation: $operation, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountScope,
    entityType,
    operation,
    idempotencyKey,
    payloadJson,
    status,
    attemptCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncQueueData &&
          other.id == this.id &&
          other.accountScope == this.accountScope &&
          other.entityType == this.entityType &&
          other.operation == this.operation &&
          other.idempotencyKey == this.idempotencyKey &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalSyncQueueCompanion extends UpdateCompanion<LocalSyncQueueData> {
  final Value<String> id;
  final Value<String> accountScope;
  final Value<String> entityType;
  final Value<String> operation;
  final Value<String> idempotencyKey;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalSyncQueueCompanion({
    this.id = const Value.absent(),
    this.accountScope = const Value.absent(),
    this.entityType = const Value.absent(),
    this.operation = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncQueueCompanion.insert({
    required String id,
    this.accountScope = const Value.absent(),
    required String entityType,
    required String operation,
    required String idempotencyKey,
    required String payloadJson,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       operation = Value(operation),
       idempotencyKey = Value(idempotencyKey),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalSyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? accountScope,
    Expression<String>? entityType,
    Expression<String>? operation,
    Expression<String>? idempotencyKey,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountScope != null) 'account_scope': accountScope,
      if (entityType != null) 'entity_type': entityType,
      if (operation != null) 'operation': operation,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? accountScope,
    Value<String>? entityType,
    Value<String>? operation,
    Value<String>? idempotencyKey,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalSyncQueueCompanion(
      id: id ?? this.id,
      accountScope: accountScope ?? this.accountScope,
      entityType: entityType ?? this.entityType,
      operation: operation ?? this.operation,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountScope.present) {
      map['account_scope'] = Variable<String>(accountScope.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('entityType: $entityType, ')
          ..write('operation: $operation, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalConfigurationVersionsTable extends LocalConfigurationVersions
    with
        TableInfo<$LocalConfigurationVersionsTable, LocalConfigurationVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalConfigurationVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activatedAtMeta = const VerificationMeta(
    'activatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> activatedAt = GeneratedColumn<DateTime>(
    'activated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, scope, version, activatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_configuration_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalConfigurationVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('activated_at')) {
      context.handle(
        _activatedAtMeta,
        activatedAt.isAcceptableOrUnknown(
          data['activated_at']!,
          _activatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalConfigurationVersion map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalConfigurationVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      activatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}activated_at'],
      )!,
    );
  }

  @override
  $LocalConfigurationVersionsTable createAlias(String alias) {
    return $LocalConfigurationVersionsTable(attachedDatabase, alias);
  }
}

class LocalConfigurationVersion extends DataClass
    implements Insertable<LocalConfigurationVersion> {
  final String id;
  final String scope;
  final int version;
  final DateTime activatedAt;
  const LocalConfigurationVersion({
    required this.id,
    required this.scope,
    required this.version,
    required this.activatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope'] = Variable<String>(scope);
    map['version'] = Variable<int>(version);
    map['activated_at'] = Variable<DateTime>(activatedAt);
    return map;
  }

  LocalConfigurationVersionsCompanion toCompanion(bool nullToAbsent) {
    return LocalConfigurationVersionsCompanion(
      id: Value(id),
      scope: Value(scope),
      version: Value(version),
      activatedAt: Value(activatedAt),
    );
  }

  factory LocalConfigurationVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalConfigurationVersion(
      id: serializer.fromJson<String>(json['id']),
      scope: serializer.fromJson<String>(json['scope']),
      version: serializer.fromJson<int>(json['version']),
      activatedAt: serializer.fromJson<DateTime>(json['activatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scope': serializer.toJson<String>(scope),
      'version': serializer.toJson<int>(version),
      'activatedAt': serializer.toJson<DateTime>(activatedAt),
    };
  }

  LocalConfigurationVersion copyWith({
    String? id,
    String? scope,
    int? version,
    DateTime? activatedAt,
  }) => LocalConfigurationVersion(
    id: id ?? this.id,
    scope: scope ?? this.scope,
    version: version ?? this.version,
    activatedAt: activatedAt ?? this.activatedAt,
  );
  LocalConfigurationVersion copyWithCompanion(
    LocalConfigurationVersionsCompanion data,
  ) {
    return LocalConfigurationVersion(
      id: data.id.present ? data.id.value : this.id,
      scope: data.scope.present ? data.scope.value : this.scope,
      version: data.version.present ? data.version.value : this.version,
      activatedAt: data.activatedAt.present
          ? data.activatedAt.value
          : this.activatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalConfigurationVersion(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('version: $version, ')
          ..write('activatedAt: $activatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scope, version, activatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalConfigurationVersion &&
          other.id == this.id &&
          other.scope == this.scope &&
          other.version == this.version &&
          other.activatedAt == this.activatedAt);
}

class LocalConfigurationVersionsCompanion
    extends UpdateCompanion<LocalConfigurationVersion> {
  final Value<String> id;
  final Value<String> scope;
  final Value<int> version;
  final Value<DateTime> activatedAt;
  final Value<int> rowid;
  const LocalConfigurationVersionsCompanion({
    this.id = const Value.absent(),
    this.scope = const Value.absent(),
    this.version = const Value.absent(),
    this.activatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalConfigurationVersionsCompanion.insert({
    required String id,
    required String scope,
    required int version,
    required DateTime activatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scope = Value(scope),
       version = Value(version),
       activatedAt = Value(activatedAt);
  static Insertable<LocalConfigurationVersion> custom({
    Expression<String>? id,
    Expression<String>? scope,
    Expression<int>? version,
    Expression<DateTime>? activatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scope != null) 'scope': scope,
      if (version != null) 'version': version,
      if (activatedAt != null) 'activated_at': activatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalConfigurationVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? scope,
    Value<int>? version,
    Value<DateTime>? activatedAt,
    Value<int>? rowid,
  }) {
    return LocalConfigurationVersionsCompanion(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      version: version ?? this.version,
      activatedAt: activatedAt ?? this.activatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (activatedAt.present) {
      map['activated_at'] = Variable<DateTime>(activatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalConfigurationVersionsCompanion(')
          ..write('id: $id, ')
          ..write('scope: $scope, ')
          ..write('version: $version, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductsTable extends LocalProducts
    with TableInfo<$LocalProductsTable, LocalProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productCodeMeta = const VerificationMeta(
    'productCode',
  );
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
    'product_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _configurationVersionMeta =
      const VerificationMeta('configurationVersion');
  @override
  late final GeneratedColumn<int> configurationVersion = GeneratedColumn<int>(
    'configuration_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    productCode,
    sku,
    payloadJson,
    isActive,
    configurationVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
        _productCodeMeta,
        productCode.isAcceptableOrUnknown(
          data['product_code']!,
          _productCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('configuration_version')) {
      context.handle(
        _configurationVersionMeta,
        configurationVersion.isAcceptableOrUnknown(
          data['configuration_version']!,
          _configurationVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      productCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_code'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      configurationVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}configuration_version'],
      )!,
    );
  }

  @override
  $LocalProductsTable createAlias(String alias) {
    return $LocalProductsTable(attachedDatabase, alias);
  }
}

class LocalProduct extends DataClass implements Insertable<LocalProduct> {
  final String id;
  final String name;
  final String productCode;
  final String? sku;
  final String payloadJson;
  final bool isActive;
  final int configurationVersion;
  const LocalProduct({
    required this.id,
    required this.name,
    required this.productCode,
    this.sku,
    required this.payloadJson,
    required this.isActive,
    required this.configurationVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['product_code'] = Variable<String>(productCode);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['is_active'] = Variable<bool>(isActive);
    map['configuration_version'] = Variable<int>(configurationVersion);
    return map;
  }

  LocalProductsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductsCompanion(
      id: Value(id),
      name: Value(name),
      productCode: Value(productCode),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      payloadJson: Value(payloadJson),
      isActive: Value(isActive),
      configurationVersion: Value(configurationVersion),
    );
  }

  factory LocalProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProduct(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      productCode: serializer.fromJson<String>(json['productCode']),
      sku: serializer.fromJson<String?>(json['sku']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      configurationVersion: serializer.fromJson<int>(
        json['configurationVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'productCode': serializer.toJson<String>(productCode),
      'sku': serializer.toJson<String?>(sku),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'isActive': serializer.toJson<bool>(isActive),
      'configurationVersion': serializer.toJson<int>(configurationVersion),
    };
  }

  LocalProduct copyWith({
    String? id,
    String? name,
    String? productCode,
    Value<String?> sku = const Value.absent(),
    String? payloadJson,
    bool? isActive,
    int? configurationVersion,
  }) => LocalProduct(
    id: id ?? this.id,
    name: name ?? this.name,
    productCode: productCode ?? this.productCode,
    sku: sku.present ? sku.value : this.sku,
    payloadJson: payloadJson ?? this.payloadJson,
    isActive: isActive ?? this.isActive,
    configurationVersion: configurationVersion ?? this.configurationVersion,
  );
  LocalProduct copyWithCompanion(LocalProductsCompanion data) {
    return LocalProduct(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      productCode: data.productCode.present
          ? data.productCode.value
          : this.productCode,
      sku: data.sku.present ? data.sku.value : this.sku,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      configurationVersion: data.configurationVersion.present
          ? data.configurationVersion.value
          : this.configurationVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProduct(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('productCode: $productCode, ')
          ..write('sku: $sku, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isActive: $isActive, ')
          ..write('configurationVersion: $configurationVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    productCode,
    sku,
    payloadJson,
    isActive,
    configurationVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProduct &&
          other.id == this.id &&
          other.name == this.name &&
          other.productCode == this.productCode &&
          other.sku == this.sku &&
          other.payloadJson == this.payloadJson &&
          other.isActive == this.isActive &&
          other.configurationVersion == this.configurationVersion);
}

class LocalProductsCompanion extends UpdateCompanion<LocalProduct> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> productCode;
  final Value<String?> sku;
  final Value<String> payloadJson;
  final Value<bool> isActive;
  final Value<int> configurationVersion;
  final Value<int> rowid;
  const LocalProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.productCode = const Value.absent(),
    this.sku = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.configurationVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductsCompanion.insert({
    required String id,
    required String name,
    required String productCode,
    this.sku = const Value.absent(),
    required String payloadJson,
    this.isActive = const Value.absent(),
    this.configurationVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       productCode = Value(productCode),
       payloadJson = Value(payloadJson);
  static Insertable<LocalProduct> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? productCode,
    Expression<String>? sku,
    Expression<String>? payloadJson,
    Expression<bool>? isActive,
    Expression<int>? configurationVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (productCode != null) 'product_code': productCode,
      if (sku != null) 'sku': sku,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (isActive != null) 'is_active': isActive,
      if (configurationVersion != null)
        'configuration_version': configurationVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? productCode,
    Value<String?>? sku,
    Value<String>? payloadJson,
    Value<bool>? isActive,
    Value<int>? configurationVersion,
    Value<int>? rowid,
  }) {
    return LocalProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      productCode: productCode ?? this.productCode,
      sku: sku ?? this.sku,
      payloadJson: payloadJson ?? this.payloadJson,
      isActive: isActive ?? this.isActive,
      configurationVersion: configurationVersion ?? this.configurationVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (configurationVersion.present) {
      map['configuration_version'] = Variable<int>(configurationVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('productCode: $productCode, ')
          ..write('sku: $sku, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isActive: $isActive, ')
          ..write('configurationVersion: $configurationVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductVariantsTable extends LocalProductVariants
    with TableInfo<$LocalProductVariantsTable, LocalProductVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantCodeMeta = const VerificationMeta(
    'variantCode',
  );
  @override
  late final GeneratedColumn<String> variantCode = GeneratedColumn<String>(
    'variant_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    name,
    variantCode,
    payloadJson,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_product_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProductVariant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('variant_code')) {
      context.handle(
        _variantCodeMeta,
        variantCode.isAcceptableOrUnknown(
          data['variant_code']!,
          _variantCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_variantCodeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProductVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProductVariant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      variantCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_code'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $LocalProductVariantsTable createAlias(String alias) {
    return $LocalProductVariantsTable(attachedDatabase, alias);
  }
}

class LocalProductVariant extends DataClass
    implements Insertable<LocalProductVariant> {
  final String id;
  final String productId;
  final String name;
  final String variantCode;
  final String payloadJson;
  final bool isActive;
  const LocalProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.variantCode,
    required this.payloadJson,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['name'] = Variable<String>(name);
    map['variant_code'] = Variable<String>(variantCode);
    map['payload_json'] = Variable<String>(payloadJson);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LocalProductVariantsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductVariantsCompanion(
      id: Value(id),
      productId: Value(productId),
      name: Value(name),
      variantCode: Value(variantCode),
      payloadJson: Value(payloadJson),
      isActive: Value(isActive),
    );
  }

  factory LocalProductVariant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProductVariant(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      name: serializer.fromJson<String>(json['name']),
      variantCode: serializer.fromJson<String>(json['variantCode']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'name': serializer.toJson<String>(name),
      'variantCode': serializer.toJson<String>(variantCode),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  LocalProductVariant copyWith({
    String? id,
    String? productId,
    String? name,
    String? variantCode,
    String? payloadJson,
    bool? isActive,
  }) => LocalProductVariant(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    name: name ?? this.name,
    variantCode: variantCode ?? this.variantCode,
    payloadJson: payloadJson ?? this.payloadJson,
    isActive: isActive ?? this.isActive,
  );
  LocalProductVariant copyWithCompanion(LocalProductVariantsCompanion data) {
    return LocalProductVariant(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      name: data.name.present ? data.name.value : this.name,
      variantCode: data.variantCode.present
          ? data.variantCode.value
          : this.variantCode,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductVariant(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('variantCode: $variantCode, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, name, variantCode, payloadJson, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProductVariant &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.name == this.name &&
          other.variantCode == this.variantCode &&
          other.payloadJson == this.payloadJson &&
          other.isActive == this.isActive);
}

class LocalProductVariantsCompanion
    extends UpdateCompanion<LocalProductVariant> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> name;
  final Value<String> variantCode;
  final Value<String> payloadJson;
  final Value<bool> isActive;
  final Value<int> rowid;
  const LocalProductVariantsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.name = const Value.absent(),
    this.variantCode = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductVariantsCompanion.insert({
    required String id,
    required String productId,
    required String name,
    required String variantCode,
    required String payloadJson,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       name = Value(name),
       variantCode = Value(variantCode),
       payloadJson = Value(payloadJson);
  static Insertable<LocalProductVariant> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? name,
    Expression<String>? variantCode,
    Expression<String>? payloadJson,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (name != null) 'name': name,
      if (variantCode != null) 'variant_code': variantCode,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductVariantsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? name,
    Value<String>? variantCode,
    Value<String>? payloadJson,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return LocalProductVariantsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      variantCode: variantCode ?? this.variantCode,
      payloadJson: payloadJson ?? this.payloadJson,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (variantCode.present) {
      map['variant_code'] = Variable<String>(variantCode.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductVariantsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('variantCode: $variantCode, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDynamicFieldsTable extends LocalDynamicFields
    with TableInfo<$LocalDynamicFieldsTable, LocalDynamicField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDynamicFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _internalKeyMeta = const VerificationMeta(
    'internalKey',
  );
  @override
  late final GeneratedColumn<String> internalKey = GeneratedColumn<String>(
    'internal_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldLabelMeta = const VerificationMeta(
    'fieldLabel',
  );
  @override
  late final GeneratedColumn<String> fieldLabel = GeneratedColumn<String>(
    'field_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataTypeMeta = const VerificationMeta(
    'dataType',
  );
  @override
  late final GeneratedColumn<String> dataType = GeneratedColumn<String>(
    'data_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibleInFlutterMeta = const VerificationMeta(
    'visibleInFlutter',
  );
  @override
  late final GeneratedColumn<bool> visibleInFlutter = GeneratedColumn<bool>(
    'visible_in_flutter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("visible_in_flutter" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    internalKey,
    fieldLabel,
    dataType,
    payloadJson,
    visibleInFlutter,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_dynamic_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDynamicField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('internal_key')) {
      context.handle(
        _internalKeyMeta,
        internalKey.isAcceptableOrUnknown(
          data['internal_key']!,
          _internalKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_internalKeyMeta);
    }
    if (data.containsKey('field_label')) {
      context.handle(
        _fieldLabelMeta,
        fieldLabel.isAcceptableOrUnknown(data['field_label']!, _fieldLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldLabelMeta);
    }
    if (data.containsKey('data_type')) {
      context.handle(
        _dataTypeMeta,
        dataType.isAcceptableOrUnknown(data['data_type']!, _dataTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_dataTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('visible_in_flutter')) {
      context.handle(
        _visibleInFlutterMeta,
        visibleInFlutter.isAcceptableOrUnknown(
          data['visible_in_flutter']!,
          _visibleInFlutterMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDynamicField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDynamicField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      internalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_key'],
      )!,
      fieldLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_label'],
      )!,
      dataType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      visibleInFlutter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}visible_in_flutter'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $LocalDynamicFieldsTable createAlias(String alias) {
    return $LocalDynamicFieldsTable(attachedDatabase, alias);
  }
}

class LocalDynamicField extends DataClass
    implements Insertable<LocalDynamicField> {
  final String id;
  final String entityType;
  final String internalKey;
  final String fieldLabel;
  final String dataType;
  final String payloadJson;
  final bool visibleInFlutter;
  final int sortOrder;
  const LocalDynamicField({
    required this.id,
    required this.entityType,
    required this.internalKey,
    required this.fieldLabel,
    required this.dataType,
    required this.payloadJson,
    required this.visibleInFlutter,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['internal_key'] = Variable<String>(internalKey);
    map['field_label'] = Variable<String>(fieldLabel);
    map['data_type'] = Variable<String>(dataType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['visible_in_flutter'] = Variable<bool>(visibleInFlutter);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LocalDynamicFieldsCompanion toCompanion(bool nullToAbsent) {
    return LocalDynamicFieldsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      internalKey: Value(internalKey),
      fieldLabel: Value(fieldLabel),
      dataType: Value(dataType),
      payloadJson: Value(payloadJson),
      visibleInFlutter: Value(visibleInFlutter),
      sortOrder: Value(sortOrder),
    );
  }

  factory LocalDynamicField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDynamicField(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      internalKey: serializer.fromJson<String>(json['internalKey']),
      fieldLabel: serializer.fromJson<String>(json['fieldLabel']),
      dataType: serializer.fromJson<String>(json['dataType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      visibleInFlutter: serializer.fromJson<bool>(json['visibleInFlutter']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'internalKey': serializer.toJson<String>(internalKey),
      'fieldLabel': serializer.toJson<String>(fieldLabel),
      'dataType': serializer.toJson<String>(dataType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'visibleInFlutter': serializer.toJson<bool>(visibleInFlutter),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LocalDynamicField copyWith({
    String? id,
    String? entityType,
    String? internalKey,
    String? fieldLabel,
    String? dataType,
    String? payloadJson,
    bool? visibleInFlutter,
    int? sortOrder,
  }) => LocalDynamicField(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    internalKey: internalKey ?? this.internalKey,
    fieldLabel: fieldLabel ?? this.fieldLabel,
    dataType: dataType ?? this.dataType,
    payloadJson: payloadJson ?? this.payloadJson,
    visibleInFlutter: visibleInFlutter ?? this.visibleInFlutter,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LocalDynamicField copyWithCompanion(LocalDynamicFieldsCompanion data) {
    return LocalDynamicField(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      internalKey: data.internalKey.present
          ? data.internalKey.value
          : this.internalKey,
      fieldLabel: data.fieldLabel.present
          ? data.fieldLabel.value
          : this.fieldLabel,
      dataType: data.dataType.present ? data.dataType.value : this.dataType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      visibleInFlutter: data.visibleInFlutter.present
          ? data.visibleInFlutter.value
          : this.visibleInFlutter,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDynamicField(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('internalKey: $internalKey, ')
          ..write('fieldLabel: $fieldLabel, ')
          ..write('dataType: $dataType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('visibleInFlutter: $visibleInFlutter, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    internalKey,
    fieldLabel,
    dataType,
    payloadJson,
    visibleInFlutter,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDynamicField &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.internalKey == this.internalKey &&
          other.fieldLabel == this.fieldLabel &&
          other.dataType == this.dataType &&
          other.payloadJson == this.payloadJson &&
          other.visibleInFlutter == this.visibleInFlutter &&
          other.sortOrder == this.sortOrder);
}

class LocalDynamicFieldsCompanion extends UpdateCompanion<LocalDynamicField> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> internalKey;
  final Value<String> fieldLabel;
  final Value<String> dataType;
  final Value<String> payloadJson;
  final Value<bool> visibleInFlutter;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LocalDynamicFieldsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.internalKey = const Value.absent(),
    this.fieldLabel = const Value.absent(),
    this.dataType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.visibleInFlutter = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDynamicFieldsCompanion.insert({
    required String id,
    required String entityType,
    required String internalKey,
    required String fieldLabel,
    required String dataType,
    required String payloadJson,
    this.visibleInFlutter = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       internalKey = Value(internalKey),
       fieldLabel = Value(fieldLabel),
       dataType = Value(dataType),
       payloadJson = Value(payloadJson);
  static Insertable<LocalDynamicField> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? internalKey,
    Expression<String>? fieldLabel,
    Expression<String>? dataType,
    Expression<String>? payloadJson,
    Expression<bool>? visibleInFlutter,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (internalKey != null) 'internal_key': internalKey,
      if (fieldLabel != null) 'field_label': fieldLabel,
      if (dataType != null) 'data_type': dataType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (visibleInFlutter != null) 'visible_in_flutter': visibleInFlutter,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDynamicFieldsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? internalKey,
    Value<String>? fieldLabel,
    Value<String>? dataType,
    Value<String>? payloadJson,
    Value<bool>? visibleInFlutter,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return LocalDynamicFieldsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      internalKey: internalKey ?? this.internalKey,
      fieldLabel: fieldLabel ?? this.fieldLabel,
      dataType: dataType ?? this.dataType,
      payloadJson: payloadJson ?? this.payloadJson,
      visibleInFlutter: visibleInFlutter ?? this.visibleInFlutter,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (internalKey.present) {
      map['internal_key'] = Variable<String>(internalKey.value);
    }
    if (fieldLabel.present) {
      map['field_label'] = Variable<String>(fieldLabel.value);
    }
    if (dataType.present) {
      map['data_type'] = Variable<String>(dataType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (visibleInFlutter.present) {
      map['visible_in_flutter'] = Variable<bool>(visibleInFlutter.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDynamicFieldsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('internalKey: $internalKey, ')
          ..write('fieldLabel: $fieldLabel, ')
          ..write('dataType: $dataType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('visibleInFlutter: $visibleInFlutter, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalLabelTemplatesTable extends LocalLabelTemplates
    with TableInfo<$LocalLabelTemplatesTable, LocalLabelTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalLabelTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeVersionMeta = const VerificationMeta(
    'activeVersion',
  );
  @override
  late final GeneratedColumn<int> activeVersion = GeneratedColumn<int>(
    'active_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    scope,
    productId,
    variantId,
    activeVersion,
    isDefault,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_label_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalLabelTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    }
    if (data.containsKey('active_version')) {
      context.handle(
        _activeVersionMeta,
        activeVersion.isAcceptableOrUnknown(
          data['active_version']!,
          _activeVersionMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalLabelTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLabelTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      ),
      activeVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_version'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $LocalLabelTemplatesTable createAlias(String alias) {
    return $LocalLabelTemplatesTable(attachedDatabase, alias);
  }
}

class LocalLabelTemplate extends DataClass
    implements Insertable<LocalLabelTemplate> {
  final String id;
  final String code;
  final String name;
  final String scope;
  final String? productId;
  final String? variantId;
  final int activeVersion;
  final bool isDefault;
  final String payloadJson;
  const LocalLabelTemplate({
    required this.id,
    required this.code,
    required this.name,
    required this.scope,
    this.productId,
    this.variantId,
    required this.activeVersion,
    required this.isDefault,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || variantId != null) {
      map['variant_id'] = Variable<String>(variantId);
    }
    map['active_version'] = Variable<int>(activeVersion);
    map['is_default'] = Variable<bool>(isDefault);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  LocalLabelTemplatesCompanion toCompanion(bool nullToAbsent) {
    return LocalLabelTemplatesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      scope: Value(scope),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      variantId: variantId == null && nullToAbsent
          ? const Value.absent()
          : Value(variantId),
      activeVersion: Value(activeVersion),
      isDefault: Value(isDefault),
      payloadJson: Value(payloadJson),
    );
  }

  factory LocalLabelTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLabelTemplate(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      scope: serializer.fromJson<String>(json['scope']),
      productId: serializer.fromJson<String?>(json['productId']),
      variantId: serializer.fromJson<String?>(json['variantId']),
      activeVersion: serializer.fromJson<int>(json['activeVersion']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'scope': serializer.toJson<String>(scope),
      'productId': serializer.toJson<String?>(productId),
      'variantId': serializer.toJson<String?>(variantId),
      'activeVersion': serializer.toJson<int>(activeVersion),
      'isDefault': serializer.toJson<bool>(isDefault),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  LocalLabelTemplate copyWith({
    String? id,
    String? code,
    String? name,
    String? scope,
    Value<String?> productId = const Value.absent(),
    Value<String?> variantId = const Value.absent(),
    int? activeVersion,
    bool? isDefault,
    String? payloadJson,
  }) => LocalLabelTemplate(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    scope: scope ?? this.scope,
    productId: productId.present ? productId.value : this.productId,
    variantId: variantId.present ? variantId.value : this.variantId,
    activeVersion: activeVersion ?? this.activeVersion,
    isDefault: isDefault ?? this.isDefault,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  LocalLabelTemplate copyWithCompanion(LocalLabelTemplatesCompanion data) {
    return LocalLabelTemplate(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      scope: data.scope.present ? data.scope.value : this.scope,
      productId: data.productId.present ? data.productId.value : this.productId,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      activeVersion: data.activeVersion.present
          ? data.activeVersion.value
          : this.activeVersion,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLabelTemplate(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('scope: $scope, ')
          ..write('productId: $productId, ')
          ..write('variantId: $variantId, ')
          ..write('activeVersion: $activeVersion, ')
          ..write('isDefault: $isDefault, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    name,
    scope,
    productId,
    variantId,
    activeVersion,
    isDefault,
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLabelTemplate &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.scope == this.scope &&
          other.productId == this.productId &&
          other.variantId == this.variantId &&
          other.activeVersion == this.activeVersion &&
          other.isDefault == this.isDefault &&
          other.payloadJson == this.payloadJson);
}

class LocalLabelTemplatesCompanion extends UpdateCompanion<LocalLabelTemplate> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> scope;
  final Value<String?> productId;
  final Value<String?> variantId;
  final Value<int> activeVersion;
  final Value<bool> isDefault;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const LocalLabelTemplatesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.scope = const Value.absent(),
    this.productId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.activeVersion = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalLabelTemplatesCompanion.insert({
    required String id,
    required String code,
    required String name,
    required String scope,
    this.productId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.activeVersion = const Value.absent(),
    this.isDefault = const Value.absent(),
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       scope = Value(scope),
       payloadJson = Value(payloadJson);
  static Insertable<LocalLabelTemplate> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? scope,
    Expression<String>? productId,
    Expression<String>? variantId,
    Expression<int>? activeVersion,
    Expression<bool>? isDefault,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (scope != null) 'scope': scope,
      if (productId != null) 'product_id': productId,
      if (variantId != null) 'variant_id': variantId,
      if (activeVersion != null) 'active_version': activeVersion,
      if (isDefault != null) 'is_default': isDefault,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalLabelTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? scope,
    Value<String?>? productId,
    Value<String?>? variantId,
    Value<int>? activeVersion,
    Value<bool>? isDefault,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return LocalLabelTemplatesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      scope: scope ?? this.scope,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      activeVersion: activeVersion ?? this.activeVersion,
      isDefault: isDefault ?? this.isDefault,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (activeVersion.present) {
      map['active_version'] = Variable<int>(activeVersion.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalLabelTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('scope: $scope, ')
          ..write('productId: $productId, ')
          ..write('variantId: $variantId, ')
          ..write('activeVersion: $activeVersion, ')
          ..write('isDefault: $isDefault, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalScaleProfilesTable extends LocalScaleProfiles
    with TableInfo<$LocalScaleProfilesTable, LocalScaleProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalScaleProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, payloadJson, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_scale_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalScaleProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalScaleProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalScaleProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $LocalScaleProfilesTable createAlias(String alias) {
    return $LocalScaleProfilesTable(attachedDatabase, alias);
  }
}

class LocalScaleProfile extends DataClass
    implements Insertable<LocalScaleProfile> {
  final String id;
  final String name;
  final String payloadJson;
  final bool isActive;
  const LocalScaleProfile({
    required this.id,
    required this.name,
    required this.payloadJson,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['payload_json'] = Variable<String>(payloadJson);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LocalScaleProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalScaleProfilesCompanion(
      id: Value(id),
      name: Value(name),
      payloadJson: Value(payloadJson),
      isActive: Value(isActive),
    );
  }

  factory LocalScaleProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalScaleProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  LocalScaleProfile copyWith({
    String? id,
    String? name,
    String? payloadJson,
    bool? isActive,
  }) => LocalScaleProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    payloadJson: payloadJson ?? this.payloadJson,
    isActive: isActive ?? this.isActive,
  );
  LocalScaleProfile copyWithCompanion(LocalScaleProfilesCompanion data) {
    return LocalScaleProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalScaleProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, payloadJson, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalScaleProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.payloadJson == this.payloadJson &&
          other.isActive == this.isActive);
}

class LocalScaleProfilesCompanion extends UpdateCompanion<LocalScaleProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> payloadJson;
  final Value<bool> isActive;
  final Value<int> rowid;
  const LocalScaleProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalScaleProfilesCompanion.insert({
    required String id,
    required String name,
    required String payloadJson,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       payloadJson = Value(payloadJson);
  static Insertable<LocalScaleProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? payloadJson,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalScaleProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? payloadJson,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return LocalScaleProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      payloadJson: payloadJson ?? this.payloadJson,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalScaleProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalInwardSessionsTable extends LocalInwardSessions
    with TableInfo<$LocalInwardSessionsTable, LocalInwardSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInwardSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountScopeMeta = const VerificationMeta(
    'accountScope',
  );
  @override
  late final GeneratedColumn<String> accountScope = GeneratedColumn<String>(
    'account_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _sessionNumberMeta = const VerificationMeta(
    'sessionNumber',
  );
  @override
  late final GeneratedColumn<String> sessionNumber = GeneratedColumn<String>(
    'session_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _entryCountMeta = const VerificationMeta(
    'entryCount',
  );
  @override
  late final GeneratedColumn<int> entryCount = GeneratedColumn<int>(
    'entry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalGrossWeightMeta = const VerificationMeta(
    'totalGrossWeight',
  );
  @override
  late final GeneratedColumn<double> totalGrossWeight = GeneratedColumn<double>(
    'total_gross_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalTareWeightMeta = const VerificationMeta(
    'totalTareWeight',
  );
  @override
  late final GeneratedColumn<double> totalTareWeight = GeneratedColumn<double>(
    'total_tare_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalNetWeightMeta = const VerificationMeta(
    'totalNetWeight',
  );
  @override
  late final GeneratedColumn<double> totalNetWeight = GeneratedColumn<double>(
    'total_net_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPieceQuantityMeta =
      const VerificationMeta('totalPieceQuantity');
  @override
  late final GeneratedColumn<double> totalPieceQuantity =
      GeneratedColumn<double>(
        'total_piece_quantity',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountScope,
    sessionNumber,
    status,
    entryCount,
    totalGrossWeight,
    totalTareWeight,
    totalNetWeight,
    totalPieceQuantity,
    startedAt,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inward_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalInwardSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_scope')) {
      context.handle(
        _accountScopeMeta,
        accountScope.isAcceptableOrUnknown(
          data['account_scope']!,
          _accountScopeMeta,
        ),
      );
    }
    if (data.containsKey('session_number')) {
      context.handle(
        _sessionNumberMeta,
        sessionNumber.isAcceptableOrUnknown(
          data['session_number']!,
          _sessionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionNumberMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('entry_count')) {
      context.handle(
        _entryCountMeta,
        entryCount.isAcceptableOrUnknown(data['entry_count']!, _entryCountMeta),
      );
    }
    if (data.containsKey('total_gross_weight')) {
      context.handle(
        _totalGrossWeightMeta,
        totalGrossWeight.isAcceptableOrUnknown(
          data['total_gross_weight']!,
          _totalGrossWeightMeta,
        ),
      );
    }
    if (data.containsKey('total_tare_weight')) {
      context.handle(
        _totalTareWeightMeta,
        totalTareWeight.isAcceptableOrUnknown(
          data['total_tare_weight']!,
          _totalTareWeightMeta,
        ),
      );
    }
    if (data.containsKey('total_net_weight')) {
      context.handle(
        _totalNetWeightMeta,
        totalNetWeight.isAcceptableOrUnknown(
          data['total_net_weight']!,
          _totalNetWeightMeta,
        ),
      );
    }
    if (data.containsKey('total_piece_quantity')) {
      context.handle(
        _totalPieceQuantityMeta,
        totalPieceQuantity.isAcceptableOrUnknown(
          data['total_piece_quantity']!,
          _totalPieceQuantityMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalInwardSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInwardSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_scope'],
      )!,
      sessionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_number'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      entryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_count'],
      )!,
      totalGrossWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_gross_weight'],
      )!,
      totalTareWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_tare_weight'],
      )!,
      totalNetWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_net_weight'],
      )!,
      totalPieceQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_piece_quantity'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  $LocalInwardSessionsTable createAlias(String alias) {
    return $LocalInwardSessionsTable(attachedDatabase, alias);
  }
}

class LocalInwardSession extends DataClass
    implements Insertable<LocalInwardSession> {
  final String id;
  final String accountScope;
  final String sessionNumber;
  final String status;
  final int entryCount;
  final double totalGrossWeight;
  final double totalTareWeight;
  final double totalNetWeight;
  final double? totalPieceQuantity;
  final DateTime startedAt;
  final DateTime? endedAt;
  const LocalInwardSession({
    required this.id,
    required this.accountScope,
    required this.sessionNumber,
    required this.status,
    required this.entryCount,
    required this.totalGrossWeight,
    required this.totalTareWeight,
    required this.totalNetWeight,
    this.totalPieceQuantity,
    required this.startedAt,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_scope'] = Variable<String>(accountScope);
    map['session_number'] = Variable<String>(sessionNumber);
    map['status'] = Variable<String>(status);
    map['entry_count'] = Variable<int>(entryCount);
    map['total_gross_weight'] = Variable<double>(totalGrossWeight);
    map['total_tare_weight'] = Variable<double>(totalTareWeight);
    map['total_net_weight'] = Variable<double>(totalNetWeight);
    if (!nullToAbsent || totalPieceQuantity != null) {
      map['total_piece_quantity'] = Variable<double>(totalPieceQuantity);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  LocalInwardSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalInwardSessionsCompanion(
      id: Value(id),
      accountScope: Value(accountScope),
      sessionNumber: Value(sessionNumber),
      status: Value(status),
      entryCount: Value(entryCount),
      totalGrossWeight: Value(totalGrossWeight),
      totalTareWeight: Value(totalTareWeight),
      totalNetWeight: Value(totalNetWeight),
      totalPieceQuantity: totalPieceQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPieceQuantity),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory LocalInwardSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInwardSession(
      id: serializer.fromJson<String>(json['id']),
      accountScope: serializer.fromJson<String>(json['accountScope']),
      sessionNumber: serializer.fromJson<String>(json['sessionNumber']),
      status: serializer.fromJson<String>(json['status']),
      entryCount: serializer.fromJson<int>(json['entryCount']),
      totalGrossWeight: serializer.fromJson<double>(json['totalGrossWeight']),
      totalTareWeight: serializer.fromJson<double>(json['totalTareWeight']),
      totalNetWeight: serializer.fromJson<double>(json['totalNetWeight']),
      totalPieceQuantity: serializer.fromJson<double?>(
        json['totalPieceQuantity'],
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountScope': serializer.toJson<String>(accountScope),
      'sessionNumber': serializer.toJson<String>(sessionNumber),
      'status': serializer.toJson<String>(status),
      'entryCount': serializer.toJson<int>(entryCount),
      'totalGrossWeight': serializer.toJson<double>(totalGrossWeight),
      'totalTareWeight': serializer.toJson<double>(totalTareWeight),
      'totalNetWeight': serializer.toJson<double>(totalNetWeight),
      'totalPieceQuantity': serializer.toJson<double?>(totalPieceQuantity),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
    };
  }

  LocalInwardSession copyWith({
    String? id,
    String? accountScope,
    String? sessionNumber,
    String? status,
    int? entryCount,
    double? totalGrossWeight,
    double? totalTareWeight,
    double? totalNetWeight,
    Value<double?> totalPieceQuantity = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => LocalInwardSession(
    id: id ?? this.id,
    accountScope: accountScope ?? this.accountScope,
    sessionNumber: sessionNumber ?? this.sessionNumber,
    status: status ?? this.status,
    entryCount: entryCount ?? this.entryCount,
    totalGrossWeight: totalGrossWeight ?? this.totalGrossWeight,
    totalTareWeight: totalTareWeight ?? this.totalTareWeight,
    totalNetWeight: totalNetWeight ?? this.totalNetWeight,
    totalPieceQuantity: totalPieceQuantity.present
        ? totalPieceQuantity.value
        : this.totalPieceQuantity,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  LocalInwardSession copyWithCompanion(LocalInwardSessionsCompanion data) {
    return LocalInwardSession(
      id: data.id.present ? data.id.value : this.id,
      accountScope: data.accountScope.present
          ? data.accountScope.value
          : this.accountScope,
      sessionNumber: data.sessionNumber.present
          ? data.sessionNumber.value
          : this.sessionNumber,
      status: data.status.present ? data.status.value : this.status,
      entryCount: data.entryCount.present
          ? data.entryCount.value
          : this.entryCount,
      totalGrossWeight: data.totalGrossWeight.present
          ? data.totalGrossWeight.value
          : this.totalGrossWeight,
      totalTareWeight: data.totalTareWeight.present
          ? data.totalTareWeight.value
          : this.totalTareWeight,
      totalNetWeight: data.totalNetWeight.present
          ? data.totalNetWeight.value
          : this.totalNetWeight,
      totalPieceQuantity: data.totalPieceQuantity.present
          ? data.totalPieceQuantity.value
          : this.totalPieceQuantity,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalInwardSession(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('sessionNumber: $sessionNumber, ')
          ..write('status: $status, ')
          ..write('entryCount: $entryCount, ')
          ..write('totalGrossWeight: $totalGrossWeight, ')
          ..write('totalTareWeight: $totalTareWeight, ')
          ..write('totalNetWeight: $totalNetWeight, ')
          ..write('totalPieceQuantity: $totalPieceQuantity, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountScope,
    sessionNumber,
    status,
    entryCount,
    totalGrossWeight,
    totalTareWeight,
    totalNetWeight,
    totalPieceQuantity,
    startedAt,
    endedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInwardSession &&
          other.id == this.id &&
          other.accountScope == this.accountScope &&
          other.sessionNumber == this.sessionNumber &&
          other.status == this.status &&
          other.entryCount == this.entryCount &&
          other.totalGrossWeight == this.totalGrossWeight &&
          other.totalTareWeight == this.totalTareWeight &&
          other.totalNetWeight == this.totalNetWeight &&
          other.totalPieceQuantity == this.totalPieceQuantity &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt);
}

class LocalInwardSessionsCompanion extends UpdateCompanion<LocalInwardSession> {
  final Value<String> id;
  final Value<String> accountScope;
  final Value<String> sessionNumber;
  final Value<String> status;
  final Value<int> entryCount;
  final Value<double> totalGrossWeight;
  final Value<double> totalTareWeight;
  final Value<double> totalNetWeight;
  final Value<double?> totalPieceQuantity;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> rowid;
  const LocalInwardSessionsCompanion({
    this.id = const Value.absent(),
    this.accountScope = const Value.absent(),
    this.sessionNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.entryCount = const Value.absent(),
    this.totalGrossWeight = const Value.absent(),
    this.totalTareWeight = const Value.absent(),
    this.totalNetWeight = const Value.absent(),
    this.totalPieceQuantity = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInwardSessionsCompanion.insert({
    required String id,
    this.accountScope = const Value.absent(),
    required String sessionNumber,
    this.status = const Value.absent(),
    this.entryCount = const Value.absent(),
    this.totalGrossWeight = const Value.absent(),
    this.totalTareWeight = const Value.absent(),
    this.totalNetWeight = const Value.absent(),
    this.totalPieceQuantity = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionNumber = Value(sessionNumber),
       startedAt = Value(startedAt);
  static Insertable<LocalInwardSession> custom({
    Expression<String>? id,
    Expression<String>? accountScope,
    Expression<String>? sessionNumber,
    Expression<String>? status,
    Expression<int>? entryCount,
    Expression<double>? totalGrossWeight,
    Expression<double>? totalTareWeight,
    Expression<double>? totalNetWeight,
    Expression<double>? totalPieceQuantity,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountScope != null) 'account_scope': accountScope,
      if (sessionNumber != null) 'session_number': sessionNumber,
      if (status != null) 'status': status,
      if (entryCount != null) 'entry_count': entryCount,
      if (totalGrossWeight != null) 'total_gross_weight': totalGrossWeight,
      if (totalTareWeight != null) 'total_tare_weight': totalTareWeight,
      if (totalNetWeight != null) 'total_net_weight': totalNetWeight,
      if (totalPieceQuantity != null)
        'total_piece_quantity': totalPieceQuantity,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInwardSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountScope,
    Value<String>? sessionNumber,
    Value<String>? status,
    Value<int>? entryCount,
    Value<double>? totalGrossWeight,
    Value<double>? totalTareWeight,
    Value<double>? totalNetWeight,
    Value<double?>? totalPieceQuantity,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? rowid,
  }) {
    return LocalInwardSessionsCompanion(
      id: id ?? this.id,
      accountScope: accountScope ?? this.accountScope,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      status: status ?? this.status,
      entryCount: entryCount ?? this.entryCount,
      totalGrossWeight: totalGrossWeight ?? this.totalGrossWeight,
      totalTareWeight: totalTareWeight ?? this.totalTareWeight,
      totalNetWeight: totalNetWeight ?? this.totalNetWeight,
      totalPieceQuantity: totalPieceQuantity ?? this.totalPieceQuantity,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountScope.present) {
      map['account_scope'] = Variable<String>(accountScope.value);
    }
    if (sessionNumber.present) {
      map['session_number'] = Variable<String>(sessionNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (entryCount.present) {
      map['entry_count'] = Variable<int>(entryCount.value);
    }
    if (totalGrossWeight.present) {
      map['total_gross_weight'] = Variable<double>(totalGrossWeight.value);
    }
    if (totalTareWeight.present) {
      map['total_tare_weight'] = Variable<double>(totalTareWeight.value);
    }
    if (totalNetWeight.present) {
      map['total_net_weight'] = Variable<double>(totalNetWeight.value);
    }
    if (totalPieceQuantity.present) {
      map['total_piece_quantity'] = Variable<double>(totalPieceQuantity.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInwardSessionsCompanion(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('sessionNumber: $sessionNumber, ')
          ..write('status: $status, ')
          ..write('entryCount: $entryCount, ')
          ..write('totalGrossWeight: $totalGrossWeight, ')
          ..write('totalTareWeight: $totalTareWeight, ')
          ..write('totalNetWeight: $totalNetWeight, ')
          ..write('totalPieceQuantity: $totalPieceQuantity, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductionTransactionsTable extends LocalProductionTransactions
    with
        TableInfo<
          $LocalProductionTransactionsTable,
          LocalProductionTransaction
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductionTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountScopeMeta = const VerificationMeta(
    'accountScope',
  );
  @override
  late final GeneratedColumn<String> accountScope = GeneratedColumn<String>(
    'account_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _barcodeValueMeta = const VerificationMeta(
    'barcodeValue',
  );
  @override
  late final GeneratedColumn<String> barcodeValue = GeneratedColumn<String>(
    'barcode_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inwardSessionIdMeta = const VerificationMeta(
    'inwardSessionId',
  );
  @override
  late final GeneratedColumn<String> inwardSessionId = GeneratedColumn<String>(
    'inward_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productSnapshotJsonMeta =
      const VerificationMeta('productSnapshotJson');
  @override
  late final GeneratedColumn<String> productSnapshotJson =
      GeneratedColumn<String>(
        'product_snapshot_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dynamicValuesJsonMeta = const VerificationMeta(
    'dynamicValuesJson',
  );
  @override
  late final GeneratedColumn<String> dynamicValuesJson =
      GeneratedColumn<String>(
        'dynamic_values_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _grossWeightMeta = const VerificationMeta(
    'grossWeight',
  );
  @override
  late final GeneratedColumn<double> grossWeight = GeneratedColumn<double>(
    'gross_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tareWeightMeta = const VerificationMeta(
    'tareWeight',
  );
  @override
  late final GeneratedColumn<double> tareWeight = GeneratedColumn<double>(
    'tare_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _netWeightMeta = const VerificationMeta(
    'netWeight',
  );
  @override
  late final GeneratedColumn<double> netWeight = GeneratedColumn<double>(
    'net_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pieceQuantityMeta = const VerificationMeta(
    'pieceQuantity',
  );
  @override
  late final GeneratedColumn<double> pieceQuantity = GeneratedColumn<double>(
    'piece_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('kg'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _rawReadingJsonMeta = const VerificationMeta(
    'rawReadingJson',
  );
  @override
  late final GeneratedColumn<String> rawReadingJson = GeneratedColumn<String>(
    'raw_reading_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountScope,
    serialNumber,
    barcodeValue,
    productId,
    variantId,
    inwardSessionId,
    productSnapshotJson,
    dynamicValuesJson,
    grossWeight,
    tareWeight,
    netWeight,
    pieceQuantity,
    unit,
    status,
    syncStatus,
    idempotencyKey,
    rawReadingJson,
    capturedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_production_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProductionTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_scope')) {
      context.handle(
        _accountScopeMeta,
        accountScope.isAcceptableOrUnknown(
          data['account_scope']!,
          _accountScopeMeta,
        ),
      );
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serialNumberMeta);
    }
    if (data.containsKey('barcode_value')) {
      context.handle(
        _barcodeValueMeta,
        barcodeValue.isAcceptableOrUnknown(
          data['barcode_value']!,
          _barcodeValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_barcodeValueMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    }
    if (data.containsKey('inward_session_id')) {
      context.handle(
        _inwardSessionIdMeta,
        inwardSessionId.isAcceptableOrUnknown(
          data['inward_session_id']!,
          _inwardSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('product_snapshot_json')) {
      context.handle(
        _productSnapshotJsonMeta,
        productSnapshotJson.isAcceptableOrUnknown(
          data['product_snapshot_json']!,
          _productSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productSnapshotJsonMeta);
    }
    if (data.containsKey('dynamic_values_json')) {
      context.handle(
        _dynamicValuesJsonMeta,
        dynamicValuesJson.isAcceptableOrUnknown(
          data['dynamic_values_json']!,
          _dynamicValuesJsonMeta,
        ),
      );
    }
    if (data.containsKey('gross_weight')) {
      context.handle(
        _grossWeightMeta,
        grossWeight.isAcceptableOrUnknown(
          data['gross_weight']!,
          _grossWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grossWeightMeta);
    }
    if (data.containsKey('tare_weight')) {
      context.handle(
        _tareWeightMeta,
        tareWeight.isAcceptableOrUnknown(data['tare_weight']!, _tareWeightMeta),
      );
    } else if (isInserting) {
      context.missing(_tareWeightMeta);
    }
    if (data.containsKey('net_weight')) {
      context.handle(
        _netWeightMeta,
        netWeight.isAcceptableOrUnknown(data['net_weight']!, _netWeightMeta),
      );
    } else if (isInserting) {
      context.missing(_netWeightMeta);
    }
    if (data.containsKey('piece_quantity')) {
      context.handle(
        _pieceQuantityMeta,
        pieceQuantity.isAcceptableOrUnknown(
          data['piece_quantity']!,
          _pieceQuantityMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('raw_reading_json')) {
      context.handle(
        _rawReadingJsonMeta,
        rawReadingJson.isAcceptableOrUnknown(
          data['raw_reading_json']!,
          _rawReadingJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawReadingJsonMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProductionTransaction map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProductionTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_scope'],
      )!,
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      )!,
      barcodeValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_value'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      ),
      inwardSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inward_session_id'],
      ),
      productSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_snapshot_json'],
      )!,
      dynamicValuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dynamic_values_json'],
      )!,
      grossWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gross_weight'],
      )!,
      tareWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tare_weight'],
      )!,
      netWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}net_weight'],
      )!,
      pieceQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}piece_quantity'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      rawReadingJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_reading_json'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
    );
  }

  @override
  $LocalProductionTransactionsTable createAlias(String alias) {
    return $LocalProductionTransactionsTable(attachedDatabase, alias);
  }
}

class LocalProductionTransaction extends DataClass
    implements Insertable<LocalProductionTransaction> {
  final String id;
  final String accountScope;
  final String serialNumber;
  final String barcodeValue;
  final String productId;
  final String? variantId;
  final String? inwardSessionId;
  final String productSnapshotJson;
  final String dynamicValuesJson;
  final double grossWeight;
  final double tareWeight;
  final double netWeight;
  final double? pieceQuantity;
  final String unit;
  final String status;
  final String syncStatus;
  final String idempotencyKey;
  final String rawReadingJson;
  final DateTime capturedAt;
  const LocalProductionTransaction({
    required this.id,
    required this.accountScope,
    required this.serialNumber,
    required this.barcodeValue,
    required this.productId,
    this.variantId,
    this.inwardSessionId,
    required this.productSnapshotJson,
    required this.dynamicValuesJson,
    required this.grossWeight,
    required this.tareWeight,
    required this.netWeight,
    this.pieceQuantity,
    required this.unit,
    required this.status,
    required this.syncStatus,
    required this.idempotencyKey,
    required this.rawReadingJson,
    required this.capturedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_scope'] = Variable<String>(accountScope);
    map['serial_number'] = Variable<String>(serialNumber);
    map['barcode_value'] = Variable<String>(barcodeValue);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || variantId != null) {
      map['variant_id'] = Variable<String>(variantId);
    }
    if (!nullToAbsent || inwardSessionId != null) {
      map['inward_session_id'] = Variable<String>(inwardSessionId);
    }
    map['product_snapshot_json'] = Variable<String>(productSnapshotJson);
    map['dynamic_values_json'] = Variable<String>(dynamicValuesJson);
    map['gross_weight'] = Variable<double>(grossWeight);
    map['tare_weight'] = Variable<double>(tareWeight);
    map['net_weight'] = Variable<double>(netWeight);
    if (!nullToAbsent || pieceQuantity != null) {
      map['piece_quantity'] = Variable<double>(pieceQuantity);
    }
    map['unit'] = Variable<String>(unit);
    map['status'] = Variable<String>(status);
    map['sync_status'] = Variable<String>(syncStatus);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['raw_reading_json'] = Variable<String>(rawReadingJson);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    return map;
  }

  LocalProductionTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalProductionTransactionsCompanion(
      id: Value(id),
      accountScope: Value(accountScope),
      serialNumber: Value(serialNumber),
      barcodeValue: Value(barcodeValue),
      productId: Value(productId),
      variantId: variantId == null && nullToAbsent
          ? const Value.absent()
          : Value(variantId),
      inwardSessionId: inwardSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(inwardSessionId),
      productSnapshotJson: Value(productSnapshotJson),
      dynamicValuesJson: Value(dynamicValuesJson),
      grossWeight: Value(grossWeight),
      tareWeight: Value(tareWeight),
      netWeight: Value(netWeight),
      pieceQuantity: pieceQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(pieceQuantity),
      unit: Value(unit),
      status: Value(status),
      syncStatus: Value(syncStatus),
      idempotencyKey: Value(idempotencyKey),
      rawReadingJson: Value(rawReadingJson),
      capturedAt: Value(capturedAt),
    );
  }

  factory LocalProductionTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProductionTransaction(
      id: serializer.fromJson<String>(json['id']),
      accountScope: serializer.fromJson<String>(json['accountScope']),
      serialNumber: serializer.fromJson<String>(json['serialNumber']),
      barcodeValue: serializer.fromJson<String>(json['barcodeValue']),
      productId: serializer.fromJson<String>(json['productId']),
      variantId: serializer.fromJson<String?>(json['variantId']),
      inwardSessionId: serializer.fromJson<String?>(json['inwardSessionId']),
      productSnapshotJson: serializer.fromJson<String>(
        json['productSnapshotJson'],
      ),
      dynamicValuesJson: serializer.fromJson<String>(json['dynamicValuesJson']),
      grossWeight: serializer.fromJson<double>(json['grossWeight']),
      tareWeight: serializer.fromJson<double>(json['tareWeight']),
      netWeight: serializer.fromJson<double>(json['netWeight']),
      pieceQuantity: serializer.fromJson<double?>(json['pieceQuantity']),
      unit: serializer.fromJson<String>(json['unit']),
      status: serializer.fromJson<String>(json['status']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      rawReadingJson: serializer.fromJson<String>(json['rawReadingJson']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountScope': serializer.toJson<String>(accountScope),
      'serialNumber': serializer.toJson<String>(serialNumber),
      'barcodeValue': serializer.toJson<String>(barcodeValue),
      'productId': serializer.toJson<String>(productId),
      'variantId': serializer.toJson<String?>(variantId),
      'inwardSessionId': serializer.toJson<String?>(inwardSessionId),
      'productSnapshotJson': serializer.toJson<String>(productSnapshotJson),
      'dynamicValuesJson': serializer.toJson<String>(dynamicValuesJson),
      'grossWeight': serializer.toJson<double>(grossWeight),
      'tareWeight': serializer.toJson<double>(tareWeight),
      'netWeight': serializer.toJson<double>(netWeight),
      'pieceQuantity': serializer.toJson<double?>(pieceQuantity),
      'unit': serializer.toJson<String>(unit),
      'status': serializer.toJson<String>(status),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'rawReadingJson': serializer.toJson<String>(rawReadingJson),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
    };
  }

  LocalProductionTransaction copyWith({
    String? id,
    String? accountScope,
    String? serialNumber,
    String? barcodeValue,
    String? productId,
    Value<String?> variantId = const Value.absent(),
    Value<String?> inwardSessionId = const Value.absent(),
    String? productSnapshotJson,
    String? dynamicValuesJson,
    double? grossWeight,
    double? tareWeight,
    double? netWeight,
    Value<double?> pieceQuantity = const Value.absent(),
    String? unit,
    String? status,
    String? syncStatus,
    String? idempotencyKey,
    String? rawReadingJson,
    DateTime? capturedAt,
  }) => LocalProductionTransaction(
    id: id ?? this.id,
    accountScope: accountScope ?? this.accountScope,
    serialNumber: serialNumber ?? this.serialNumber,
    barcodeValue: barcodeValue ?? this.barcodeValue,
    productId: productId ?? this.productId,
    variantId: variantId.present ? variantId.value : this.variantId,
    inwardSessionId: inwardSessionId.present
        ? inwardSessionId.value
        : this.inwardSessionId,
    productSnapshotJson: productSnapshotJson ?? this.productSnapshotJson,
    dynamicValuesJson: dynamicValuesJson ?? this.dynamicValuesJson,
    grossWeight: grossWeight ?? this.grossWeight,
    tareWeight: tareWeight ?? this.tareWeight,
    netWeight: netWeight ?? this.netWeight,
    pieceQuantity: pieceQuantity.present
        ? pieceQuantity.value
        : this.pieceQuantity,
    unit: unit ?? this.unit,
    status: status ?? this.status,
    syncStatus: syncStatus ?? this.syncStatus,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    rawReadingJson: rawReadingJson ?? this.rawReadingJson,
    capturedAt: capturedAt ?? this.capturedAt,
  );
  LocalProductionTransaction copyWithCompanion(
    LocalProductionTransactionsCompanion data,
  ) {
    return LocalProductionTransaction(
      id: data.id.present ? data.id.value : this.id,
      accountScope: data.accountScope.present
          ? data.accountScope.value
          : this.accountScope,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      barcodeValue: data.barcodeValue.present
          ? data.barcodeValue.value
          : this.barcodeValue,
      productId: data.productId.present ? data.productId.value : this.productId,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      inwardSessionId: data.inwardSessionId.present
          ? data.inwardSessionId.value
          : this.inwardSessionId,
      productSnapshotJson: data.productSnapshotJson.present
          ? data.productSnapshotJson.value
          : this.productSnapshotJson,
      dynamicValuesJson: data.dynamicValuesJson.present
          ? data.dynamicValuesJson.value
          : this.dynamicValuesJson,
      grossWeight: data.grossWeight.present
          ? data.grossWeight.value
          : this.grossWeight,
      tareWeight: data.tareWeight.present
          ? data.tareWeight.value
          : this.tareWeight,
      netWeight: data.netWeight.present ? data.netWeight.value : this.netWeight,
      pieceQuantity: data.pieceQuantity.present
          ? data.pieceQuantity.value
          : this.pieceQuantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      status: data.status.present ? data.status.value : this.status,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      rawReadingJson: data.rawReadingJson.present
          ? data.rawReadingJson.value
          : this.rawReadingJson,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductionTransaction(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('productId: $productId, ')
          ..write('variantId: $variantId, ')
          ..write('inwardSessionId: $inwardSessionId, ')
          ..write('productSnapshotJson: $productSnapshotJson, ')
          ..write('dynamicValuesJson: $dynamicValuesJson, ')
          ..write('grossWeight: $grossWeight, ')
          ..write('tareWeight: $tareWeight, ')
          ..write('netWeight: $netWeight, ')
          ..write('pieceQuantity: $pieceQuantity, ')
          ..write('unit: $unit, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('rawReadingJson: $rawReadingJson, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountScope,
    serialNumber,
    barcodeValue,
    productId,
    variantId,
    inwardSessionId,
    productSnapshotJson,
    dynamicValuesJson,
    grossWeight,
    tareWeight,
    netWeight,
    pieceQuantity,
    unit,
    status,
    syncStatus,
    idempotencyKey,
    rawReadingJson,
    capturedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProductionTransaction &&
          other.id == this.id &&
          other.accountScope == this.accountScope &&
          other.serialNumber == this.serialNumber &&
          other.barcodeValue == this.barcodeValue &&
          other.productId == this.productId &&
          other.variantId == this.variantId &&
          other.inwardSessionId == this.inwardSessionId &&
          other.productSnapshotJson == this.productSnapshotJson &&
          other.dynamicValuesJson == this.dynamicValuesJson &&
          other.grossWeight == this.grossWeight &&
          other.tareWeight == this.tareWeight &&
          other.netWeight == this.netWeight &&
          other.pieceQuantity == this.pieceQuantity &&
          other.unit == this.unit &&
          other.status == this.status &&
          other.syncStatus == this.syncStatus &&
          other.idempotencyKey == this.idempotencyKey &&
          other.rawReadingJson == this.rawReadingJson &&
          other.capturedAt == this.capturedAt);
}

class LocalProductionTransactionsCompanion
    extends UpdateCompanion<LocalProductionTransaction> {
  final Value<String> id;
  final Value<String> accountScope;
  final Value<String> serialNumber;
  final Value<String> barcodeValue;
  final Value<String> productId;
  final Value<String?> variantId;
  final Value<String?> inwardSessionId;
  final Value<String> productSnapshotJson;
  final Value<String> dynamicValuesJson;
  final Value<double> grossWeight;
  final Value<double> tareWeight;
  final Value<double> netWeight;
  final Value<double?> pieceQuantity;
  final Value<String> unit;
  final Value<String> status;
  final Value<String> syncStatus;
  final Value<String> idempotencyKey;
  final Value<String> rawReadingJson;
  final Value<DateTime> capturedAt;
  final Value<int> rowid;
  const LocalProductionTransactionsCompanion({
    this.id = const Value.absent(),
    this.accountScope = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.barcodeValue = const Value.absent(),
    this.productId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.inwardSessionId = const Value.absent(),
    this.productSnapshotJson = const Value.absent(),
    this.dynamicValuesJson = const Value.absent(),
    this.grossWeight = const Value.absent(),
    this.tareWeight = const Value.absent(),
    this.netWeight = const Value.absent(),
    this.pieceQuantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rawReadingJson = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductionTransactionsCompanion.insert({
    required String id,
    this.accountScope = const Value.absent(),
    required String serialNumber,
    required String barcodeValue,
    required String productId,
    this.variantId = const Value.absent(),
    this.inwardSessionId = const Value.absent(),
    required String productSnapshotJson,
    this.dynamicValuesJson = const Value.absent(),
    required double grossWeight,
    required double tareWeight,
    required double netWeight,
    this.pieceQuantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String idempotencyKey,
    required String rawReadingJson,
    required DateTime capturedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serialNumber = Value(serialNumber),
       barcodeValue = Value(barcodeValue),
       productId = Value(productId),
       productSnapshotJson = Value(productSnapshotJson),
       grossWeight = Value(grossWeight),
       tareWeight = Value(tareWeight),
       netWeight = Value(netWeight),
       idempotencyKey = Value(idempotencyKey),
       rawReadingJson = Value(rawReadingJson),
       capturedAt = Value(capturedAt);
  static Insertable<LocalProductionTransaction> custom({
    Expression<String>? id,
    Expression<String>? accountScope,
    Expression<String>? serialNumber,
    Expression<String>? barcodeValue,
    Expression<String>? productId,
    Expression<String>? variantId,
    Expression<String>? inwardSessionId,
    Expression<String>? productSnapshotJson,
    Expression<String>? dynamicValuesJson,
    Expression<double>? grossWeight,
    Expression<double>? tareWeight,
    Expression<double>? netWeight,
    Expression<double>? pieceQuantity,
    Expression<String>? unit,
    Expression<String>? status,
    Expression<String>? syncStatus,
    Expression<String>? idempotencyKey,
    Expression<String>? rawReadingJson,
    Expression<DateTime>? capturedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountScope != null) 'account_scope': accountScope,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (barcodeValue != null) 'barcode_value': barcodeValue,
      if (productId != null) 'product_id': productId,
      if (variantId != null) 'variant_id': variantId,
      if (inwardSessionId != null) 'inward_session_id': inwardSessionId,
      if (productSnapshotJson != null)
        'product_snapshot_json': productSnapshotJson,
      if (dynamicValuesJson != null) 'dynamic_values_json': dynamicValuesJson,
      if (grossWeight != null) 'gross_weight': grossWeight,
      if (tareWeight != null) 'tare_weight': tareWeight,
      if (netWeight != null) 'net_weight': netWeight,
      if (pieceQuantity != null) 'piece_quantity': pieceQuantity,
      if (unit != null) 'unit': unit,
      if (status != null) 'status': status,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (rawReadingJson != null) 'raw_reading_json': rawReadingJson,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductionTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountScope,
    Value<String>? serialNumber,
    Value<String>? barcodeValue,
    Value<String>? productId,
    Value<String?>? variantId,
    Value<String?>? inwardSessionId,
    Value<String>? productSnapshotJson,
    Value<String>? dynamicValuesJson,
    Value<double>? grossWeight,
    Value<double>? tareWeight,
    Value<double>? netWeight,
    Value<double?>? pieceQuantity,
    Value<String>? unit,
    Value<String>? status,
    Value<String>? syncStatus,
    Value<String>? idempotencyKey,
    Value<String>? rawReadingJson,
    Value<DateTime>? capturedAt,
    Value<int>? rowid,
  }) {
    return LocalProductionTransactionsCompanion(
      id: id ?? this.id,
      accountScope: accountScope ?? this.accountScope,
      serialNumber: serialNumber ?? this.serialNumber,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      inwardSessionId: inwardSessionId ?? this.inwardSessionId,
      productSnapshotJson: productSnapshotJson ?? this.productSnapshotJson,
      dynamicValuesJson: dynamicValuesJson ?? this.dynamicValuesJson,
      grossWeight: grossWeight ?? this.grossWeight,
      tareWeight: tareWeight ?? this.tareWeight,
      netWeight: netWeight ?? this.netWeight,
      pieceQuantity: pieceQuantity ?? this.pieceQuantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      rawReadingJson: rawReadingJson ?? this.rawReadingJson,
      capturedAt: capturedAt ?? this.capturedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountScope.present) {
      map['account_scope'] = Variable<String>(accountScope.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (barcodeValue.present) {
      map['barcode_value'] = Variable<String>(barcodeValue.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (inwardSessionId.present) {
      map['inward_session_id'] = Variable<String>(inwardSessionId.value);
    }
    if (productSnapshotJson.present) {
      map['product_snapshot_json'] = Variable<String>(
        productSnapshotJson.value,
      );
    }
    if (dynamicValuesJson.present) {
      map['dynamic_values_json'] = Variable<String>(dynamicValuesJson.value);
    }
    if (grossWeight.present) {
      map['gross_weight'] = Variable<double>(grossWeight.value);
    }
    if (tareWeight.present) {
      map['tare_weight'] = Variable<double>(tareWeight.value);
    }
    if (netWeight.present) {
      map['net_weight'] = Variable<double>(netWeight.value);
    }
    if (pieceQuantity.present) {
      map['piece_quantity'] = Variable<double>(pieceQuantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (rawReadingJson.present) {
      map['raw_reading_json'] = Variable<String>(rawReadingJson.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductionTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('productId: $productId, ')
          ..write('variantId: $variantId, ')
          ..write('inwardSessionId: $inwardSessionId, ')
          ..write('productSnapshotJson: $productSnapshotJson, ')
          ..write('dynamicValuesJson: $dynamicValuesJson, ')
          ..write('grossWeight: $grossWeight, ')
          ..write('tareWeight: $tareWeight, ')
          ..write('netWeight: $netWeight, ')
          ..write('pieceQuantity: $pieceQuantity, ')
          ..write('unit: $unit, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('rawReadingJson: $rawReadingJson, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalInventoryLedgerTable extends LocalInventoryLedger
    with TableInfo<$LocalInventoryLedgerTable, LocalInventoryLedgerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalInventoryLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountScopeMeta = const VerificationMeta(
    'accountScope',
  );
  @override
  late final GeneratedColumn<String> accountScope = GeneratedColumn<String>(
    'account_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeValueMeta = const VerificationMeta(
    'barcodeValue',
  );
  @override
  late final GeneratedColumn<String> barcodeValue = GeneratedColumn<String>(
    'barcode_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightQuantityMeta = const VerificationMeta(
    'weightQuantity',
  );
  @override
  late final GeneratedColumn<double> weightQuantity = GeneratedColumn<double>(
    'weight_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pieceQuantityMeta = const VerificationMeta(
    'pieceQuantity',
  );
  @override
  late final GeneratedColumn<double> pieceQuantity = GeneratedColumn<double>(
    'piece_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceTypeMeta = const VerificationMeta(
    'referenceType',
  );
  @override
  late final GeneratedColumn<String> referenceType = GeneratedColumn<String>(
    'reference_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceIdMeta = const VerificationMeta(
    'referenceId',
  );
  @override
  late final GeneratedColumn<String> referenceId = GeneratedColumn<String>(
    'reference_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountScope,
    productId,
    variantId,
    serialNumber,
    barcodeValue,
    transactionType,
    weightQuantity,
    pieceQuantity,
    referenceType,
    referenceId,
    syncStatus,
    occurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_inventory_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalInventoryLedgerData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_scope')) {
      context.handle(
        _accountScopeMeta,
        accountScope.isAcceptableOrUnknown(
          data['account_scope']!,
          _accountScopeMeta,
        ),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('barcode_value')) {
      context.handle(
        _barcodeValueMeta,
        barcodeValue.isAcceptableOrUnknown(
          data['barcode_value']!,
          _barcodeValueMeta,
        ),
      );
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('weight_quantity')) {
      context.handle(
        _weightQuantityMeta,
        weightQuantity.isAcceptableOrUnknown(
          data['weight_quantity']!,
          _weightQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weightQuantityMeta);
    }
    if (data.containsKey('piece_quantity')) {
      context.handle(
        _pieceQuantityMeta,
        pieceQuantity.isAcceptableOrUnknown(
          data['piece_quantity']!,
          _pieceQuantityMeta,
        ),
      );
    }
    if (data.containsKey('reference_type')) {
      context.handle(
        _referenceTypeMeta,
        referenceType.isAcceptableOrUnknown(
          data['reference_type']!,
          _referenceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceTypeMeta);
    }
    if (data.containsKey('reference_id')) {
      context.handle(
        _referenceIdMeta,
        referenceId.isAcceptableOrUnknown(
          data['reference_id']!,
          _referenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceIdMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalInventoryLedgerData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalInventoryLedgerData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_scope'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      ),
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
      barcodeValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_value'],
      ),
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      weightQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_quantity'],
      )!,
      pieceQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}piece_quantity'],
      ),
      referenceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_type'],
      )!,
      referenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_id'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
    );
  }

  @override
  $LocalInventoryLedgerTable createAlias(String alias) {
    return $LocalInventoryLedgerTable(attachedDatabase, alias);
  }
}

class LocalInventoryLedgerData extends DataClass
    implements Insertable<LocalInventoryLedgerData> {
  final String id;
  final String accountScope;
  final String productId;
  final String? variantId;
  final String? serialNumber;
  final String? barcodeValue;
  final String transactionType;
  final double weightQuantity;
  final double? pieceQuantity;
  final String referenceType;
  final String referenceId;
  final String syncStatus;
  final DateTime occurredAt;
  const LocalInventoryLedgerData({
    required this.id,
    required this.accountScope,
    required this.productId,
    this.variantId,
    this.serialNumber,
    this.barcodeValue,
    required this.transactionType,
    required this.weightQuantity,
    this.pieceQuantity,
    required this.referenceType,
    required this.referenceId,
    required this.syncStatus,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_scope'] = Variable<String>(accountScope);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || variantId != null) {
      map['variant_id'] = Variable<String>(variantId);
    }
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    if (!nullToAbsent || barcodeValue != null) {
      map['barcode_value'] = Variable<String>(barcodeValue);
    }
    map['transaction_type'] = Variable<String>(transactionType);
    map['weight_quantity'] = Variable<double>(weightQuantity);
    if (!nullToAbsent || pieceQuantity != null) {
      map['piece_quantity'] = Variable<double>(pieceQuantity);
    }
    map['reference_type'] = Variable<String>(referenceType);
    map['reference_id'] = Variable<String>(referenceId);
    map['sync_status'] = Variable<String>(syncStatus);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    return map;
  }

  LocalInventoryLedgerCompanion toCompanion(bool nullToAbsent) {
    return LocalInventoryLedgerCompanion(
      id: Value(id),
      accountScope: Value(accountScope),
      productId: Value(productId),
      variantId: variantId == null && nullToAbsent
          ? const Value.absent()
          : Value(variantId),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      barcodeValue: barcodeValue == null && nullToAbsent
          ? const Value.absent()
          : Value(barcodeValue),
      transactionType: Value(transactionType),
      weightQuantity: Value(weightQuantity),
      pieceQuantity: pieceQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(pieceQuantity),
      referenceType: Value(referenceType),
      referenceId: Value(referenceId),
      syncStatus: Value(syncStatus),
      occurredAt: Value(occurredAt),
    );
  }

  factory LocalInventoryLedgerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalInventoryLedgerData(
      id: serializer.fromJson<String>(json['id']),
      accountScope: serializer.fromJson<String>(json['accountScope']),
      productId: serializer.fromJson<String>(json['productId']),
      variantId: serializer.fromJson<String?>(json['variantId']),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      barcodeValue: serializer.fromJson<String?>(json['barcodeValue']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      weightQuantity: serializer.fromJson<double>(json['weightQuantity']),
      pieceQuantity: serializer.fromJson<double?>(json['pieceQuantity']),
      referenceType: serializer.fromJson<String>(json['referenceType']),
      referenceId: serializer.fromJson<String>(json['referenceId']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountScope': serializer.toJson<String>(accountScope),
      'productId': serializer.toJson<String>(productId),
      'variantId': serializer.toJson<String?>(variantId),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'barcodeValue': serializer.toJson<String?>(barcodeValue),
      'transactionType': serializer.toJson<String>(transactionType),
      'weightQuantity': serializer.toJson<double>(weightQuantity),
      'pieceQuantity': serializer.toJson<double?>(pieceQuantity),
      'referenceType': serializer.toJson<String>(referenceType),
      'referenceId': serializer.toJson<String>(referenceId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  LocalInventoryLedgerData copyWith({
    String? id,
    String? accountScope,
    String? productId,
    Value<String?> variantId = const Value.absent(),
    Value<String?> serialNumber = const Value.absent(),
    Value<String?> barcodeValue = const Value.absent(),
    String? transactionType,
    double? weightQuantity,
    Value<double?> pieceQuantity = const Value.absent(),
    String? referenceType,
    String? referenceId,
    String? syncStatus,
    DateTime? occurredAt,
  }) => LocalInventoryLedgerData(
    id: id ?? this.id,
    accountScope: accountScope ?? this.accountScope,
    productId: productId ?? this.productId,
    variantId: variantId.present ? variantId.value : this.variantId,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    barcodeValue: barcodeValue.present ? barcodeValue.value : this.barcodeValue,
    transactionType: transactionType ?? this.transactionType,
    weightQuantity: weightQuantity ?? this.weightQuantity,
    pieceQuantity: pieceQuantity.present
        ? pieceQuantity.value
        : this.pieceQuantity,
    referenceType: referenceType ?? this.referenceType,
    referenceId: referenceId ?? this.referenceId,
    syncStatus: syncStatus ?? this.syncStatus,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  LocalInventoryLedgerData copyWithCompanion(
    LocalInventoryLedgerCompanion data,
  ) {
    return LocalInventoryLedgerData(
      id: data.id.present ? data.id.value : this.id,
      accountScope: data.accountScope.present
          ? data.accountScope.value
          : this.accountScope,
      productId: data.productId.present ? data.productId.value : this.productId,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      barcodeValue: data.barcodeValue.present
          ? data.barcodeValue.value
          : this.barcodeValue,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      weightQuantity: data.weightQuantity.present
          ? data.weightQuantity.value
          : this.weightQuantity,
      pieceQuantity: data.pieceQuantity.present
          ? data.pieceQuantity.value
          : this.pieceQuantity,
      referenceType: data.referenceType.present
          ? data.referenceType.value
          : this.referenceType,
      referenceId: data.referenceId.present
          ? data.referenceId.value
          : this.referenceId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryLedgerData(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('productId: $productId, ')
          ..write('variantId: $variantId, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('transactionType: $transactionType, ')
          ..write('weightQuantity: $weightQuantity, ')
          ..write('pieceQuantity: $pieceQuantity, ')
          ..write('referenceType: $referenceType, ')
          ..write('referenceId: $referenceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountScope,
    productId,
    variantId,
    serialNumber,
    barcodeValue,
    transactionType,
    weightQuantity,
    pieceQuantity,
    referenceType,
    referenceId,
    syncStatus,
    occurredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalInventoryLedgerData &&
          other.id == this.id &&
          other.accountScope == this.accountScope &&
          other.productId == this.productId &&
          other.variantId == this.variantId &&
          other.serialNumber == this.serialNumber &&
          other.barcodeValue == this.barcodeValue &&
          other.transactionType == this.transactionType &&
          other.weightQuantity == this.weightQuantity &&
          other.pieceQuantity == this.pieceQuantity &&
          other.referenceType == this.referenceType &&
          other.referenceId == this.referenceId &&
          other.syncStatus == this.syncStatus &&
          other.occurredAt == this.occurredAt);
}

class LocalInventoryLedgerCompanion
    extends UpdateCompanion<LocalInventoryLedgerData> {
  final Value<String> id;
  final Value<String> accountScope;
  final Value<String> productId;
  final Value<String?> variantId;
  final Value<String?> serialNumber;
  final Value<String?> barcodeValue;
  final Value<String> transactionType;
  final Value<double> weightQuantity;
  final Value<double?> pieceQuantity;
  final Value<String> referenceType;
  final Value<String> referenceId;
  final Value<String> syncStatus;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const LocalInventoryLedgerCompanion({
    this.id = const Value.absent(),
    this.accountScope = const Value.absent(),
    this.productId = const Value.absent(),
    this.variantId = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.barcodeValue = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.weightQuantity = const Value.absent(),
    this.pieceQuantity = const Value.absent(),
    this.referenceType = const Value.absent(),
    this.referenceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalInventoryLedgerCompanion.insert({
    required String id,
    this.accountScope = const Value.absent(),
    required String productId,
    this.variantId = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.barcodeValue = const Value.absent(),
    required String transactionType,
    required double weightQuantity,
    this.pieceQuantity = const Value.absent(),
    required String referenceType,
    required String referenceId,
    this.syncStatus = const Value.absent(),
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       transactionType = Value(transactionType),
       weightQuantity = Value(weightQuantity),
       referenceType = Value(referenceType),
       referenceId = Value(referenceId),
       occurredAt = Value(occurredAt);
  static Insertable<LocalInventoryLedgerData> custom({
    Expression<String>? id,
    Expression<String>? accountScope,
    Expression<String>? productId,
    Expression<String>? variantId,
    Expression<String>? serialNumber,
    Expression<String>? barcodeValue,
    Expression<String>? transactionType,
    Expression<double>? weightQuantity,
    Expression<double>? pieceQuantity,
    Expression<String>? referenceType,
    Expression<String>? referenceId,
    Expression<String>? syncStatus,
    Expression<DateTime>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountScope != null) 'account_scope': accountScope,
      if (productId != null) 'product_id': productId,
      if (variantId != null) 'variant_id': variantId,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (barcodeValue != null) 'barcode_value': barcodeValue,
      if (transactionType != null) 'transaction_type': transactionType,
      if (weightQuantity != null) 'weight_quantity': weightQuantity,
      if (pieceQuantity != null) 'piece_quantity': pieceQuantity,
      if (referenceType != null) 'reference_type': referenceType,
      if (referenceId != null) 'reference_id': referenceId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalInventoryLedgerCompanion copyWith({
    Value<String>? id,
    Value<String>? accountScope,
    Value<String>? productId,
    Value<String?>? variantId,
    Value<String?>? serialNumber,
    Value<String?>? barcodeValue,
    Value<String>? transactionType,
    Value<double>? weightQuantity,
    Value<double?>? pieceQuantity,
    Value<String>? referenceType,
    Value<String>? referenceId,
    Value<String>? syncStatus,
    Value<DateTime>? occurredAt,
    Value<int>? rowid,
  }) {
    return LocalInventoryLedgerCompanion(
      id: id ?? this.id,
      accountScope: accountScope ?? this.accountScope,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      serialNumber: serialNumber ?? this.serialNumber,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      transactionType: transactionType ?? this.transactionType,
      weightQuantity: weightQuantity ?? this.weightQuantity,
      pieceQuantity: pieceQuantity ?? this.pieceQuantity,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      syncStatus: syncStatus ?? this.syncStatus,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountScope.present) {
      map['account_scope'] = Variable<String>(accountScope.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (barcodeValue.present) {
      map['barcode_value'] = Variable<String>(barcodeValue.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (weightQuantity.present) {
      map['weight_quantity'] = Variable<double>(weightQuantity.value);
    }
    if (pieceQuantity.present) {
      map['piece_quantity'] = Variable<double>(pieceQuantity.value);
    }
    if (referenceType.present) {
      map['reference_type'] = Variable<String>(referenceType.value);
    }
    if (referenceId.present) {
      map['reference_id'] = Variable<String>(referenceId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalInventoryLedgerCompanion(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('productId: $productId, ')
          ..write('variantId: $variantId, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('transactionType: $transactionType, ')
          ..write('weightQuantity: $weightQuantity, ')
          ..write('pieceQuantity: $pieceQuantity, ')
          ..write('referenceType: $referenceType, ')
          ..write('referenceId: $referenceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCustomersTable extends LocalCustomers
    with TableInfo<$LocalCustomersTable, LocalCustomer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, code, payloadJson, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCustomer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCustomer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCustomer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $LocalCustomersTable createAlias(String alias) {
    return $LocalCustomersTable(attachedDatabase, alias);
  }
}

class LocalCustomer extends DataClass implements Insertable<LocalCustomer> {
  final String id;
  final String name;
  final String? code;
  final String payloadJson;
  final bool isActive;
  const LocalCustomer({
    required this.id,
    required this.name,
    this.code,
    required this.payloadJson,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LocalCustomersCompanion toCompanion(bool nullToAbsent) {
    return LocalCustomersCompanion(
      id: Value(id),
      name: Value(name),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      payloadJson: Value(payloadJson),
      isActive: Value(isActive),
    );
  }

  factory LocalCustomer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCustomer(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String?>(json['code']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String?>(code),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  LocalCustomer copyWith({
    String? id,
    String? name,
    Value<String?> code = const Value.absent(),
    String? payloadJson,
    bool? isActive,
  }) => LocalCustomer(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code.present ? code.value : this.code,
    payloadJson: payloadJson ?? this.payloadJson,
    isActive: isActive ?? this.isActive,
  );
  LocalCustomer copyWithCompanion(LocalCustomersCompanion data) {
    return LocalCustomer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCustomer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, code, payloadJson, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCustomer &&
          other.id == this.id &&
          other.name == this.name &&
          other.code == this.code &&
          other.payloadJson == this.payloadJson &&
          other.isActive == this.isActive);
}

class LocalCustomersCompanion extends UpdateCompanion<LocalCustomer> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> code;
  final Value<String> payloadJson;
  final Value<bool> isActive;
  final Value<int> rowid;
  const LocalCustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCustomersCompanion.insert({
    required String id,
    required String name,
    this.code = const Value.absent(),
    required String payloadJson,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       payloadJson = Value(payloadJson);
  static Insertable<LocalCustomer> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? payloadJson,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? code,
    Value<String>? payloadJson,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return LocalCustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      payloadJson: payloadJson ?? this.payloadJson,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDispatchesTable extends LocalDispatches
    with TableInfo<$LocalDispatchesTable, LocalDispatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDispatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountScopeMeta = const VerificationMeta(
    'accountScope',
  );
  @override
  late final GeneratedColumn<String> accountScope = GeneratedColumn<String>(
    'account_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _dispatchNumberMeta = const VerificationMeta(
    'dispatchNumber',
  );
  @override
  late final GeneratedColumn<String> dispatchNumber = GeneratedColumn<String>(
    'dispatch_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerSnapshotJsonMeta =
      const VerificationMeta('customerSnapshotJson');
  @override
  late final GeneratedColumn<String> customerSnapshotJson =
      GeneratedColumn<String>(
        'customer_snapshot_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _totalWeightMeta = const VerificationMeta(
    'totalWeight',
  );
  @override
  late final GeneratedColumn<double> totalWeight = GeneratedColumn<double>(
    'total_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPiecesMeta = const VerificationMeta(
    'totalPieces',
  );
  @override
  late final GeneratedColumn<double> totalPieces = GeneratedColumn<double>(
    'total_pieces',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountScope,
    dispatchNumber,
    customerId,
    customerSnapshotJson,
    status,
    totalWeight,
    totalPieces,
    syncStatus,
    idempotencyKey,
    createdAt,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_dispatches';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDispatche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_scope')) {
      context.handle(
        _accountScopeMeta,
        accountScope.isAcceptableOrUnknown(
          data['account_scope']!,
          _accountScopeMeta,
        ),
      );
    }
    if (data.containsKey('dispatch_number')) {
      context.handle(
        _dispatchNumberMeta,
        dispatchNumber.isAcceptableOrUnknown(
          data['dispatch_number']!,
          _dispatchNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dispatchNumberMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('customer_snapshot_json')) {
      context.handle(
        _customerSnapshotJsonMeta,
        customerSnapshotJson.isAcceptableOrUnknown(
          data['customer_snapshot_json']!,
          _customerSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerSnapshotJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('total_weight')) {
      context.handle(
        _totalWeightMeta,
        totalWeight.isAcceptableOrUnknown(
          data['total_weight']!,
          _totalWeightMeta,
        ),
      );
    }
    if (data.containsKey('total_pieces')) {
      context.handle(
        _totalPiecesMeta,
        totalPieces.isAcceptableOrUnknown(
          data['total_pieces']!,
          _totalPiecesMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDispatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDispatche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_scope'],
      )!,
      dispatchNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispatch_number'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      customerSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_snapshot_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_weight'],
      )!,
      totalPieces: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_pieces'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $LocalDispatchesTable createAlias(String alias) {
    return $LocalDispatchesTable(attachedDatabase, alias);
  }
}

class LocalDispatche extends DataClass implements Insertable<LocalDispatche> {
  final String id;
  final String accountScope;
  final String dispatchNumber;
  final String customerId;
  final String customerSnapshotJson;
  final String status;
  final double totalWeight;
  final double? totalPieces;
  final String syncStatus;
  final String idempotencyKey;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  const LocalDispatche({
    required this.id,
    required this.accountScope,
    required this.dispatchNumber,
    required this.customerId,
    required this.customerSnapshotJson,
    required this.status,
    required this.totalWeight,
    this.totalPieces,
    required this.syncStatus,
    required this.idempotencyKey,
    required this.createdAt,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_scope'] = Variable<String>(accountScope);
    map['dispatch_number'] = Variable<String>(dispatchNumber);
    map['customer_id'] = Variable<String>(customerId);
    map['customer_snapshot_json'] = Variable<String>(customerSnapshotJson);
    map['status'] = Variable<String>(status);
    map['total_weight'] = Variable<double>(totalWeight);
    if (!nullToAbsent || totalPieces != null) {
      map['total_pieces'] = Variable<double>(totalPieces);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  LocalDispatchesCompanion toCompanion(bool nullToAbsent) {
    return LocalDispatchesCompanion(
      id: Value(id),
      accountScope: Value(accountScope),
      dispatchNumber: Value(dispatchNumber),
      customerId: Value(customerId),
      customerSnapshotJson: Value(customerSnapshotJson),
      status: Value(status),
      totalWeight: Value(totalWeight),
      totalPieces: totalPieces == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPieces),
      syncStatus: Value(syncStatus),
      idempotencyKey: Value(idempotencyKey),
      createdAt: Value(createdAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory LocalDispatche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDispatche(
      id: serializer.fromJson<String>(json['id']),
      accountScope: serializer.fromJson<String>(json['accountScope']),
      dispatchNumber: serializer.fromJson<String>(json['dispatchNumber']),
      customerId: serializer.fromJson<String>(json['customerId']),
      customerSnapshotJson: serializer.fromJson<String>(
        json['customerSnapshotJson'],
      ),
      status: serializer.fromJson<String>(json['status']),
      totalWeight: serializer.fromJson<double>(json['totalWeight']),
      totalPieces: serializer.fromJson<double?>(json['totalPieces']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountScope': serializer.toJson<String>(accountScope),
      'dispatchNumber': serializer.toJson<String>(dispatchNumber),
      'customerId': serializer.toJson<String>(customerId),
      'customerSnapshotJson': serializer.toJson<String>(customerSnapshotJson),
      'status': serializer.toJson<String>(status),
      'totalWeight': serializer.toJson<double>(totalWeight),
      'totalPieces': serializer.toJson<double?>(totalPieces),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  LocalDispatche copyWith({
    String? id,
    String? accountScope,
    String? dispatchNumber,
    String? customerId,
    String? customerSnapshotJson,
    String? status,
    double? totalWeight,
    Value<double?> totalPieces = const Value.absent(),
    String? syncStatus,
    String? idempotencyKey,
    DateTime? createdAt,
    Value<DateTime?> confirmedAt = const Value.absent(),
  }) => LocalDispatche(
    id: id ?? this.id,
    accountScope: accountScope ?? this.accountScope,
    dispatchNumber: dispatchNumber ?? this.dispatchNumber,
    customerId: customerId ?? this.customerId,
    customerSnapshotJson: customerSnapshotJson ?? this.customerSnapshotJson,
    status: status ?? this.status,
    totalWeight: totalWeight ?? this.totalWeight,
    totalPieces: totalPieces.present ? totalPieces.value : this.totalPieces,
    syncStatus: syncStatus ?? this.syncStatus,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    createdAt: createdAt ?? this.createdAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  LocalDispatche copyWithCompanion(LocalDispatchesCompanion data) {
    return LocalDispatche(
      id: data.id.present ? data.id.value : this.id,
      accountScope: data.accountScope.present
          ? data.accountScope.value
          : this.accountScope,
      dispatchNumber: data.dispatchNumber.present
          ? data.dispatchNumber.value
          : this.dispatchNumber,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      customerSnapshotJson: data.customerSnapshotJson.present
          ? data.customerSnapshotJson.value
          : this.customerSnapshotJson,
      status: data.status.present ? data.status.value : this.status,
      totalWeight: data.totalWeight.present
          ? data.totalWeight.value
          : this.totalWeight,
      totalPieces: data.totalPieces.present
          ? data.totalPieces.value
          : this.totalPieces,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDispatche(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('dispatchNumber: $dispatchNumber, ')
          ..write('customerId: $customerId, ')
          ..write('customerSnapshotJson: $customerSnapshotJson, ')
          ..write('status: $status, ')
          ..write('totalWeight: $totalWeight, ')
          ..write('totalPieces: $totalPieces, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountScope,
    dispatchNumber,
    customerId,
    customerSnapshotJson,
    status,
    totalWeight,
    totalPieces,
    syncStatus,
    idempotencyKey,
    createdAt,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDispatche &&
          other.id == this.id &&
          other.accountScope == this.accountScope &&
          other.dispatchNumber == this.dispatchNumber &&
          other.customerId == this.customerId &&
          other.customerSnapshotJson == this.customerSnapshotJson &&
          other.status == this.status &&
          other.totalWeight == this.totalWeight &&
          other.totalPieces == this.totalPieces &&
          other.syncStatus == this.syncStatus &&
          other.idempotencyKey == this.idempotencyKey &&
          other.createdAt == this.createdAt &&
          other.confirmedAt == this.confirmedAt);
}

class LocalDispatchesCompanion extends UpdateCompanion<LocalDispatche> {
  final Value<String> id;
  final Value<String> accountScope;
  final Value<String> dispatchNumber;
  final Value<String> customerId;
  final Value<String> customerSnapshotJson;
  final Value<String> status;
  final Value<double> totalWeight;
  final Value<double?> totalPieces;
  final Value<String> syncStatus;
  final Value<String> idempotencyKey;
  final Value<DateTime> createdAt;
  final Value<DateTime?> confirmedAt;
  final Value<int> rowid;
  const LocalDispatchesCompanion({
    this.id = const Value.absent(),
    this.accountScope = const Value.absent(),
    this.dispatchNumber = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerSnapshotJson = const Value.absent(),
    this.status = const Value.absent(),
    this.totalWeight = const Value.absent(),
    this.totalPieces = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDispatchesCompanion.insert({
    required String id,
    this.accountScope = const Value.absent(),
    required String dispatchNumber,
    required String customerId,
    required String customerSnapshotJson,
    this.status = const Value.absent(),
    this.totalWeight = const Value.absent(),
    this.totalPieces = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String idempotencyKey,
    required DateTime createdAt,
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dispatchNumber = Value(dispatchNumber),
       customerId = Value(customerId),
       customerSnapshotJson = Value(customerSnapshotJson),
       idempotencyKey = Value(idempotencyKey),
       createdAt = Value(createdAt);
  static Insertable<LocalDispatche> custom({
    Expression<String>? id,
    Expression<String>? accountScope,
    Expression<String>? dispatchNumber,
    Expression<String>? customerId,
    Expression<String>? customerSnapshotJson,
    Expression<String>? status,
    Expression<double>? totalWeight,
    Expression<double>? totalPieces,
    Expression<String>? syncStatus,
    Expression<String>? idempotencyKey,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? confirmedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountScope != null) 'account_scope': accountScope,
      if (dispatchNumber != null) 'dispatch_number': dispatchNumber,
      if (customerId != null) 'customer_id': customerId,
      if (customerSnapshotJson != null)
        'customer_snapshot_json': customerSnapshotJson,
      if (status != null) 'status': status,
      if (totalWeight != null) 'total_weight': totalWeight,
      if (totalPieces != null) 'total_pieces': totalPieces,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (createdAt != null) 'created_at': createdAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDispatchesCompanion copyWith({
    Value<String>? id,
    Value<String>? accountScope,
    Value<String>? dispatchNumber,
    Value<String>? customerId,
    Value<String>? customerSnapshotJson,
    Value<String>? status,
    Value<double>? totalWeight,
    Value<double?>? totalPieces,
    Value<String>? syncStatus,
    Value<String>? idempotencyKey,
    Value<DateTime>? createdAt,
    Value<DateTime?>? confirmedAt,
    Value<int>? rowid,
  }) {
    return LocalDispatchesCompanion(
      id: id ?? this.id,
      accountScope: accountScope ?? this.accountScope,
      dispatchNumber: dispatchNumber ?? this.dispatchNumber,
      customerId: customerId ?? this.customerId,
      customerSnapshotJson: customerSnapshotJson ?? this.customerSnapshotJson,
      status: status ?? this.status,
      totalWeight: totalWeight ?? this.totalWeight,
      totalPieces: totalPieces ?? this.totalPieces,
      syncStatus: syncStatus ?? this.syncStatus,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountScope.present) {
      map['account_scope'] = Variable<String>(accountScope.value);
    }
    if (dispatchNumber.present) {
      map['dispatch_number'] = Variable<String>(dispatchNumber.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerSnapshotJson.present) {
      map['customer_snapshot_json'] = Variable<String>(
        customerSnapshotJson.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalWeight.present) {
      map['total_weight'] = Variable<double>(totalWeight.value);
    }
    if (totalPieces.present) {
      map['total_pieces'] = Variable<double>(totalPieces.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDispatchesCompanion(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('dispatchNumber: $dispatchNumber, ')
          ..write('customerId: $customerId, ')
          ..write('customerSnapshotJson: $customerSnapshotJson, ')
          ..write('status: $status, ')
          ..write('totalWeight: $totalWeight, ')
          ..write('totalPieces: $totalPieces, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDispatchItemsTable extends LocalDispatchItems
    with TableInfo<$LocalDispatchItemsTable, LocalDispatchItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDispatchItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountScopeMeta = const VerificationMeta(
    'accountScope',
  );
  @override
  late final GeneratedColumn<String> accountScope = GeneratedColumn<String>(
    'account_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _dispatchIdMeta = const VerificationMeta(
    'dispatchId',
  );
  @override
  late final GeneratedColumn<String> dispatchId = GeneratedColumn<String>(
    'dispatch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productionTransactionIdMeta =
      const VerificationMeta('productionTransactionId');
  @override
  late final GeneratedColumn<String> productionTransactionId =
      GeneratedColumn<String>(
        'production_transaction_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _barcodeValueMeta = const VerificationMeta(
    'barcodeValue',
  );
  @override
  late final GeneratedColumn<String> barcodeValue = GeneratedColumn<String>(
    'barcode_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightQuantityMeta = const VerificationMeta(
    'weightQuantity',
  );
  @override
  late final GeneratedColumn<double> weightQuantity = GeneratedColumn<double>(
    'weight_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pieceQuantityMeta = const VerificationMeta(
    'pieceQuantity',
  );
  @override
  late final GeneratedColumn<double> pieceQuantity = GeneratedColumn<double>(
    'piece_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountScope,
    dispatchId,
    productionTransactionId,
    barcodeValue,
    weightQuantity,
    pieceQuantity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_dispatch_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDispatchItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_scope')) {
      context.handle(
        _accountScopeMeta,
        accountScope.isAcceptableOrUnknown(
          data['account_scope']!,
          _accountScopeMeta,
        ),
      );
    }
    if (data.containsKey('dispatch_id')) {
      context.handle(
        _dispatchIdMeta,
        dispatchId.isAcceptableOrUnknown(data['dispatch_id']!, _dispatchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dispatchIdMeta);
    }
    if (data.containsKey('production_transaction_id')) {
      context.handle(
        _productionTransactionIdMeta,
        productionTransactionId.isAcceptableOrUnknown(
          data['production_transaction_id']!,
          _productionTransactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productionTransactionIdMeta);
    }
    if (data.containsKey('barcode_value')) {
      context.handle(
        _barcodeValueMeta,
        barcodeValue.isAcceptableOrUnknown(
          data['barcode_value']!,
          _barcodeValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_barcodeValueMeta);
    }
    if (data.containsKey('weight_quantity')) {
      context.handle(
        _weightQuantityMeta,
        weightQuantity.isAcceptableOrUnknown(
          data['weight_quantity']!,
          _weightQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weightQuantityMeta);
    }
    if (data.containsKey('piece_quantity')) {
      context.handle(
        _pieceQuantityMeta,
        pieceQuantity.isAcceptableOrUnknown(
          data['piece_quantity']!,
          _pieceQuantityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDispatchItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDispatchItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_scope'],
      )!,
      dispatchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispatch_id'],
      )!,
      productionTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}production_transaction_id'],
      )!,
      barcodeValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_value'],
      )!,
      weightQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_quantity'],
      )!,
      pieceQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}piece_quantity'],
      ),
    );
  }

  @override
  $LocalDispatchItemsTable createAlias(String alias) {
    return $LocalDispatchItemsTable(attachedDatabase, alias);
  }
}

class LocalDispatchItem extends DataClass
    implements Insertable<LocalDispatchItem> {
  final String id;
  final String accountScope;
  final String dispatchId;
  final String productionTransactionId;
  final String barcodeValue;
  final double weightQuantity;
  final double? pieceQuantity;
  const LocalDispatchItem({
    required this.id,
    required this.accountScope,
    required this.dispatchId,
    required this.productionTransactionId,
    required this.barcodeValue,
    required this.weightQuantity,
    this.pieceQuantity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_scope'] = Variable<String>(accountScope);
    map['dispatch_id'] = Variable<String>(dispatchId);
    map['production_transaction_id'] = Variable<String>(
      productionTransactionId,
    );
    map['barcode_value'] = Variable<String>(barcodeValue);
    map['weight_quantity'] = Variable<double>(weightQuantity);
    if (!nullToAbsent || pieceQuantity != null) {
      map['piece_quantity'] = Variable<double>(pieceQuantity);
    }
    return map;
  }

  LocalDispatchItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalDispatchItemsCompanion(
      id: Value(id),
      accountScope: Value(accountScope),
      dispatchId: Value(dispatchId),
      productionTransactionId: Value(productionTransactionId),
      barcodeValue: Value(barcodeValue),
      weightQuantity: Value(weightQuantity),
      pieceQuantity: pieceQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(pieceQuantity),
    );
  }

  factory LocalDispatchItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDispatchItem(
      id: serializer.fromJson<String>(json['id']),
      accountScope: serializer.fromJson<String>(json['accountScope']),
      dispatchId: serializer.fromJson<String>(json['dispatchId']),
      productionTransactionId: serializer.fromJson<String>(
        json['productionTransactionId'],
      ),
      barcodeValue: serializer.fromJson<String>(json['barcodeValue']),
      weightQuantity: serializer.fromJson<double>(json['weightQuantity']),
      pieceQuantity: serializer.fromJson<double?>(json['pieceQuantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountScope': serializer.toJson<String>(accountScope),
      'dispatchId': serializer.toJson<String>(dispatchId),
      'productionTransactionId': serializer.toJson<String>(
        productionTransactionId,
      ),
      'barcodeValue': serializer.toJson<String>(barcodeValue),
      'weightQuantity': serializer.toJson<double>(weightQuantity),
      'pieceQuantity': serializer.toJson<double?>(pieceQuantity),
    };
  }

  LocalDispatchItem copyWith({
    String? id,
    String? accountScope,
    String? dispatchId,
    String? productionTransactionId,
    String? barcodeValue,
    double? weightQuantity,
    Value<double?> pieceQuantity = const Value.absent(),
  }) => LocalDispatchItem(
    id: id ?? this.id,
    accountScope: accountScope ?? this.accountScope,
    dispatchId: dispatchId ?? this.dispatchId,
    productionTransactionId:
        productionTransactionId ?? this.productionTransactionId,
    barcodeValue: barcodeValue ?? this.barcodeValue,
    weightQuantity: weightQuantity ?? this.weightQuantity,
    pieceQuantity: pieceQuantity.present
        ? pieceQuantity.value
        : this.pieceQuantity,
  );
  LocalDispatchItem copyWithCompanion(LocalDispatchItemsCompanion data) {
    return LocalDispatchItem(
      id: data.id.present ? data.id.value : this.id,
      accountScope: data.accountScope.present
          ? data.accountScope.value
          : this.accountScope,
      dispatchId: data.dispatchId.present
          ? data.dispatchId.value
          : this.dispatchId,
      productionTransactionId: data.productionTransactionId.present
          ? data.productionTransactionId.value
          : this.productionTransactionId,
      barcodeValue: data.barcodeValue.present
          ? data.barcodeValue.value
          : this.barcodeValue,
      weightQuantity: data.weightQuantity.present
          ? data.weightQuantity.value
          : this.weightQuantity,
      pieceQuantity: data.pieceQuantity.present
          ? data.pieceQuantity.value
          : this.pieceQuantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDispatchItem(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('dispatchId: $dispatchId, ')
          ..write('productionTransactionId: $productionTransactionId, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('weightQuantity: $weightQuantity, ')
          ..write('pieceQuantity: $pieceQuantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountScope,
    dispatchId,
    productionTransactionId,
    barcodeValue,
    weightQuantity,
    pieceQuantity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDispatchItem &&
          other.id == this.id &&
          other.accountScope == this.accountScope &&
          other.dispatchId == this.dispatchId &&
          other.productionTransactionId == this.productionTransactionId &&
          other.barcodeValue == this.barcodeValue &&
          other.weightQuantity == this.weightQuantity &&
          other.pieceQuantity == this.pieceQuantity);
}

class LocalDispatchItemsCompanion extends UpdateCompanion<LocalDispatchItem> {
  final Value<String> id;
  final Value<String> accountScope;
  final Value<String> dispatchId;
  final Value<String> productionTransactionId;
  final Value<String> barcodeValue;
  final Value<double> weightQuantity;
  final Value<double?> pieceQuantity;
  final Value<int> rowid;
  const LocalDispatchItemsCompanion({
    this.id = const Value.absent(),
    this.accountScope = const Value.absent(),
    this.dispatchId = const Value.absent(),
    this.productionTransactionId = const Value.absent(),
    this.barcodeValue = const Value.absent(),
    this.weightQuantity = const Value.absent(),
    this.pieceQuantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDispatchItemsCompanion.insert({
    required String id,
    this.accountScope = const Value.absent(),
    required String dispatchId,
    required String productionTransactionId,
    required String barcodeValue,
    required double weightQuantity,
    this.pieceQuantity = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dispatchId = Value(dispatchId),
       productionTransactionId = Value(productionTransactionId),
       barcodeValue = Value(barcodeValue),
       weightQuantity = Value(weightQuantity);
  static Insertable<LocalDispatchItem> custom({
    Expression<String>? id,
    Expression<String>? accountScope,
    Expression<String>? dispatchId,
    Expression<String>? productionTransactionId,
    Expression<String>? barcodeValue,
    Expression<double>? weightQuantity,
    Expression<double>? pieceQuantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountScope != null) 'account_scope': accountScope,
      if (dispatchId != null) 'dispatch_id': dispatchId,
      if (productionTransactionId != null)
        'production_transaction_id': productionTransactionId,
      if (barcodeValue != null) 'barcode_value': barcodeValue,
      if (weightQuantity != null) 'weight_quantity': weightQuantity,
      if (pieceQuantity != null) 'piece_quantity': pieceQuantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDispatchItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountScope,
    Value<String>? dispatchId,
    Value<String>? productionTransactionId,
    Value<String>? barcodeValue,
    Value<double>? weightQuantity,
    Value<double?>? pieceQuantity,
    Value<int>? rowid,
  }) {
    return LocalDispatchItemsCompanion(
      id: id ?? this.id,
      accountScope: accountScope ?? this.accountScope,
      dispatchId: dispatchId ?? this.dispatchId,
      productionTransactionId:
          productionTransactionId ?? this.productionTransactionId,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      weightQuantity: weightQuantity ?? this.weightQuantity,
      pieceQuantity: pieceQuantity ?? this.pieceQuantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountScope.present) {
      map['account_scope'] = Variable<String>(accountScope.value);
    }
    if (dispatchId.present) {
      map['dispatch_id'] = Variable<String>(dispatchId.value);
    }
    if (productionTransactionId.present) {
      map['production_transaction_id'] = Variable<String>(
        productionTransactionId.value,
      );
    }
    if (barcodeValue.present) {
      map['barcode_value'] = Variable<String>(barcodeValue.value);
    }
    if (weightQuantity.present) {
      map['weight_quantity'] = Variable<double>(weightQuantity.value);
    }
    if (pieceQuantity.present) {
      map['piece_quantity'] = Variable<double>(pieceQuantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDispatchItemsCompanion(')
          ..write('id: $id, ')
          ..write('accountScope: $accountScope, ')
          ..write('dispatchId: $dispatchId, ')
          ..write('productionTransactionId: $productionTransactionId, ')
          ..write('barcodeValue: $barcodeValue, ')
          ..write('weightQuantity: $weightQuantity, ')
          ..write('pieceQuantity: $pieceQuantity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $LocalSyncQueueTable localSyncQueue = $LocalSyncQueueTable(this);
  late final $LocalConfigurationVersionsTable localConfigurationVersions =
      $LocalConfigurationVersionsTable(this);
  late final $LocalProductsTable localProducts = $LocalProductsTable(this);
  late final $LocalProductVariantsTable localProductVariants =
      $LocalProductVariantsTable(this);
  late final $LocalDynamicFieldsTable localDynamicFields =
      $LocalDynamicFieldsTable(this);
  late final $LocalLabelTemplatesTable localLabelTemplates =
      $LocalLabelTemplatesTable(this);
  late final $LocalScaleProfilesTable localScaleProfiles =
      $LocalScaleProfilesTable(this);
  late final $LocalInwardSessionsTable localInwardSessions =
      $LocalInwardSessionsTable(this);
  late final $LocalProductionTransactionsTable localProductionTransactions =
      $LocalProductionTransactionsTable(this);
  late final $LocalInventoryLedgerTable localInventoryLedger =
      $LocalInventoryLedgerTable(this);
  late final $LocalCustomersTable localCustomers = $LocalCustomersTable(this);
  late final $LocalDispatchesTable localDispatches = $LocalDispatchesTable(
    this,
  );
  late final $LocalDispatchItemsTable localDispatchItems =
      $LocalDispatchItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localSyncQueue,
    localConfigurationVersions,
    localProducts,
    localProductVariants,
    localDynamicFields,
    localLabelTemplates,
    localScaleProfiles,
    localInwardSessions,
    localProductionTransactions,
    localInventoryLedger,
    localCustomers,
    localDispatches,
    localDispatchItems,
  ];
}

typedef $$LocalSyncQueueTableCreateCompanionBuilder =
    LocalSyncQueueCompanion Function({
      required String id,
      Value<String> accountScope,
      required String entityType,
      required String operation,
      required String idempotencyKey,
      required String payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalSyncQueueTableUpdateCompanionBuilder =
    LocalSyncQueueCompanion Function({
      Value<String> id,
      Value<String> accountScope,
      Value<String> entityType,
      Value<String> operation,
      Value<String> idempotencyKey,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalSyncQueueTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalSyncQueueTable> {
  $$LocalSyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncQueueTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalSyncQueueTable> {
  $$LocalSyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncQueueTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalSyncQueueTable> {
  $$LocalSyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalSyncQueueTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalSyncQueueTable,
          LocalSyncQueueData,
          $$LocalSyncQueueTableFilterComposer,
          $$LocalSyncQueueTableOrderingComposer,
          $$LocalSyncQueueTableAnnotationComposer,
          $$LocalSyncQueueTableCreateCompanionBuilder,
          $$LocalSyncQueueTableUpdateCompanionBuilder,
          (
            LocalSyncQueueData,
            BaseReferences<
              _$LocalDatabase,
              $LocalSyncQueueTable,
              LocalSyncQueueData
            >,
          ),
          LocalSyncQueueData,
          PrefetchHooks Function()
        > {
  $$LocalSyncQueueTableTableManager(
    _$LocalDatabase db,
    $LocalSyncQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountScope = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncQueueCompanion(
                id: id,
                accountScope: accountScope,
                entityType: entityType,
                operation: operation,
                idempotencyKey: idempotencyKey,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> accountScope = const Value.absent(),
                required String entityType,
                required String operation,
                required String idempotencyKey,
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncQueueCompanion.insert(
                id: id,
                accountScope: accountScope,
                entityType: entityType,
                operation: operation,
                idempotencyKey: idempotencyKey,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalSyncQueueTable,
      LocalSyncQueueData,
      $$LocalSyncQueueTableFilterComposer,
      $$LocalSyncQueueTableOrderingComposer,
      $$LocalSyncQueueTableAnnotationComposer,
      $$LocalSyncQueueTableCreateCompanionBuilder,
      $$LocalSyncQueueTableUpdateCompanionBuilder,
      (
        LocalSyncQueueData,
        BaseReferences<
          _$LocalDatabase,
          $LocalSyncQueueTable,
          LocalSyncQueueData
        >,
      ),
      LocalSyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$LocalConfigurationVersionsTableCreateCompanionBuilder =
    LocalConfigurationVersionsCompanion Function({
      required String id,
      required String scope,
      required int version,
      required DateTime activatedAt,
      Value<int> rowid,
    });
typedef $$LocalConfigurationVersionsTableUpdateCompanionBuilder =
    LocalConfigurationVersionsCompanion Function({
      Value<String> id,
      Value<String> scope,
      Value<int> version,
      Value<DateTime> activatedAt,
      Value<int> rowid,
    });

class $$LocalConfigurationVersionsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalConfigurationVersionsTable> {
  $$LocalConfigurationVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalConfigurationVersionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalConfigurationVersionsTable> {
  $$LocalConfigurationVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalConfigurationVersionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalConfigurationVersionsTable> {
  $$LocalConfigurationVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get activatedAt => $composableBuilder(
    column: $table.activatedAt,
    builder: (column) => column,
  );
}

class $$LocalConfigurationVersionsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalConfigurationVersionsTable,
          LocalConfigurationVersion,
          $$LocalConfigurationVersionsTableFilterComposer,
          $$LocalConfigurationVersionsTableOrderingComposer,
          $$LocalConfigurationVersionsTableAnnotationComposer,
          $$LocalConfigurationVersionsTableCreateCompanionBuilder,
          $$LocalConfigurationVersionsTableUpdateCompanionBuilder,
          (
            LocalConfigurationVersion,
            BaseReferences<
              _$LocalDatabase,
              $LocalConfigurationVersionsTable,
              LocalConfigurationVersion
            >,
          ),
          LocalConfigurationVersion,
          PrefetchHooks Function()
        > {
  $$LocalConfigurationVersionsTableTableManager(
    _$LocalDatabase db,
    $LocalConfigurationVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalConfigurationVersionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalConfigurationVersionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalConfigurationVersionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> activatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalConfigurationVersionsCompanion(
                id: id,
                scope: scope,
                version: version,
                activatedAt: activatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scope,
                required int version,
                required DateTime activatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalConfigurationVersionsCompanion.insert(
                id: id,
                scope: scope,
                version: version,
                activatedAt: activatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalConfigurationVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalConfigurationVersionsTable,
      LocalConfigurationVersion,
      $$LocalConfigurationVersionsTableFilterComposer,
      $$LocalConfigurationVersionsTableOrderingComposer,
      $$LocalConfigurationVersionsTableAnnotationComposer,
      $$LocalConfigurationVersionsTableCreateCompanionBuilder,
      $$LocalConfigurationVersionsTableUpdateCompanionBuilder,
      (
        LocalConfigurationVersion,
        BaseReferences<
          _$LocalDatabase,
          $LocalConfigurationVersionsTable,
          LocalConfigurationVersion
        >,
      ),
      LocalConfigurationVersion,
      PrefetchHooks Function()
    >;
typedef $$LocalProductsTableCreateCompanionBuilder =
    LocalProductsCompanion Function({
      required String id,
      required String name,
      required String productCode,
      Value<String?> sku,
      required String payloadJson,
      Value<bool> isActive,
      Value<int> configurationVersion,
      Value<int> rowid,
    });
typedef $$LocalProductsTableUpdateCompanionBuilder =
    LocalProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> productCode,
      Value<String?> sku,
      Value<String> payloadJson,
      Value<bool> isActive,
      Value<int> configurationVersion,
      Value<int> rowid,
    });

class $$LocalProductsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalProductsTable> {
  $$LocalProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get configurationVersion => $composableBuilder(
    column: $table.configurationVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalProductsTable> {
  $$LocalProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get configurationVersion => $composableBuilder(
    column: $table.configurationVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalProductsTable> {
  $$LocalProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
    column: $table.productCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get configurationVersion => $composableBuilder(
    column: $table.configurationVersion,
    builder: (column) => column,
  );
}

class $$LocalProductsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalProductsTable,
          LocalProduct,
          $$LocalProductsTableFilterComposer,
          $$LocalProductsTableOrderingComposer,
          $$LocalProductsTableAnnotationComposer,
          $$LocalProductsTableCreateCompanionBuilder,
          $$LocalProductsTableUpdateCompanionBuilder,
          (
            LocalProduct,
            BaseReferences<_$LocalDatabase, $LocalProductsTable, LocalProduct>,
          ),
          LocalProduct,
          PrefetchHooks Function()
        > {
  $$LocalProductsTableTableManager(
    _$LocalDatabase db,
    $LocalProductsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> productCode = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> configurationVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion(
                id: id,
                name: name,
                productCode: productCode,
                sku: sku,
                payloadJson: payloadJson,
                isActive: isActive,
                configurationVersion: configurationVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String productCode,
                Value<String?> sku = const Value.absent(),
                required String payloadJson,
                Value<bool> isActive = const Value.absent(),
                Value<int> configurationVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductsCompanion.insert(
                id: id,
                name: name,
                productCode: productCode,
                sku: sku,
                payloadJson: payloadJson,
                isActive: isActive,
                configurationVersion: configurationVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalProductsTable,
      LocalProduct,
      $$LocalProductsTableFilterComposer,
      $$LocalProductsTableOrderingComposer,
      $$LocalProductsTableAnnotationComposer,
      $$LocalProductsTableCreateCompanionBuilder,
      $$LocalProductsTableUpdateCompanionBuilder,
      (
        LocalProduct,
        BaseReferences<_$LocalDatabase, $LocalProductsTable, LocalProduct>,
      ),
      LocalProduct,
      PrefetchHooks Function()
    >;
typedef $$LocalProductVariantsTableCreateCompanionBuilder =
    LocalProductVariantsCompanion Function({
      required String id,
      required String productId,
      required String name,
      required String variantCode,
      required String payloadJson,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$LocalProductVariantsTableUpdateCompanionBuilder =
    LocalProductVariantsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> name,
      Value<String> variantCode,
      Value<String> payloadJson,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$LocalProductVariantsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalProductVariantsTable> {
  $$LocalProductVariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantCode => $composableBuilder(
    column: $table.variantCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductVariantsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalProductVariantsTable> {
  $$LocalProductVariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantCode => $composableBuilder(
    column: $table.variantCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductVariantsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalProductVariantsTable> {
  $$LocalProductVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get variantCode => $composableBuilder(
    column: $table.variantCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$LocalProductVariantsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalProductVariantsTable,
          LocalProductVariant,
          $$LocalProductVariantsTableFilterComposer,
          $$LocalProductVariantsTableOrderingComposer,
          $$LocalProductVariantsTableAnnotationComposer,
          $$LocalProductVariantsTableCreateCompanionBuilder,
          $$LocalProductVariantsTableUpdateCompanionBuilder,
          (
            LocalProductVariant,
            BaseReferences<
              _$LocalDatabase,
              $LocalProductVariantsTable,
              LocalProductVariant
            >,
          ),
          LocalProductVariant,
          PrefetchHooks Function()
        > {
  $$LocalProductVariantsTableTableManager(
    _$LocalDatabase db,
    $LocalProductVariantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductVariantsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalProductVariantsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> variantCode = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductVariantsCompanion(
                id: id,
                productId: productId,
                name: name,
                variantCode: variantCode,
                payloadJson: payloadJson,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String name,
                required String variantCode,
                required String payloadJson,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductVariantsCompanion.insert(
                id: id,
                productId: productId,
                name: name,
                variantCode: variantCode,
                payloadJson: payloadJson,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductVariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalProductVariantsTable,
      LocalProductVariant,
      $$LocalProductVariantsTableFilterComposer,
      $$LocalProductVariantsTableOrderingComposer,
      $$LocalProductVariantsTableAnnotationComposer,
      $$LocalProductVariantsTableCreateCompanionBuilder,
      $$LocalProductVariantsTableUpdateCompanionBuilder,
      (
        LocalProductVariant,
        BaseReferences<
          _$LocalDatabase,
          $LocalProductVariantsTable,
          LocalProductVariant
        >,
      ),
      LocalProductVariant,
      PrefetchHooks Function()
    >;
typedef $$LocalDynamicFieldsTableCreateCompanionBuilder =
    LocalDynamicFieldsCompanion Function({
      required String id,
      required String entityType,
      required String internalKey,
      required String fieldLabel,
      required String dataType,
      required String payloadJson,
      Value<bool> visibleInFlutter,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$LocalDynamicFieldsTableUpdateCompanionBuilder =
    LocalDynamicFieldsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> internalKey,
      Value<String> fieldLabel,
      Value<String> dataType,
      Value<String> payloadJson,
      Value<bool> visibleInFlutter,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$LocalDynamicFieldsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalDynamicFieldsTable> {
  $$LocalDynamicFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalKey => $composableBuilder(
    column: $table.internalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldLabel => $composableBuilder(
    column: $table.fieldLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get visibleInFlutter => $composableBuilder(
    column: $table.visibleInFlutter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDynamicFieldsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalDynamicFieldsTable> {
  $$LocalDynamicFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalKey => $composableBuilder(
    column: $table.internalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldLabel => $composableBuilder(
    column: $table.fieldLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get visibleInFlutter => $composableBuilder(
    column: $table.visibleInFlutter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDynamicFieldsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalDynamicFieldsTable> {
  $$LocalDynamicFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get internalKey => $composableBuilder(
    column: $table.internalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldLabel => $composableBuilder(
    column: $table.fieldLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataType =>
      $composableBuilder(column: $table.dataType, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get visibleInFlutter => $composableBuilder(
    column: $table.visibleInFlutter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$LocalDynamicFieldsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalDynamicFieldsTable,
          LocalDynamicField,
          $$LocalDynamicFieldsTableFilterComposer,
          $$LocalDynamicFieldsTableOrderingComposer,
          $$LocalDynamicFieldsTableAnnotationComposer,
          $$LocalDynamicFieldsTableCreateCompanionBuilder,
          $$LocalDynamicFieldsTableUpdateCompanionBuilder,
          (
            LocalDynamicField,
            BaseReferences<
              _$LocalDatabase,
              $LocalDynamicFieldsTable,
              LocalDynamicField
            >,
          ),
          LocalDynamicField,
          PrefetchHooks Function()
        > {
  $$LocalDynamicFieldsTableTableManager(
    _$LocalDatabase db,
    $LocalDynamicFieldsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDynamicFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDynamicFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDynamicFieldsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> internalKey = const Value.absent(),
                Value<String> fieldLabel = const Value.absent(),
                Value<String> dataType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<bool> visibleInFlutter = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDynamicFieldsCompanion(
                id: id,
                entityType: entityType,
                internalKey: internalKey,
                fieldLabel: fieldLabel,
                dataType: dataType,
                payloadJson: payloadJson,
                visibleInFlutter: visibleInFlutter,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String internalKey,
                required String fieldLabel,
                required String dataType,
                required String payloadJson,
                Value<bool> visibleInFlutter = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDynamicFieldsCompanion.insert(
                id: id,
                entityType: entityType,
                internalKey: internalKey,
                fieldLabel: fieldLabel,
                dataType: dataType,
                payloadJson: payloadJson,
                visibleInFlutter: visibleInFlutter,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDynamicFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalDynamicFieldsTable,
      LocalDynamicField,
      $$LocalDynamicFieldsTableFilterComposer,
      $$LocalDynamicFieldsTableOrderingComposer,
      $$LocalDynamicFieldsTableAnnotationComposer,
      $$LocalDynamicFieldsTableCreateCompanionBuilder,
      $$LocalDynamicFieldsTableUpdateCompanionBuilder,
      (
        LocalDynamicField,
        BaseReferences<
          _$LocalDatabase,
          $LocalDynamicFieldsTable,
          LocalDynamicField
        >,
      ),
      LocalDynamicField,
      PrefetchHooks Function()
    >;
typedef $$LocalLabelTemplatesTableCreateCompanionBuilder =
    LocalLabelTemplatesCompanion Function({
      required String id,
      required String code,
      required String name,
      required String scope,
      Value<String?> productId,
      Value<String?> variantId,
      Value<int> activeVersion,
      Value<bool> isDefault,
      required String payloadJson,
      Value<int> rowid,
    });
typedef $$LocalLabelTemplatesTableUpdateCompanionBuilder =
    LocalLabelTemplatesCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<String> scope,
      Value<String?> productId,
      Value<String?> variantId,
      Value<int> activeVersion,
      Value<bool> isDefault,
      Value<String> payloadJson,
      Value<int> rowid,
    });

class $$LocalLabelTemplatesTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalLabelTemplatesTable> {
  $$LocalLabelTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeVersion => $composableBuilder(
    column: $table.activeVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalLabelTemplatesTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalLabelTemplatesTable> {
  $$LocalLabelTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeVersion => $composableBuilder(
    column: $table.activeVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalLabelTemplatesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalLabelTemplatesTable> {
  $$LocalLabelTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<int> get activeVersion => $composableBuilder(
    column: $table.activeVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$LocalLabelTemplatesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalLabelTemplatesTable,
          LocalLabelTemplate,
          $$LocalLabelTemplatesTableFilterComposer,
          $$LocalLabelTemplatesTableOrderingComposer,
          $$LocalLabelTemplatesTableAnnotationComposer,
          $$LocalLabelTemplatesTableCreateCompanionBuilder,
          $$LocalLabelTemplatesTableUpdateCompanionBuilder,
          (
            LocalLabelTemplate,
            BaseReferences<
              _$LocalDatabase,
              $LocalLabelTemplatesTable,
              LocalLabelTemplate
            >,
          ),
          LocalLabelTemplate,
          PrefetchHooks Function()
        > {
  $$LocalLabelTemplatesTableTableManager(
    _$LocalDatabase db,
    $LocalLabelTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalLabelTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalLabelTemplatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalLabelTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> variantId = const Value.absent(),
                Value<int> activeVersion = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalLabelTemplatesCompanion(
                id: id,
                code: code,
                name: name,
                scope: scope,
                productId: productId,
                variantId: variantId,
                activeVersion: activeVersion,
                isDefault: isDefault,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                required String scope,
                Value<String?> productId = const Value.absent(),
                Value<String?> variantId = const Value.absent(),
                Value<int> activeVersion = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => LocalLabelTemplatesCompanion.insert(
                id: id,
                code: code,
                name: name,
                scope: scope,
                productId: productId,
                variantId: variantId,
                activeVersion: activeVersion,
                isDefault: isDefault,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalLabelTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalLabelTemplatesTable,
      LocalLabelTemplate,
      $$LocalLabelTemplatesTableFilterComposer,
      $$LocalLabelTemplatesTableOrderingComposer,
      $$LocalLabelTemplatesTableAnnotationComposer,
      $$LocalLabelTemplatesTableCreateCompanionBuilder,
      $$LocalLabelTemplatesTableUpdateCompanionBuilder,
      (
        LocalLabelTemplate,
        BaseReferences<
          _$LocalDatabase,
          $LocalLabelTemplatesTable,
          LocalLabelTemplate
        >,
      ),
      LocalLabelTemplate,
      PrefetchHooks Function()
    >;
typedef $$LocalScaleProfilesTableCreateCompanionBuilder =
    LocalScaleProfilesCompanion Function({
      required String id,
      required String name,
      required String payloadJson,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$LocalScaleProfilesTableUpdateCompanionBuilder =
    LocalScaleProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> payloadJson,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$LocalScaleProfilesTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalScaleProfilesTable> {
  $$LocalScaleProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalScaleProfilesTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalScaleProfilesTable> {
  $$LocalScaleProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalScaleProfilesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalScaleProfilesTable> {
  $$LocalScaleProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$LocalScaleProfilesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalScaleProfilesTable,
          LocalScaleProfile,
          $$LocalScaleProfilesTableFilterComposer,
          $$LocalScaleProfilesTableOrderingComposer,
          $$LocalScaleProfilesTableAnnotationComposer,
          $$LocalScaleProfilesTableCreateCompanionBuilder,
          $$LocalScaleProfilesTableUpdateCompanionBuilder,
          (
            LocalScaleProfile,
            BaseReferences<
              _$LocalDatabase,
              $LocalScaleProfilesTable,
              LocalScaleProfile
            >,
          ),
          LocalScaleProfile,
          PrefetchHooks Function()
        > {
  $$LocalScaleProfilesTableTableManager(
    _$LocalDatabase db,
    $LocalScaleProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalScaleProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalScaleProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalScaleProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalScaleProfilesCompanion(
                id: id,
                name: name,
                payloadJson: payloadJson,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String payloadJson,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalScaleProfilesCompanion.insert(
                id: id,
                name: name,
                payloadJson: payloadJson,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalScaleProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalScaleProfilesTable,
      LocalScaleProfile,
      $$LocalScaleProfilesTableFilterComposer,
      $$LocalScaleProfilesTableOrderingComposer,
      $$LocalScaleProfilesTableAnnotationComposer,
      $$LocalScaleProfilesTableCreateCompanionBuilder,
      $$LocalScaleProfilesTableUpdateCompanionBuilder,
      (
        LocalScaleProfile,
        BaseReferences<
          _$LocalDatabase,
          $LocalScaleProfilesTable,
          LocalScaleProfile
        >,
      ),
      LocalScaleProfile,
      PrefetchHooks Function()
    >;
typedef $$LocalInwardSessionsTableCreateCompanionBuilder =
    LocalInwardSessionsCompanion Function({
      required String id,
      Value<String> accountScope,
      required String sessionNumber,
      Value<String> status,
      Value<int> entryCount,
      Value<double> totalGrossWeight,
      Value<double> totalTareWeight,
      Value<double> totalNetWeight,
      Value<double?> totalPieceQuantity,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> rowid,
    });
typedef $$LocalInwardSessionsTableUpdateCompanionBuilder =
    LocalInwardSessionsCompanion Function({
      Value<String> id,
      Value<String> accountScope,
      Value<String> sessionNumber,
      Value<String> status,
      Value<int> entryCount,
      Value<double> totalGrossWeight,
      Value<double> totalTareWeight,
      Value<double> totalNetWeight,
      Value<double?> totalPieceQuantity,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> rowid,
    });

class $$LocalInwardSessionsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalInwardSessionsTable> {
  $$LocalInwardSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionNumber => $composableBuilder(
    column: $table.sessionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryCount => $composableBuilder(
    column: $table.entryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalGrossWeight => $composableBuilder(
    column: $table.totalGrossWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalTareWeight => $composableBuilder(
    column: $table.totalTareWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalNetWeight => $composableBuilder(
    column: $table.totalNetWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPieceQuantity => $composableBuilder(
    column: $table.totalPieceQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInwardSessionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalInwardSessionsTable> {
  $$LocalInwardSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionNumber => $composableBuilder(
    column: $table.sessionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryCount => $composableBuilder(
    column: $table.entryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalGrossWeight => $composableBuilder(
    column: $table.totalGrossWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalTareWeight => $composableBuilder(
    column: $table.totalTareWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalNetWeight => $composableBuilder(
    column: $table.totalNetWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPieceQuantity => $composableBuilder(
    column: $table.totalPieceQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInwardSessionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalInwardSessionsTable> {
  $$LocalInwardSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionNumber => $composableBuilder(
    column: $table.sessionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get entryCount => $composableBuilder(
    column: $table.entryCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalGrossWeight => $composableBuilder(
    column: $table.totalGrossWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalTareWeight => $composableBuilder(
    column: $table.totalTareWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalNetWeight => $composableBuilder(
    column: $table.totalNetWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPieceQuantity => $composableBuilder(
    column: $table.totalPieceQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);
}

class $$LocalInwardSessionsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalInwardSessionsTable,
          LocalInwardSession,
          $$LocalInwardSessionsTableFilterComposer,
          $$LocalInwardSessionsTableOrderingComposer,
          $$LocalInwardSessionsTableAnnotationComposer,
          $$LocalInwardSessionsTableCreateCompanionBuilder,
          $$LocalInwardSessionsTableUpdateCompanionBuilder,
          (
            LocalInwardSession,
            BaseReferences<
              _$LocalDatabase,
              $LocalInwardSessionsTable,
              LocalInwardSession
            >,
          ),
          LocalInwardSession,
          PrefetchHooks Function()
        > {
  $$LocalInwardSessionsTableTableManager(
    _$LocalDatabase db,
    $LocalInwardSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalInwardSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalInwardSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalInwardSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountScope = const Value.absent(),
                Value<String> sessionNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> entryCount = const Value.absent(),
                Value<double> totalGrossWeight = const Value.absent(),
                Value<double> totalTareWeight = const Value.absent(),
                Value<double> totalNetWeight = const Value.absent(),
                Value<double?> totalPieceQuantity = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInwardSessionsCompanion(
                id: id,
                accountScope: accountScope,
                sessionNumber: sessionNumber,
                status: status,
                entryCount: entryCount,
                totalGrossWeight: totalGrossWeight,
                totalTareWeight: totalTareWeight,
                totalNetWeight: totalNetWeight,
                totalPieceQuantity: totalPieceQuantity,
                startedAt: startedAt,
                endedAt: endedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> accountScope = const Value.absent(),
                required String sessionNumber,
                Value<String> status = const Value.absent(),
                Value<int> entryCount = const Value.absent(),
                Value<double> totalGrossWeight = const Value.absent(),
                Value<double> totalTareWeight = const Value.absent(),
                Value<double> totalNetWeight = const Value.absent(),
                Value<double?> totalPieceQuantity = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInwardSessionsCompanion.insert(
                id: id,
                accountScope: accountScope,
                sessionNumber: sessionNumber,
                status: status,
                entryCount: entryCount,
                totalGrossWeight: totalGrossWeight,
                totalTareWeight: totalTareWeight,
                totalNetWeight: totalNetWeight,
                totalPieceQuantity: totalPieceQuantity,
                startedAt: startedAt,
                endedAt: endedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInwardSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalInwardSessionsTable,
      LocalInwardSession,
      $$LocalInwardSessionsTableFilterComposer,
      $$LocalInwardSessionsTableOrderingComposer,
      $$LocalInwardSessionsTableAnnotationComposer,
      $$LocalInwardSessionsTableCreateCompanionBuilder,
      $$LocalInwardSessionsTableUpdateCompanionBuilder,
      (
        LocalInwardSession,
        BaseReferences<
          _$LocalDatabase,
          $LocalInwardSessionsTable,
          LocalInwardSession
        >,
      ),
      LocalInwardSession,
      PrefetchHooks Function()
    >;
typedef $$LocalProductionTransactionsTableCreateCompanionBuilder =
    LocalProductionTransactionsCompanion Function({
      required String id,
      Value<String> accountScope,
      required String serialNumber,
      required String barcodeValue,
      required String productId,
      Value<String?> variantId,
      Value<String?> inwardSessionId,
      required String productSnapshotJson,
      Value<String> dynamicValuesJson,
      required double grossWeight,
      required double tareWeight,
      required double netWeight,
      Value<double?> pieceQuantity,
      Value<String> unit,
      Value<String> status,
      Value<String> syncStatus,
      required String idempotencyKey,
      required String rawReadingJson,
      required DateTime capturedAt,
      Value<int> rowid,
    });
typedef $$LocalProductionTransactionsTableUpdateCompanionBuilder =
    LocalProductionTransactionsCompanion Function({
      Value<String> id,
      Value<String> accountScope,
      Value<String> serialNumber,
      Value<String> barcodeValue,
      Value<String> productId,
      Value<String?> variantId,
      Value<String?> inwardSessionId,
      Value<String> productSnapshotJson,
      Value<String> dynamicValuesJson,
      Value<double> grossWeight,
      Value<double> tareWeight,
      Value<double> netWeight,
      Value<double?> pieceQuantity,
      Value<String> unit,
      Value<String> status,
      Value<String> syncStatus,
      Value<String> idempotencyKey,
      Value<String> rawReadingJson,
      Value<DateTime> capturedAt,
      Value<int> rowid,
    });

class $$LocalProductionTransactionsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalProductionTransactionsTable> {
  $$LocalProductionTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inwardSessionId => $composableBuilder(
    column: $table.inwardSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productSnapshotJson => $composableBuilder(
    column: $table.productSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dynamicValuesJson => $composableBuilder(
    column: $table.dynamicValuesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grossWeight => $composableBuilder(
    column: $table.grossWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tareWeight => $composableBuilder(
    column: $table.tareWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get netWeight => $composableBuilder(
    column: $table.netWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pieceQuantity => $composableBuilder(
    column: $table.pieceQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawReadingJson => $composableBuilder(
    column: $table.rawReadingJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProductionTransactionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalProductionTransactionsTable> {
  $$LocalProductionTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inwardSessionId => $composableBuilder(
    column: $table.inwardSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productSnapshotJson => $composableBuilder(
    column: $table.productSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dynamicValuesJson => $composableBuilder(
    column: $table.dynamicValuesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grossWeight => $composableBuilder(
    column: $table.grossWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tareWeight => $composableBuilder(
    column: $table.tareWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get netWeight => $composableBuilder(
    column: $table.netWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pieceQuantity => $composableBuilder(
    column: $table.pieceQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawReadingJson => $composableBuilder(
    column: $table.rawReadingJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProductionTransactionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalProductionTransactionsTable> {
  $$LocalProductionTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get inwardSessionId => $composableBuilder(
    column: $table.inwardSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productSnapshotJson => $composableBuilder(
    column: $table.productSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dynamicValuesJson => $composableBuilder(
    column: $table.dynamicValuesJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grossWeight => $composableBuilder(
    column: $table.grossWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tareWeight => $composableBuilder(
    column: $table.tareWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get netWeight =>
      $composableBuilder(column: $table.netWeight, builder: (column) => column);

  GeneratedColumn<double> get pieceQuantity => $composableBuilder(
    column: $table.pieceQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawReadingJson => $composableBuilder(
    column: $table.rawReadingJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );
}

class $$LocalProductionTransactionsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalProductionTransactionsTable,
          LocalProductionTransaction,
          $$LocalProductionTransactionsTableFilterComposer,
          $$LocalProductionTransactionsTableOrderingComposer,
          $$LocalProductionTransactionsTableAnnotationComposer,
          $$LocalProductionTransactionsTableCreateCompanionBuilder,
          $$LocalProductionTransactionsTableUpdateCompanionBuilder,
          (
            LocalProductionTransaction,
            BaseReferences<
              _$LocalDatabase,
              $LocalProductionTransactionsTable,
              LocalProductionTransaction
            >,
          ),
          LocalProductionTransaction,
          PrefetchHooks Function()
        > {
  $$LocalProductionTransactionsTableTableManager(
    _$LocalDatabase db,
    $LocalProductionTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductionTransactionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalProductionTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalProductionTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountScope = const Value.absent(),
                Value<String> serialNumber = const Value.absent(),
                Value<String> barcodeValue = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String?> variantId = const Value.absent(),
                Value<String?> inwardSessionId = const Value.absent(),
                Value<String> productSnapshotJson = const Value.absent(),
                Value<String> dynamicValuesJson = const Value.absent(),
                Value<double> grossWeight = const Value.absent(),
                Value<double> tareWeight = const Value.absent(),
                Value<double> netWeight = const Value.absent(),
                Value<double?> pieceQuantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> rawReadingJson = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductionTransactionsCompanion(
                id: id,
                accountScope: accountScope,
                serialNumber: serialNumber,
                barcodeValue: barcodeValue,
                productId: productId,
                variantId: variantId,
                inwardSessionId: inwardSessionId,
                productSnapshotJson: productSnapshotJson,
                dynamicValuesJson: dynamicValuesJson,
                grossWeight: grossWeight,
                tareWeight: tareWeight,
                netWeight: netWeight,
                pieceQuantity: pieceQuantity,
                unit: unit,
                status: status,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                rawReadingJson: rawReadingJson,
                capturedAt: capturedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> accountScope = const Value.absent(),
                required String serialNumber,
                required String barcodeValue,
                required String productId,
                Value<String?> variantId = const Value.absent(),
                Value<String?> inwardSessionId = const Value.absent(),
                required String productSnapshotJson,
                Value<String> dynamicValuesJson = const Value.absent(),
                required double grossWeight,
                required double tareWeight,
                required double netWeight,
                Value<double?> pieceQuantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required String idempotencyKey,
                required String rawReadingJson,
                required DateTime capturedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalProductionTransactionsCompanion.insert(
                id: id,
                accountScope: accountScope,
                serialNumber: serialNumber,
                barcodeValue: barcodeValue,
                productId: productId,
                variantId: variantId,
                inwardSessionId: inwardSessionId,
                productSnapshotJson: productSnapshotJson,
                dynamicValuesJson: dynamicValuesJson,
                grossWeight: grossWeight,
                tareWeight: tareWeight,
                netWeight: netWeight,
                pieceQuantity: pieceQuantity,
                unit: unit,
                status: status,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                rawReadingJson: rawReadingJson,
                capturedAt: capturedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProductionTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalProductionTransactionsTable,
      LocalProductionTransaction,
      $$LocalProductionTransactionsTableFilterComposer,
      $$LocalProductionTransactionsTableOrderingComposer,
      $$LocalProductionTransactionsTableAnnotationComposer,
      $$LocalProductionTransactionsTableCreateCompanionBuilder,
      $$LocalProductionTransactionsTableUpdateCompanionBuilder,
      (
        LocalProductionTransaction,
        BaseReferences<
          _$LocalDatabase,
          $LocalProductionTransactionsTable,
          LocalProductionTransaction
        >,
      ),
      LocalProductionTransaction,
      PrefetchHooks Function()
    >;
typedef $$LocalInventoryLedgerTableCreateCompanionBuilder =
    LocalInventoryLedgerCompanion Function({
      required String id,
      Value<String> accountScope,
      required String productId,
      Value<String?> variantId,
      Value<String?> serialNumber,
      Value<String?> barcodeValue,
      required String transactionType,
      required double weightQuantity,
      Value<double?> pieceQuantity,
      required String referenceType,
      required String referenceId,
      Value<String> syncStatus,
      required DateTime occurredAt,
      Value<int> rowid,
    });
typedef $$LocalInventoryLedgerTableUpdateCompanionBuilder =
    LocalInventoryLedgerCompanion Function({
      Value<String> id,
      Value<String> accountScope,
      Value<String> productId,
      Value<String?> variantId,
      Value<String?> serialNumber,
      Value<String?> barcodeValue,
      Value<String> transactionType,
      Value<double> weightQuantity,
      Value<double?> pieceQuantity,
      Value<String> referenceType,
      Value<String> referenceId,
      Value<String> syncStatus,
      Value<DateTime> occurredAt,
      Value<int> rowid,
    });

class $$LocalInventoryLedgerTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalInventoryLedgerTable> {
  $$LocalInventoryLedgerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightQuantity => $composableBuilder(
    column: $table.weightQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pieceQuantity => $composableBuilder(
    column: $table.pieceQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalInventoryLedgerTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalInventoryLedgerTable> {
  $$LocalInventoryLedgerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightQuantity => $composableBuilder(
    column: $table.weightQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pieceQuantity => $composableBuilder(
    column: $table.pieceQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalInventoryLedgerTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalInventoryLedgerTable> {
  $$LocalInventoryLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightQuantity => $composableBuilder(
    column: $table.weightQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pieceQuantity => $composableBuilder(
    column: $table.pieceQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceType => $composableBuilder(
    column: $table.referenceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceId => $composableBuilder(
    column: $table.referenceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );
}

class $$LocalInventoryLedgerTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalInventoryLedgerTable,
          LocalInventoryLedgerData,
          $$LocalInventoryLedgerTableFilterComposer,
          $$LocalInventoryLedgerTableOrderingComposer,
          $$LocalInventoryLedgerTableAnnotationComposer,
          $$LocalInventoryLedgerTableCreateCompanionBuilder,
          $$LocalInventoryLedgerTableUpdateCompanionBuilder,
          (
            LocalInventoryLedgerData,
            BaseReferences<
              _$LocalDatabase,
              $LocalInventoryLedgerTable,
              LocalInventoryLedgerData
            >,
          ),
          LocalInventoryLedgerData,
          PrefetchHooks Function()
        > {
  $$LocalInventoryLedgerTableTableManager(
    _$LocalDatabase db,
    $LocalInventoryLedgerTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalInventoryLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalInventoryLedgerTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalInventoryLedgerTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountScope = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String?> variantId = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> barcodeValue = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<double> weightQuantity = const Value.absent(),
                Value<double?> pieceQuantity = const Value.absent(),
                Value<String> referenceType = const Value.absent(),
                Value<String> referenceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryLedgerCompanion(
                id: id,
                accountScope: accountScope,
                productId: productId,
                variantId: variantId,
                serialNumber: serialNumber,
                barcodeValue: barcodeValue,
                transactionType: transactionType,
                weightQuantity: weightQuantity,
                pieceQuantity: pieceQuantity,
                referenceType: referenceType,
                referenceId: referenceId,
                syncStatus: syncStatus,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> accountScope = const Value.absent(),
                required String productId,
                Value<String?> variantId = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String?> barcodeValue = const Value.absent(),
                required String transactionType,
                required double weightQuantity,
                Value<double?> pieceQuantity = const Value.absent(),
                required String referenceType,
                required String referenceId,
                Value<String> syncStatus = const Value.absent(),
                required DateTime occurredAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalInventoryLedgerCompanion.insert(
                id: id,
                accountScope: accountScope,
                productId: productId,
                variantId: variantId,
                serialNumber: serialNumber,
                barcodeValue: barcodeValue,
                transactionType: transactionType,
                weightQuantity: weightQuantity,
                pieceQuantity: pieceQuantity,
                referenceType: referenceType,
                referenceId: referenceId,
                syncStatus: syncStatus,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalInventoryLedgerTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalInventoryLedgerTable,
      LocalInventoryLedgerData,
      $$LocalInventoryLedgerTableFilterComposer,
      $$LocalInventoryLedgerTableOrderingComposer,
      $$LocalInventoryLedgerTableAnnotationComposer,
      $$LocalInventoryLedgerTableCreateCompanionBuilder,
      $$LocalInventoryLedgerTableUpdateCompanionBuilder,
      (
        LocalInventoryLedgerData,
        BaseReferences<
          _$LocalDatabase,
          $LocalInventoryLedgerTable,
          LocalInventoryLedgerData
        >,
      ),
      LocalInventoryLedgerData,
      PrefetchHooks Function()
    >;
typedef $$LocalCustomersTableCreateCompanionBuilder =
    LocalCustomersCompanion Function({
      required String id,
      required String name,
      Value<String?> code,
      required String payloadJson,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$LocalCustomersTableUpdateCompanionBuilder =
    LocalCustomersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> code,
      Value<String> payloadJson,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$LocalCustomersTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCustomersTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCustomersTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalCustomersTable> {
  $$LocalCustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$LocalCustomersTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalCustomersTable,
          LocalCustomer,
          $$LocalCustomersTableFilterComposer,
          $$LocalCustomersTableOrderingComposer,
          $$LocalCustomersTableAnnotationComposer,
          $$LocalCustomersTableCreateCompanionBuilder,
          $$LocalCustomersTableUpdateCompanionBuilder,
          (
            LocalCustomer,
            BaseReferences<
              _$LocalDatabase,
              $LocalCustomersTable,
              LocalCustomer
            >,
          ),
          LocalCustomer,
          PrefetchHooks Function()
        > {
  $$LocalCustomersTableTableManager(
    _$LocalDatabase db,
    $LocalCustomersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCustomersCompanion(
                id: id,
                name: name,
                code: code,
                payloadJson: payloadJson,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> code = const Value.absent(),
                required String payloadJson,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCustomersCompanion.insert(
                id: id,
                name: name,
                code: code,
                payloadJson: payloadJson,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalCustomersTable,
      LocalCustomer,
      $$LocalCustomersTableFilterComposer,
      $$LocalCustomersTableOrderingComposer,
      $$LocalCustomersTableAnnotationComposer,
      $$LocalCustomersTableCreateCompanionBuilder,
      $$LocalCustomersTableUpdateCompanionBuilder,
      (
        LocalCustomer,
        BaseReferences<_$LocalDatabase, $LocalCustomersTable, LocalCustomer>,
      ),
      LocalCustomer,
      PrefetchHooks Function()
    >;
typedef $$LocalDispatchesTableCreateCompanionBuilder =
    LocalDispatchesCompanion Function({
      required String id,
      Value<String> accountScope,
      required String dispatchNumber,
      required String customerId,
      required String customerSnapshotJson,
      Value<String> status,
      Value<double> totalWeight,
      Value<double?> totalPieces,
      Value<String> syncStatus,
      required String idempotencyKey,
      required DateTime createdAt,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });
typedef $$LocalDispatchesTableUpdateCompanionBuilder =
    LocalDispatchesCompanion Function({
      Value<String> id,
      Value<String> accountScope,
      Value<String> dispatchNumber,
      Value<String> customerId,
      Value<String> customerSnapshotJson,
      Value<String> status,
      Value<double> totalWeight,
      Value<double?> totalPieces,
      Value<String> syncStatus,
      Value<String> idempotencyKey,
      Value<DateTime> createdAt,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });

class $$LocalDispatchesTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalDispatchesTable> {
  $$LocalDispatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dispatchNumber => $composableBuilder(
    column: $table.dispatchNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerSnapshotJson => $composableBuilder(
    column: $table.customerSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalWeight => $composableBuilder(
    column: $table.totalWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPieces => $composableBuilder(
    column: $table.totalPieces,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDispatchesTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalDispatchesTable> {
  $$LocalDispatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dispatchNumber => $composableBuilder(
    column: $table.dispatchNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerSnapshotJson => $composableBuilder(
    column: $table.customerSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalWeight => $composableBuilder(
    column: $table.totalWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPieces => $composableBuilder(
    column: $table.totalPieces,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDispatchesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalDispatchesTable> {
  $$LocalDispatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dispatchNumber => $composableBuilder(
    column: $table.dispatchNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerSnapshotJson => $composableBuilder(
    column: $table.customerSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get totalWeight => $composableBuilder(
    column: $table.totalWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPieces => $composableBuilder(
    column: $table.totalPieces,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );
}

class $$LocalDispatchesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalDispatchesTable,
          LocalDispatche,
          $$LocalDispatchesTableFilterComposer,
          $$LocalDispatchesTableOrderingComposer,
          $$LocalDispatchesTableAnnotationComposer,
          $$LocalDispatchesTableCreateCompanionBuilder,
          $$LocalDispatchesTableUpdateCompanionBuilder,
          (
            LocalDispatche,
            BaseReferences<
              _$LocalDatabase,
              $LocalDispatchesTable,
              LocalDispatche
            >,
          ),
          LocalDispatche,
          PrefetchHooks Function()
        > {
  $$LocalDispatchesTableTableManager(
    _$LocalDatabase db,
    $LocalDispatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDispatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDispatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDispatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountScope = const Value.absent(),
                Value<String> dispatchNumber = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> customerSnapshotJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> totalWeight = const Value.absent(),
                Value<double?> totalPieces = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDispatchesCompanion(
                id: id,
                accountScope: accountScope,
                dispatchNumber: dispatchNumber,
                customerId: customerId,
                customerSnapshotJson: customerSnapshotJson,
                status: status,
                totalWeight: totalWeight,
                totalPieces: totalPieces,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> accountScope = const Value.absent(),
                required String dispatchNumber,
                required String customerId,
                required String customerSnapshotJson,
                Value<String> status = const Value.absent(),
                Value<double> totalWeight = const Value.absent(),
                Value<double?> totalPieces = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required String idempotencyKey,
                required DateTime createdAt,
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDispatchesCompanion.insert(
                id: id,
                accountScope: accountScope,
                dispatchNumber: dispatchNumber,
                customerId: customerId,
                customerSnapshotJson: customerSnapshotJson,
                status: status,
                totalWeight: totalWeight,
                totalPieces: totalPieces,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDispatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalDispatchesTable,
      LocalDispatche,
      $$LocalDispatchesTableFilterComposer,
      $$LocalDispatchesTableOrderingComposer,
      $$LocalDispatchesTableAnnotationComposer,
      $$LocalDispatchesTableCreateCompanionBuilder,
      $$LocalDispatchesTableUpdateCompanionBuilder,
      (
        LocalDispatche,
        BaseReferences<_$LocalDatabase, $LocalDispatchesTable, LocalDispatche>,
      ),
      LocalDispatche,
      PrefetchHooks Function()
    >;
typedef $$LocalDispatchItemsTableCreateCompanionBuilder =
    LocalDispatchItemsCompanion Function({
      required String id,
      Value<String> accountScope,
      required String dispatchId,
      required String productionTransactionId,
      required String barcodeValue,
      required double weightQuantity,
      Value<double?> pieceQuantity,
      Value<int> rowid,
    });
typedef $$LocalDispatchItemsTableUpdateCompanionBuilder =
    LocalDispatchItemsCompanion Function({
      Value<String> id,
      Value<String> accountScope,
      Value<String> dispatchId,
      Value<String> productionTransactionId,
      Value<String> barcodeValue,
      Value<double> weightQuantity,
      Value<double?> pieceQuantity,
      Value<int> rowid,
    });

class $$LocalDispatchItemsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalDispatchItemsTable> {
  $$LocalDispatchItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dispatchId => $composableBuilder(
    column: $table.dispatchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productionTransactionId => $composableBuilder(
    column: $table.productionTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightQuantity => $composableBuilder(
    column: $table.weightQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pieceQuantity => $composableBuilder(
    column: $table.pieceQuantity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDispatchItemsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalDispatchItemsTable> {
  $$LocalDispatchItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dispatchId => $composableBuilder(
    column: $table.dispatchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productionTransactionId => $composableBuilder(
    column: $table.productionTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightQuantity => $composableBuilder(
    column: $table.weightQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pieceQuantity => $composableBuilder(
    column: $table.pieceQuantity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDispatchItemsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalDispatchItemsTable> {
  $$LocalDispatchItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountScope => $composableBuilder(
    column: $table.accountScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dispatchId => $composableBuilder(
    column: $table.dispatchId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productionTransactionId => $composableBuilder(
    column: $table.productionTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcodeValue => $composableBuilder(
    column: $table.barcodeValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightQuantity => $composableBuilder(
    column: $table.weightQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pieceQuantity => $composableBuilder(
    column: $table.pieceQuantity,
    builder: (column) => column,
  );
}

class $$LocalDispatchItemsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalDispatchItemsTable,
          LocalDispatchItem,
          $$LocalDispatchItemsTableFilterComposer,
          $$LocalDispatchItemsTableOrderingComposer,
          $$LocalDispatchItemsTableAnnotationComposer,
          $$LocalDispatchItemsTableCreateCompanionBuilder,
          $$LocalDispatchItemsTableUpdateCompanionBuilder,
          (
            LocalDispatchItem,
            BaseReferences<
              _$LocalDatabase,
              $LocalDispatchItemsTable,
              LocalDispatchItem
            >,
          ),
          LocalDispatchItem,
          PrefetchHooks Function()
        > {
  $$LocalDispatchItemsTableTableManager(
    _$LocalDatabase db,
    $LocalDispatchItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDispatchItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDispatchItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDispatchItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountScope = const Value.absent(),
                Value<String> dispatchId = const Value.absent(),
                Value<String> productionTransactionId = const Value.absent(),
                Value<String> barcodeValue = const Value.absent(),
                Value<double> weightQuantity = const Value.absent(),
                Value<double?> pieceQuantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDispatchItemsCompanion(
                id: id,
                accountScope: accountScope,
                dispatchId: dispatchId,
                productionTransactionId: productionTransactionId,
                barcodeValue: barcodeValue,
                weightQuantity: weightQuantity,
                pieceQuantity: pieceQuantity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> accountScope = const Value.absent(),
                required String dispatchId,
                required String productionTransactionId,
                required String barcodeValue,
                required double weightQuantity,
                Value<double?> pieceQuantity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDispatchItemsCompanion.insert(
                id: id,
                accountScope: accountScope,
                dispatchId: dispatchId,
                productionTransactionId: productionTransactionId,
                barcodeValue: barcodeValue,
                weightQuantity: weightQuantity,
                pieceQuantity: pieceQuantity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDispatchItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalDispatchItemsTable,
      LocalDispatchItem,
      $$LocalDispatchItemsTableFilterComposer,
      $$LocalDispatchItemsTableOrderingComposer,
      $$LocalDispatchItemsTableAnnotationComposer,
      $$LocalDispatchItemsTableCreateCompanionBuilder,
      $$LocalDispatchItemsTableUpdateCompanionBuilder,
      (
        LocalDispatchItem,
        BaseReferences<
          _$LocalDatabase,
          $LocalDispatchItemsTable,
          LocalDispatchItem
        >,
      ),
      LocalDispatchItem,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$LocalSyncQueueTableTableManager get localSyncQueue =>
      $$LocalSyncQueueTableTableManager(_db, _db.localSyncQueue);
  $$LocalConfigurationVersionsTableTableManager
  get localConfigurationVersions =>
      $$LocalConfigurationVersionsTableTableManager(
        _db,
        _db.localConfigurationVersions,
      );
  $$LocalProductsTableTableManager get localProducts =>
      $$LocalProductsTableTableManager(_db, _db.localProducts);
  $$LocalProductVariantsTableTableManager get localProductVariants =>
      $$LocalProductVariantsTableTableManager(_db, _db.localProductVariants);
  $$LocalDynamicFieldsTableTableManager get localDynamicFields =>
      $$LocalDynamicFieldsTableTableManager(_db, _db.localDynamicFields);
  $$LocalLabelTemplatesTableTableManager get localLabelTemplates =>
      $$LocalLabelTemplatesTableTableManager(_db, _db.localLabelTemplates);
  $$LocalScaleProfilesTableTableManager get localScaleProfiles =>
      $$LocalScaleProfilesTableTableManager(_db, _db.localScaleProfiles);
  $$LocalInwardSessionsTableTableManager get localInwardSessions =>
      $$LocalInwardSessionsTableTableManager(_db, _db.localInwardSessions);
  $$LocalProductionTransactionsTableTableManager
  get localProductionTransactions =>
      $$LocalProductionTransactionsTableTableManager(
        _db,
        _db.localProductionTransactions,
      );
  $$LocalInventoryLedgerTableTableManager get localInventoryLedger =>
      $$LocalInventoryLedgerTableTableManager(_db, _db.localInventoryLedger);
  $$LocalCustomersTableTableManager get localCustomers =>
      $$LocalCustomersTableTableManager(_db, _db.localCustomers);
  $$LocalDispatchesTableTableManager get localDispatches =>
      $$LocalDispatchesTableTableManager(_db, _db.localDispatches);
  $$LocalDispatchItemsTableTableManager get localDispatchItems =>
      $$LocalDispatchItemsTableTableManager(_db, _db.localDispatchItems);
}
