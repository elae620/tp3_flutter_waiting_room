# TP3 — Provider & Scalable State Management with TDD

## 1. Objectif du TP

L'objectif de ce TP est de découvrir une meilleure manière de gérer l'état dans une application Flutter en utilisant **Provider** et **ChangeNotifier**, tout en appliquant la méthode **TDD (Test Driven Development)**.

Dans notre application, nous avons une petite application de **salle d'attente** permettant de :

* ajouter des clients ;
* afficher les clients dans une file d'attente ;
* supprimer un client ;
* faire passer le client suivant avec le bouton **Next Client**.

Le TP permet surtout de remplacer la gestion locale de l'état avec `setState()` par une gestion d'état centralisée avec **Provider**. Le workshop présente cette évolution comme une solution permettant d'éviter le *prop drilling* et de mieux organiser l'état lorsque l'application devient plus grande.

---

# 2. Situation avant le TP3

Au départ, l'application utilisait un gestionnaire appelé :

```text
WaitingRoomManager
```

L'écran `WaitingRoomScreen` était un `StatefulWidget`.

La gestion des clients se faisait directement dans l'écran avec :

```dart
setState()
```

Le fonctionnement était approximativement :

```text
WaitingRoomScreen
       ↓
setState()
       ↓
WaitingRoomManager
       ↓
Liste des clients
```

Cette solution fonctionne pour une petite application, mais elle devient moins pratique lorsque plusieurs widgets doivent utiliser les mêmes données.

---

# 3. Pourquoi utiliser Provider ?

## Problème

Dans une application plus grande, plusieurs widgets peuvent avoir besoin du même état.

On pourrait avoir :

```text
Widget A
   ↓
Widget B
   ↓
Widget C
   ↓
Widget D
```

et devoir transmettre les données d'un widget à l'autre.

C'est ce qu'on appelle le **prop drilling**.

## Solution

Provider permet de placer l'état dans un endroit central :

```text
                 QueueProvider
                      │
          ┌───────────┼───────────┐
          ↓           ↓           ↓
       Widget A    Widget B    Widget C
```

Les widgets qui ont besoin de l'état peuvent directement accéder au Provider.

Le workshop présente Provider comme une solution permettant de centraliser l'état et de reconstruire les widgets concernés lorsqu'il change.

---

# 4. Étape 1 — Installer Provider

Dans `pubspec.yaml`, nous avons ajouté la dépendance :

```yaml
dependencies:
  provider: ^6.1.5+1
```

Puis nous avons exécuté :

```powershell
flutter pub get
```

Cette commande télécharge et installe les dépendances du projet.

---

# 5. Étape 2 — Commencer par le test avec TDD

Avant d'implémenter la nouvelle fonctionnalité, nous avons écrit un test pour `nextClient()`.

Le test vérifie que le premier client de la file est supprimé.

Exemple :

```dart
test('should remove the first client when nextClient() is called', () {
  // ARRANGE
  final manager = WaitingRoomManager();

  manager.addClient('Client A');
  manager.addClient('Client B');

  // ACT
  manager.nextClient();

  // ASSERT
  expect(manager.clients.length, 1);
  expect(manager.clients.first, 'Client B');
});
```

L'idée est :

```text
Avant :

Client A
Client B

       ↓ nextClient()

Après :

Client B
```

Cette étape correspond à la logique **TDD** du workshop.

---

# 6. TDD — Les trois étapes

TDD signifie :

> **Test Driven Development**

En français :

> **Développement piloté par les tests.**

Il fonctionne avec trois étapes principales.

## 🔴 RED

On écrit d'abord le test.

Le test échoue car la fonctionnalité n'existe pas encore.

```text
Test ❌
```

Par exemple, `nextClient()` n'existe pas encore.

---

## 🟢 GREEN

On écrit le code nécessaire pour faire passer le test.

Nous avons ajouté :

