import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/home_screen/domain/entities/home_entity.dart';

abstract interface class HomeScreenRepository {
  Future<Either<Failure, List<HomeEntity>>> getHomeEntities();
}
