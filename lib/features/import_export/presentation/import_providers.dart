import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/import_repository.dart';

final importRepositoryProvider = Provider<ImportRepository>((ref) => ImportRepository());
