import 'package:graphql_flutter/graphql_flutter.dart';

// Define the queries
List documents = [
  gql('''query getGames {
    games {
      platform
    }
  }'''),
  gql('''
query getGame(\$_ID: ID!){
  game(id: \$_ID){
    platform
    reviews {
      content
    }
  }
}
''')
];