```dart
void nextClient() {
  if (_clients.isNotEmpty) {
    _clients.removeAt(0);
    notifyListeners();
  }
}
```

Puis :

```powershell
flutter test
```

Les tests passent.

```text
All tests passed!
```

---

## 🔵 REFACTOR

Une fois les tests fonctionnels, on peut améliorer l'organisation du code sans modifier le comportement attendu.

Le principe est :

```text
RED
 ↓
GREEN
 ↓
REFACTOR
 ↓
Tests
```

Les tests permettent de vérifier que les modifications n'ont pas cassé les fonctionnalités existantes.

---

# 7. Étape 3 — Créer QueueProvider

Nous avons ensuite remplacé :

```text
WaitingRoomManager
```

par :

```text
QueueProvider
```

Le fichier :

```text
lib/queue_provider.dart
```

contient :

```dart
import 'package:flutter/foundation.dart';

class QueueProvider extends ChangeNotifier {
  final List<String> _clients = [];

  List<String> get clients => _clients;

  void addClient(String name) {
    _clients.add(name);
    notifyListeners();
  }

  void removeClient(String name) {
    _clients.remove(name);
    notifyListeners();
  }

  void nextClient() {
    if (_clients.isNotEmpty) {
      _clients.removeAt(0);
      notifyListeners();
    }
  }
}
```

---

# 8. Pourquoi `ChangeNotifier` ?

Notre classe est :

```dart
class QueueProvider extends ChangeNotifier
```

`ChangeNotifier` permet au Provider de prévenir les widgets lorsqu'une donnée change.

Par exemple :

```dart
_clients.add(name);
notifyListeners();
```

Le fonctionnement est :

```text
Modification de l'état
        ↓
notifyListeners()
        ↓
Les widgets concernés sont prévenus
        ↓
L'interface est mise à jour
```

Le workshop demande précisément que `QueueProvider` hérite de `ChangeNotifier`.

---

# 9. Étape 4 — Connecter Provider à l'application

Dans `main.dart`, nous avons ajouté :

```dart
ChangeNotifierProvider(
  create: (context) => QueueProvider(),
  child: const WaitingRoomApp(),
)
```

Cela rend le `QueueProvider` disponible pour les widgets situés à l'intérieur de l'application.

Architecture :

```text
ChangeNotifierProvider
        ↓
   QueueProvider
        ↓
WaitingRoomApp
        ↓
WaitingRoomScreen
```

---

# 10. Étape 5 — Remplacer StatefulWidget

Avant :

```dart
class WaitingRoomScreen extends StatefulWidget
```

Après :

```dart
class WaitingRoomScreen extends StatelessWidget
```

Pourquoi ?

Parce que l'état de la file d'attente n'est plus stocké directement dans `WaitingRoomScreen`.

Il est maintenant stocké dans :

```text
QueueProvider
```

Donc :

```text
Avant :

WaitingRoomScreen
      ↓
   State
      ↓
WaitingRoomManager


Après :

WaitingRoomScreen
      ↓
QueueProvider
      ↓
ChangeNotifier
```

Cela rend la séparation entre l'interface et l'état plus claire.

---

# 11. `context.watch()` et `context.read()`

C'est une partie très importante du TP.

## `context.watch()`

Nous avons utilisé :

```dart
final queueProvider = context.watch<QueueProvider>();
```

`watch()` signifie :

> Je veux écouter les changements du Provider.

Par exemple :

```dart
'Clients in Queue: ${queueProvider.clients.length}'
```

Si le nombre de clients change, le widget est reconstruit.

---

## `context.read()`

Nous avons utilisé :

```dart
context.read<QueueProvider>().addClient(name);
```

`read()` signifie :

> Je veux accéder au Provider pour effectuer une action, sans écouter les changements à cet endroit.

Nous l'utilisons pour :

```dart
context.read<QueueProvider>().addClient(name);
```

