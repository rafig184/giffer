import 'package:giffer_flutter/model/favorite_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoriteDatabase {
  // List<FavoriteData> favoriteGifs = [];
  List favoriteGifs = [];

  // final Box<FavoriteData> _myBox = Hive.box<FavoriteData>('mybox');
  final _myBox = Hive.box('mybox');

  void createInitialData() {
    print("created DB");
    favoriteGifs = [];
  }

  void loadData() {
    print("Loading Data from DB");
    // favoriteGifs = _myBox.values.toList();
    favoriteGifs = _myBox.get("FAVORITELIST");
  }

  void updateDatabase() {
    // _myBox.putAll({for (var gif in favoriteGifs) gif.id: gif});
    _myBox.put("FAVORITELIST", favoriteGifs);
  }

  void addFavorite(FavoriteData favorite) {
    favoriteGifs.add(favorite);
    updateDatabase();
  }

  void deleteFavorite(FavoriteData favorite) {
    favoriteGifs.removeWhere((item) => item.id == favorite.id);
    _myBox.delete(favorite.id);
  }

  bool isFavorite(String id) {
    return favoriteGifs.any((favorite) => favorite.id == id);
  }
}
