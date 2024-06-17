import 'package:googleapis/firestore/v1.dart';
import 'package:tekartik_firebase_firestore_rest/src/query_rest.dart';

import 'import_firestore.dart';

class AggregateQueryRest implements AggregateQuery {
  final QueryRestImpl queryRest;
  final List<AggregateField> fields;
  AggregateQueryRest(this.queryRest, this.fields);
  @override
  Future<AggregateQuerySnapshot> get() async {
    var firestoreRest = queryRest.firestoreRestImpl;
    var response = await firestoreRest.runAggregationQuery(this);
    return response;
  }
}

class AggregateQuerySnapshotRest implements AggregateQuerySnapshot {
  final AggregateQueryRest aggregateQueryRest;
  final RunAggregationQueryResponse nativeResponse;

  AggregateQuerySnapshotRest(this.aggregateQueryRest, this.nativeResponse);

  String indexAlias(int index) =>
      aggregateQueryRest.queryRest.firestoreRestImpl.indexAlias(index);

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
