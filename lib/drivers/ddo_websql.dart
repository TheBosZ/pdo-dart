import '../ddo.dart';
import 'dart:web_sql';
import 'dart:async';
import 'dart:html';

class DDOWebSQL extends Driver {

	SqlDatabase _db;

	DDOWebSQL({String name, String version: '1', String displayName: null, int estimatedSize: null, DatabaseCallback callback: null}) {
		if (displayName == null) {
			displayName = name;
		}
		if (estimatedSize == null) {
			estimatedSize = 1024 * 1024 * 4;
		}
		_db = window.openDatabase(name, version, displayName, estimatedSize, callback);
		dbinfo = [name];
	}

	@override
	Future beginTransaction() => new Future.value(false);

	@override
	bool close() => _close();

	@override
	Future commit() => new Future.value(false);

	@override
	Object getAttribute(int attr) => false;

	@override
	String quote(String value) => "'${value.replaceAll("'", "''")}'";

	@override
	Object quoteIdentifier(Object val) {
		if (val is List) {
			return (val.map((v) => quoteIdentifier(v)).toList());
		}

		if (val is String) {
			if (val.indexOf('[') != -1 || val.indexOf(' ') != -1 || val.indexOf('(') != -1 || val.indexOf('*') != -1) {
				return val;
			}
			return '[${val.replaceAll('.', '].[')}]';
		}
		return val;

	}

	@override
	Future rollBack() => new Future.value(false);

	@override
	bool setAttribute(int attr, Object mixed) {
		bool result = false;
		if (attr == DDO.ATTR_ERRMODE && mixed == DDO.ERRMODE_EXCEPTION) {
			throwExceptions = true;
		} else if (attr == DDO.ATTR_STATEMENT_CLASS && (mixed as List<String>).elementAt(0) == 'LoggedPDOStatement') {
			logging = true;
		}

		if (attr == DDO.ATTR_PERSISTENT && mixed != persistent) {
			//Websql doesn't have persistent
		}
		return result;
	}

	bool _close() {
		_db = null;
		return true;
	}

	@override
	Future<DDOResults> uQuery(String query) {
		Completer completer = new Completer();
		_db.transaction((SqlTransaction tx) {
			tx.executeSql(query, [], (tx, SqlResultSet results) {

				DDOResults retres = new DDOResults();
				if (results.insertId != null) {
					retres.insertId = results.insertId;
				}
				if (results.rowsAffected != null) {
					retres.affectedRows = results.rowsAffected;
				}
				retres.fields = new List<String>();

				for (Map row in results.rows) {
					retres.add(new DDOResult.fromMap(row));
				}
				completer.complete(retres);

			});
		});
		return completer.future;
	}
}
