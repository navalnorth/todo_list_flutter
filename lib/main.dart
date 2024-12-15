import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Todo List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CollectionReference _todos =
      FirebaseFirestore.instance.collection("todos");

      final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: SafeArea(
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Ajouter une nouvelle tâche",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(onPressed: () async {
                    // Ajouter une tache
                    await _todos.add({
                      "task": _controller.text,
                      "done": false
                    });
                    _controller.clear();
                  }, 
                  icon: const Icon(Icons.add))
                ),
              ),
            ),
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
                    stream: _todos.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListView(
                          children: snapshot.data!.docs.map((doc) {
                            return Dismissible(
                              key: Key(doc.reference.id),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (direction) async {
                                await _todos.doc(doc.reference.id).delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Tâche "${doc["task"]}" supprimée' ),
                                  ),
                                );
                              },
                              background: Container(
                                color: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerLeft,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: ListTile(
                                title: Text(
                                    doc["task"],
                                    style: TextStyle(
                                      decoration: doc["done"]
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    ),
                                ),
                                trailing: Checkbox(
                                  value: doc["done"], 
                                  onChanged: (value) {
                                    _todos.doc(doc.reference.id).update({"done": value});
                                  }
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      } else if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      } else {
                        return const Center(
                          child: Text("Pas de tâches disponibles"),
                        );
                      }
                    })),
          ],
        )));
  }
}
