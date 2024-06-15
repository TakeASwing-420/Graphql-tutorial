import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'provider.dart' as provider;
import 'query.dart' as query;

void main() async {
  // Initialize Hive for persistence
  await initHiveForFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: provider.client,
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _queryResult;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _executeQuery(int queryIndex) async {
    setState(() {
      _isLoading = true;
      _queryResult = null;
      _errorMessage = null;
    });

    try {
      final GraphQLClient client = GraphQLProvider.of(context).value;
      final QueryResult result = await client.query(
        QueryOptions(
          document: query.documents[queryIndex],
          variables: queryIndex == 1 ? {'_ID': _controller.text} : {},
        ),
      );

      if (result.hasException) {
        setState(() {
          _errorMessage = result.exception.toString();
        });
      } else {
        setState(() {
          _queryResult = result.data.toString();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GraphQL Flutter Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Enter Game ID'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _executeQuery(0),
              child: const Text('Fetch All Games'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _executeQuery(1),
              child: const Text('Fetch Game by ID'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : _queryResult != null
                    ? Text(_queryResult!)
                    : _errorMessage != null
                        ? Text('Error: $_errorMessage')
                        : Container(),
          ],
        ),
      ),
    );
  }
}