```dart
context.read<QueueProvider>().removeClient(clientName);
```

```dart
context.read<QueueProvider>().nextClient();
```

### À retenir

| Méthode   | Utilisation                                   |
| --------- | --------------------------------------------- |
| `watch()` | Lire l'état + écouter les changements         |
| `read()`  | Accéder au Provider pour effectuer une action |

Le workshop demande justement l'utilisation de `watch()` pour observer l'état et `read()` pour déclencher les actions.

---

# 12. Les boutons de l'application

## ➕ Add

Le bouton **Add** existait déjà avant le TP3.

Il permet d'ajouter un client.

Avant :

```text
Add
 ↓
setState()
 ↓
WaitingRoomManager
```

Après :

```text
Add
 ↓
context.read<QueueProvider>()
 ↓
addClient()
 ↓
notifyListeners()
 ↓
Interface mise à jour
```

Donc le bouton n'est pas nouveau, mais son fonctionnement a été adapté à Provider.

---

## 🗑️ Delete

Le bouton **Delete** existait également avant le TP3.

Il permet de supprimer un client précis.

Après le passage à Provider :

```dart
context
    .read<QueueProvider>()
    .removeClient(clientName);
```

---

## ⏭️ Next Client

C'est le **nouveau bouton ajouté dans ce TP3**.

Il permet de faire passer le client suivant.

Exemple :

```text
Avant :

Client A
Client B
Client C
```

Après avoir appuyé sur **Next Client** :

```text
Client B
Client C
```

Le bouton est défini avec :

```dart
FloatingActionButton(
  key: const Key('nextClientButton'),
  onPressed: () {
    context.read<QueueProvider>().nextClient();
  },
  tooltip: 'Next Client',
  child: const Icon(Icons.skip_next),
)
```

Le workshop demande explicitement ce bouton et son test widget.

---

# 13. Étape 6 — Test widget

Nous avons également ajouté un test qui simule l'utilisation réelle de l'application.

Le test :

1. démarre l'application avec `QueueProvider` ;
2. ajoute `Client A` ;
3. ajoute `Client B` ;
4. clique sur **Next Client** ;
5. vérifie que `Client A` a disparu ;
6. vérifie que `Client B` est toujours présent ;
7. vérifie que le nombre de clients est `1`.

Exemple de résultat attendu :

```text
Avant :

Clients in Queue: 2

Client A
Client B


Après Next Client :

Clients in Queue: 1

Client B
```

---

# 14. Différence entre Unit Test et Widget Test

## Unit Test

Le test unitaire teste directement la logique du Provider.

```text
QueueProvider
     ↓
nextClient()
     ↓
Résultat attendu
```

Il vérifie par exemple :

```text
[A, B]
 ↓
nextClient()
 ↓
[B]
```

---

## Widget Test

Le test widget teste l'interaction avec l'interface.

```text
Utilisateur
    ↓
Clique sur Next Client
    ↓
Provider
    ↓
Interface
    ↓
Client A disparaît
```

### Résumé

| Test        | Ce qu'il teste                      |
| ----------- | ----------------------------------- |
| Unit Test   | Logique de `QueueProvider`          |
| Widget Test | Interface + interaction utilisateur |

---

# 15. Les erreurs rencontrées pendant le TP

## Erreur `WaitingRoomManager not found`

Après avoir renommé le fichier et créé `QueueProvider`, l'ancien `main.dart` contenait encore :

```dart
final WaitingRoomManager _manager = WaitingRoomManager();
```

Flutter affichait :

```text
Error: Type 'WaitingRoomManager' not found.
```

### Solution

Nous avons remplacé l'ancien système par :

```dart
QueueProvider
```

et connecté l'application avec :

```dart
ChangeNotifierProvider
```

---

# 16. Vérification des tests

Après les modifications, nous avons exécuté :

```powershell
flutter test
```

Les tests fonctionnaient correctement.

