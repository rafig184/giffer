import 'package:giffer_flutter/model/favorite_model.dart';
import 'package:hive/hive.dart';

class FavoriteDataAdapter extends TypeAdapter<FavoriteData> {
  @override
  final typeId = 0; // Unique identifier for your custom class

  @override
  FavoriteData read(BinaryReader reader) {
    // Read data from binary and construct a ShiftData object
    return FavoriteData(
      id: reader.readString(),
      url: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteData obj) {
    // Write data from a ShiftData object to binary
    writer.writeString(obj.id);
    writer.writeString(obj.url);
  }
}
