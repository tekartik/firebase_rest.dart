import 'package:googleapis/firestore/v1.dart';
import 'package:tekartik_firebase_firestore_rest/src/query_rest.dart';

import 'import_firestore.dart';

/// Aggregate query rest implementation.
class AggregateQueryRest implements AggregateQuery {
  /// Query
  final QueryRestImpl queryRest;

  /// Fields
  final List<AggregateField> fields;

  /// Constructor.
  AggregateQueryRest(this.queryRest, this.fields);

  @override
  Future<AggregateQuerySnapshot> get() async {
    var firestoreRest = queryRest.firestoreRestImpl;
    var response = await firestoreRest.runAggregationQuery(this);
    return response;
  }
}

/// Aggregate query snapshot rest implementation.
class AggregateQuerySnapshotRest implements AggregateQuerySnapshot {
  /// Aggregate query.
  final AggregateQueryRest aggregateQueryRest;

  /// Native response.
  final RunAggregationQueryResponse nativeResponse;

  /// Constructor.
  AggregateQuerySnapshotRest(this.aggregateQueryRest, this.nativeResponse);

  /// Get index alias.
  String indexAlias(int index) =>
      aggregateQueryRest.queryRest.firestoreRestImpl.indexAlias(index);

  /// Get aggregate field value.
  Value getAggregateFieldValue(int index) {
    var value =
        nativeResponse.first.result!.aggregateFields![indexAlias(index)]!;
    return value;
  }

  @override
  int? get count {
    for (var e in aggregateQueryRest.fields.indexed) {
      var aggregateField = e.$2;
      if (aggregateField is AggregateFieldCount) {
        var index = e.$1;
        var result = int.parse(getAggregateFieldValue(index).integerValue!);
        return result;
      }
    }
    return null;
  }

  /// Get double value from value.
  double? getDoubleValue(Value value) {
    if (value.doubleValue != null) {
      return value.doubleValue;
    } else if (value.integerValue != null) {
      return double.parse(value.integerValue!);
    } else {
      return null;
    }
  }

  @override
  double? getAverage(String field) {
    for (var e in aggregateQueryRest.fields.indexed) {
      var aggregateField = e.$2;
      if (aggregateField is AggregateFieldAverage &&
          aggregateField.field == field) {
        var index = e.$1;
        return getDoubleValue(getAggregateFieldValue(index));
      }
    }
    return null;
  }

  @override
  double? getSum(String field) {
    for (var e in aggregateQueryRest.fields.indexed) {
      var aggregateField = e.$2;
      if (aggregateField is AggregateFieldSum &&
          aggregateField.field == field) {
        var index = e.$1;
        return getDoubleValue(getAggregateFieldValue(index));
      }
    }
    return null;
  }

  @override
  Query get query => aggregateQueryRest.queryRest;
}