Cela confirme notamment :

* `QueueProvider` fonctionne ;
* `nextClient()` fonctionne ;
* le test widget fonctionne ;
* l'intégration avec Provider fonctionne.

---

# 17. Problème rencontré avec `flutter run`

Lorsque nous avons exécuté :

```powershell
flutter run
```

Flutter a affiché :

```text
No supported devices connected.
```

Flutter a détecté :

```text
Windows
Chrome
Edge
```

mais aucun appareil Android compatible.

Ce problème n'est **pas une erreur du code de l'application**.

La solution est de démarrer un émulateur Android dans Android Studio, puis de vérifier avec :

```powershell
flutter devices
```

et ensuite :

```powershell
flutter run
```

Il ne faut pas exécuter `flutter create .` inutilement puisque le projet existe déjà et que les tests fonctionnent.

---

# 18. Architecture finale

L'architecture de notre application est maintenant :

```text
                    Flutter App
                        │
                        ↓
            ChangeNotifierProvider
                        │
                        ↓
                 QueueProvider
                        │
        ┌───────────────┼───────────────┐
        ↓               ↓               ↓
   addClient()     removeClient()   nextClient()
        │               │               │
        └───────────────┼───────────────┘
                        ↓
                 notifyListeners()
                        ↓
               WaitingRoomScreen
                        │
                 context.watch()
                        ↓
                Interface mise à jour
```

Les actions utilisent :

```text
context.read()
```

et l'affichage de l'état utilise :

```text
context.watch()
```

---

# 19. Comparaison avant / après TP3

## Avant

```text
WaitingRoomScreen
      ↓
StatefulWidget
      ↓
setState()
      ↓
WaitingRoomManager
```

## Après

```text
ChangeNotifierProvider
      ↓
QueueProvider
      ↓
ChangeNotifier
      ↓
notifyListeners()
      ↓
WaitingRoomScreen
      ↓
watch() / read()
```

### Les principaux changements

| Élément           | Avant                | Après               |
| ----------------- | -------------------- | ------------------- |
| Gestionnaire      | `WaitingRoomManager` | `QueueProvider`     |
| État              | Dans le `State`      | Dans le Provider    |
| Widget            | `StatefulWidget`     | `StatelessWidget`   |
| Gestion de l'état | `setState()`         | `ChangeNotifier`    |
| Notification      | `setState()`         | `notifyListeners()` |
| Lecture de l'état | `_manager`           | `context.watch()`   |
| Actions           | `_manager.method()`  | `context.read()`    |
| Add               | Existe déjà          | Adapté à Provider   |
| Delete            | Existe déjà          | Adapté à Provider   |
| Next Client       | ❌ N'existait pas     | ✅ Nouveau           |
| Tests             | Tests existants      | Unit + Widget tests |

---

# 20. Pourquoi cette solution est "Scalable" ?

Le mot **scalable** signifie que l'architecture peut évoluer avec l'application.

Par exemple, si l'application devient plus grande, on peut avoir :

```text
UserProvider
    ↓
Gestion des utilisateurs

QueueProvider
    ↓
Gestion de la file d'attente

CartProvider
    ↓
Gestion du panier

SettingsProvider
    ↓
Gestion des paramètres
```

Chaque Provider peut être responsable d'une partie précise de l'état.

Cela permet d'éviter d'avoir toute la logique dans un seul widget.

---

# 21. Les concepts importants à connaître

## State

Le **State** correspond aux données qui peuvent changer.

Dans notre application :

```text
Liste des clients
```

---

## Provider

Provider permet de **partager et centraliser l'état** entre plusieurs widgets.

---

## ChangeNotifier

`ChangeNotifier` permet de prévenir les widgets lorsque l'état change.

---

## notifyListeners()

```dart
notifyListeners();
```

signifie :

> "L'état vient de changer, prévenez les widgets qui l'écoutent."

---

## watch()

