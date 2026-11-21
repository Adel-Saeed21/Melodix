

import 'package:melodix/features/home_screen/domain/entities/home_entity.dart';

abstract interface class HomeScreenLocalDataSource {}

/// Stores homeEntities as JSON through the project's [LocalStorage].
class HomeScreenLocalDataSourceImpl implements HomeScreenLocalDataSource {
  const HomeScreenLocalDataSourceImpl();

  @override
  Future<List<HomeEntity>> getHomeEntities() async {
    //TODO: implement getHomeEntities
    throw UnimplementedError(); 
  }
}
