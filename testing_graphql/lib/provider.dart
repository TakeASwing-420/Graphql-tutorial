import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

final HttpLink _httpLink = HttpLink(
  "http://localhost:4000/graphql", // local testing
);

ValueNotifier<GraphQLClient> client = ValueNotifier(
  GraphQLClient(
    link: _httpLink,
    // The default store is the InMemoryStore, which does NOT persist to disk
    cache: GraphQLCache(store: HiveStore()),
  ),
);
