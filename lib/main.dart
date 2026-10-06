import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() {
  runApp(const WaitingRoomApp());
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => QueueProvider(),
      child: const MaterialApp(
        home: WaitingRoomScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupérer l'état et écouter les changements
    final queueProvider = context.watch<QueueProvider>();

    // Contrôleur du champ de saisie
    final controller = TextEditingController();

    void addClient() {
      final name = controller.text.trim();

      if (name.isNotEmpty) {
        context.read<QueueProvider>().addClient(name);
        controller.clear();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Waiting Room'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          children: [
            // Champ de saisie + bouton Ajouter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Client Name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addClient(),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(onPressed: addClient, child: const Text('Add')),
              ],
            ),

            const SizedBox(height: 16),

            // Nombre de clients
            Text(
              'Clients in Queue: ${queueProvider.clients.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // Liste des clients
            Expanded(
              child: ListView.builder(
                itemCount: queueProvider.clients.length,

                itemBuilder: (context, index) {
                  final clientName = queueProvider.clients[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.indigo),

                      title: Text(clientName),

                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),

                        tooltip: 'Remove client',

                        onPressed: () {
                          context.read<QueueProvider>().removeClient(
                            clientName,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bouton Next Client
      floatingActionButton: FloatingActionButton(
        key: const Key('nextClientButton'),
        onPressed: () {
          context.read<QueueProvider>().nextClient();
        },
        tooltip: 'Next Client',
        child: const Icon(Icons.skip_next),
      ),
    );
  }
}
