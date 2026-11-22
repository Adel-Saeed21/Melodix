import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/melodix_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupGetIt();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );

  runApp(const MelodixApp());
}
