import 'dart:convert';
import 'dart:io';
import 'package:couchbase_lite/couchbase_lite.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<void> init() async {
    if (_db != null) return;

    await _copyDatabaseIfNeeded();
    _db = await Database.initWithName('incident_db');
  }

  static Future<void> _copyDatabaseIfNeeded() async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${appDir.path}/incident_db.cblite2');

    if (await targetDir.exists()) return;

    await targetDir.create(recursive: true);
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final assetManifest = jsonDecode(manifestContent) as Map<String, dynamic>;

    final dbAssetFiles = assetManifest.keys
        .where((key) => key.startsWith('assets/incident_db.cblite2/'))
        .toList();

    for (final assetPath in dbAssetFiles) {
      final fileName = assetPath.split('/').last;
      final data = await rootBundle.load(assetPath);
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(data.buffer.asUint8List());
    }
  }

  static Future<String> getAnswerForQuestion(String userQuestion) async {
    if (_db == null) return "Database not ready";

    final cleanedQuestion = userQuestion.trim().toLowerCase();

    // Define keywords for each question
    if (cleanedQuestion.contains("incidents") && cleanedQuestion.contains("assigned") && cleanedQuestion.contains("me")) {
      return await _runQuery(
          createdBy: "Amar Thombare"
      );
    } else if (cleanedQuestion.contains("show") && cleanedQuestion.contains("incidents")) {
      return await _runQuery(); // no filters
    } else if (cleanedQuestion.contains("technical") && cleanedQuestion.contains("incidents") && cleanedQuestion.contains("created")) {
      return await _runQuery(
        status: "Created",
        incidentType: "Technical",
      );
    } else if (cleanedQuestion.contains("medical") && cleanedQuestion.contains("incidents") && cleanedQuestion.contains("dispatch")) {
      return await _runQuery(
        status: "Dispatch",
        incidentType: "Medical",
      );
    } else if (cleanedQuestion.contains("security") && cleanedQuestion.contains("incidents") && cleanedQuestion.contains("in-progress")) {
      return await _runQuery(
        status: "In-Progress",
        incidentType: "Security",
      );
    } else if (cleanedQuestion.contains("my") && cleanedQuestion.contains("incidents") && cleanedQuestion.contains("dispatch")) {
      return await _runQuery(
        createdBy: "Amar Thombare",
        status: "Dispatch",
      );
    } else if (cleanedQuestion.contains("incidents") && cleanedQuestion.contains("created")) {
      return await _runQuery(
        status: "Created",
      );
    } else if (cleanedQuestion.contains("technical") && cleanedQuestion.contains("incidents") && cleanedQuestion.contains("my")) {
      return await _runQuery(
        createdBy: "Amar Thombare",
        incidentType: "Technical",
      );
    } else if (cleanedQuestion.contains("in-progress") && cleanedQuestion.contains("incidents")) {
      return await _runQuery(
        status: "In-Progress",
      );
    } else if (cleanedQuestion.contains("medical") && cleanedQuestion.contains("incidents") && cleanedQuestion.contains("assigned") && cleanedQuestion.contains("me")) {
      return await _runQuery(
        createdBy: "Amar Thombare",
        incidentType: "Medical",
      );
    } else {
      return "Sorry, I couldn't understand your question.";
    }
  }

  static Future<String> _runQuery({
    String? createdBy,
    String? status,
    String? incidentType,
  }) async
  {
    if (_db == null) return "Database not ready";

    Expression condition = Expression.property('documentType')
        .equalTo(Expression.string('incident_document_type'));

    if (createdBy != null) {
      condition = condition.and(
        Expression.property('created_by_name').equalTo(Expression.string(createdBy)),
      );
    }

    if (status != null) {
      condition = condition.and(
        Expression.property('status').equalTo(Expression.string(status)),
      );
    }

    if (incidentType != null) {
      condition = condition.and(
        Expression.property('incident_type_name').equalTo(Expression.string(incidentType)),
      );
    }

    final bool isCountQuery = status != null || incidentType != null || createdBy != null;

    final Query query = isCountQuery
        ? QueryBuilder
        .select([SelectResult.expression(Functions.count(Expression.property("incident_no")))])
        .from("incident_db")
        .where(condition)
        : QueryBuilder
        .select([SelectResult.all()])
        .from("incident_db")
        .where(condition);

    final result = await query.execute();

    if (isCountQuery) {
      final count = result.first[0].getInt() ?? 0;
      return "There are $count incidents matching your query.";
    } else {
      final incidents = <Map<String, dynamic>>[];
      for (final row in result) {
        final map = row.toMap()['incident_db'];
        if (map != null && map is Map) {
          incidents.add(Map<String, dynamic>.from(map));
        }
      }

      if (incidents.isEmpty) {
        return "No incidents found.";
      }

      return incidents.map((e) {
        return "- ${e['incident_no'] ?? 'Unknown'} | ${e['incident_type_name'] ?? 'Type'} | ${e['status'] ?? 'Status'}";
      }).join("\n");
    }
  }

  static Future<List<Map<String, dynamic>>> getAllKeysAndValues() async {
    if (_db == null) return [];

    final query = QueryBuilder.select([SelectResult.all()])
        .from("incident_db")
        .where(Expression.property('documentType')
            .equalTo(Expression.string('incident_document_type')));

    final result = await query.execute();
    final items = <Map<String, dynamic>>[];

    for (var obj in result) {
      final map = obj.toMap()['incident_db'];
      if (map != null && map is Map) {
        items.add(Map<String, dynamic>.from(map));
      }
    }
    return items;
  }
}
