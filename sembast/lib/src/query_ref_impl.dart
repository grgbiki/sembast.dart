import 'package:sembast/sembast.dart';
import 'package:sembast/src/api/finder.dart';
import 'package:sembast/src/api/query_ref.dart';
import 'package:sembast/src/api/store_ref.dart';
import 'package:sembast/src/common_import.dart';
import 'package:sembast/src/database_impl.dart';
import 'package:sembast/src/debug_utils.dart';
import 'package:sembast/src/finder_impl.dart';
import 'package:sembast/src/listener.dart';
import 'package:sembast/src/store_ref_impl.dart';

/// A query is unique
class SembastQueryRef<K, V> implements QueryRef<K, V> {
  /// The store.
  final StoreRef<K, V> store;

  /// The finder.
  // ignore: deprecated_member_use_from_same_package
  final SembastFinder finder;

  /// Query ref implementation.

  SembastQueryRef(
      this.store,
      // ignore: deprecated_member_use_from_same_package
      SembastFinder finder)
      : finder = finder?.clone() as
            // ignore: deprecated_member_use_from_same_package
            SembastFinder;

  @override
  String toString() => '$store $finder)';

  @override
  Stream<List<RecordSnapshot<K, V>>> onSnapshots(Database database) {
    var db = getDatabase(database);
    // Create the query but don't add it until first result is set
    QueryListenerController<K, V> ctlr;
    ctlr = db.listener.addQuery(this, onListen: () async {
      // Add the existing snapshot

      // Read right away to get the content at call time

      // Just filter
      try {
        await db.notificationLock.synchronized(() async {
          var allMatching = await (store as SembastStoreRef<K, V>)
              .findImmutableRecords(database,
                  finder:
                      finder == null ? null : Finder(filter: finder.filter));
          // ignore: unawaited_futures

          // Get the result at query time first
          if (debugListener) {
            print('matching $ctlr: ${allMatching.length} on $this');
          }

          await ctlr.add(allMatching, db.cooperator);
        });
      } catch (error, stackTrace) {
        ctlr.addError(error, stackTrace);
      }
    });
    return ctlr.stream;
  }

  @override
  Future<List<RecordSnapshot<K, V>>> getSnapshots(DatabaseClient client) =>
      store.find(client, finder: finder);

  @override
  Future<RecordSnapshot<K, V>> getSnapshot(DatabaseClient client) =>
      store.findFirst(client, finder: finder);
}
