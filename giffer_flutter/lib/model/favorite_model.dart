class FavoriteData {
  String id;
  String url;

  FavoriteData({
    required this.id,
    required this.url,
  });

  factory FavoriteData.fromJson(Map<String, dynamic> json) {
    return FavoriteData(
      id: json['id'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
    };
  }
}