```dart
context.watch<QueueProvider>()
```

signifie :

> "Je veux écouter les changements."

---

## read()

```dart
context.read<QueueProvider>()
```

signifie :

> "Je veux accéder au Provider pour effectuer une action."

---

## TDD

TDD signifie :

> **Test Driven Development**

Cycle :

```text
🔴 RED
Écrire un test qui échoue
        ↓
🟢 GREEN
Écrire le code pour réussir le test
        ↓
🔵 REFACTOR
Améliorer le code
```

---

# 22. Questions que j'ai posées pendant le TP

### Question 1 — Expliquer le concept de provider


---

### Question 2 — Est-ce que je dois supprimer tout le contenu du fichier ?

Oui, pour le nouveau fichier `queue_provider.dart`, nous avons remplacé l'ancien gestionnaire par la nouvelle classe `QueueProvider`.

Pour `main.dart`, nous avons ensuite remplacé l'ancien code par la version utilisant Provider.

---

### Question 3 — Pourquoi j'ai l'erreur `WaitingRoomManager not found` ?

Parce que l'ancien `main.dart` utilisait encore :

```dart
WaitingRoomManager
```

alors que nous étions passés à :

```dart
QueueProvider
```

Il fallait donc adapter `main.dart`.

---

### Question 4 — Quels sont les boutons ajoutés dans le TP3 ?

Le seul **nouveau bouton** est :

```text
⏭️ Next Client
```

Les boutons :

```text
➕ Add
🗑️ Delete
```

existaient déjà.

Leur fonctionnement a simplement été adapté à Provider.

---

### Question 5 — Quelle est la différence entre `watch()` et `read()` ?

```text
watch() → écouter les changements
read()  → effectuer une action
```

---

### Question 6 — Pourquoi utiliser `ChangeNotifier` ?

Pour permettre au Provider de notifier les widgets lorsqu'une modification de l'état se produit.



### Question 7 — Pourquoi le test `nextClient()` ?

Parce qu'il permet de vérifier automatiquement que le premier client est bien retiré de la file.

---

### Question 8 — Pourquoi `flutter run` affiche `No supported devices connected` ?

Parce qu'aucun appareil Android compatible n'était connecté ou lancé.

Ce n'est pas une erreur de Provider ou de notre code.

---

# 23. Checklist finale du TP3

* [x] Installer Provider
* [x] Ajouter `provider` dans `pubspec.yaml`
* [x] Utiliser TDD
* [x] Écrire le test de `nextClient()`
* [x] Créer `QueueProvider`
* [x] Faire hériter `QueueProvider` de `ChangeNotifier`
* [x] Utiliser `notifyListeners()`
* [x] Ajouter `ChangeNotifierProvider`
* [x] Transformer `WaitingRoomScreen` en `StatelessWidget`
* [x] Utiliser `context.watch()`
* [x] Utiliser `context.read()`
* [x] Adapter le bouton Add
* [x] Adapter le bouton Delete
* [x] Ajouter le bouton **Next Client**
* [x] Ajouter le test widget
* [x] Exécuter `flutter test`
* [x] Vérifier que les tests passent
* [x] Tester l'application

Le workshop demande notamment que `QueueProvider` étende `ChangeNotifier`, que l'application utilise `ChangeNotifierProvider`, que l'écran utilise `watch/read`, que le bouton **Next Client** soit présent et que des tests unitaires et widget soient réalisés.

---


```text
Provider
   ↓
centralise l'état

ChangeNotifier
   ↓
signale les changements

watch()
   ↓
écoute les changements

read()
   ↓
effectue les actions

TDD
   ↓
RED → GREEN → REFACTOR
```

**En résumé :**

> **Le TP3 nous apprend à séparer l'interface de la gestion de l'état et à utiliser Provider pour construire une application Flutter plus organisée, maintenable et évolutive, tout en vérifiant son comportement avec TDD.**
