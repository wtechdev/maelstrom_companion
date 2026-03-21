import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';

/// Progetto attivo selezionato dall'utente. Condiviso tra ProjectsScreen e TimerScreen.
final selectedProjectProvider = StateProvider<Project?>((ref) => null);
