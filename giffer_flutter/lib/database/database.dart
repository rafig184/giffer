import 'package:giffer_flutter/model/favorite_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoriteDatabase {
  List<FavoriteData> favoriteGifs = [];

  final Box<FavoriteData> _myBox = Hive.box<FavoriteData>('mybox');

  void createInitialData() {
    print("created DB");
    favoriteGifs = [];
  }

  void loadData() {
    print("Loading Data from DB");
    favoriteGifs = _myBox.values.toList();
  }

  void updateDatabase() {
    _myBox.putAll({for (var gif in favoriteGifs) gif.id: gif});
  }

  void addFavorite(FavoriteData favorite) {
    favoriteGifs.add(favorite);
    updateDatabase();
  }
}
