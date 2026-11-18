
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:mynote/screens/auth_gate.dart';

import 'firebase_options.dart';

import 'repositories/firebase_auth_repository.dart';
import 'repositories/firestore_note_repository.dart';

import 'providers/auth_provider.dart';
import 'providers/note_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyNoteApp());
}

class MyNoteApp extends StatelessWidget {
  const MyNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: FirebaseAuthRepository(
              serverClientId: '752823795173-ntsm4ncbobms49b60ciheet5fe7cob2s.apps.googleusercontent.com',

            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NoteProvider(
            noteRepository: FirestoreNoteRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MyNote',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate()
      ),
    );
  }
}
