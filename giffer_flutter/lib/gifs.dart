import 'dart:async';
import 'package:android_download_manager/android_download_manager.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:core';
import 'package:flutter/widgets.dart';
import 'package:giffer_flutter/database/database.dart';
import 'package:giffer_flutter/model/favorite_model.dart';
import 'package:giffer_flutter/ui-widgets/spinners.dart';
import 'package:http/http.dart' as http;
import 'package:msh_checkbox/msh_checkbox.dart';
import 'package:show_network_image/show_network_image.dart';
import 'package:social_share/social_share.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:giffer_flutter/colors.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';

class GifsPage extends StatefulWidget {
  const GifsPage();

  @override
  State<GifsPage> createState() => _GifsPageState();
}

enum GifsProvider { Giphy, Tenor, Trending, Favorites }

class _GifsPageState extends State<GifsPage> {
  List<dynamic> gifsListGiphy = [];
  List<dynamic> gifsListTenor = [];
  List<dynamic> categoriesGiphy = [];
  List<dynamic> categoriesTenor = [];
  List<dynamic> favorites = [];
  bool isSearch = false;
  bool isFavorite = false;
  TextEditingController searchController = TextEditingController();
  String giphyApiKey = "K1HxaGhOObjpIjOZh0d3mZcsv1pHflei";
  String tenorApiKey = "AIzaSyBKMCcIReVm4_0YpFUnlhuZkRD_aOfrNCc";
  String geminiAIKey = "AIzaSyDq-ujx6iqbRrhLJPOSoCMxME30AuWUj_I";
  bool isLoadingSnackBar = false;
  bool isLoadingGifs = false;
  bool isSearchWithAiChecked = false;
  String isAISearchStatus = "off";
  GifsProvider gifsView = GifsProvider.Trending;
  bool isSafeChecked = true;
  String isSafeSearch = "on";
  String ratingGiphy = "g";
  String ratingTenor = "high";
  String resultAI = "";
  String giphyApi = "";
  String tenorApi = "";
  Set<String> favoriteGifIds = {};

  final _mybox = Hive.box('mybox');
  late FavoriteDatabase db;

  @override
  void initState() {
    super.initState();
    db = FavoriteDatabase();
    fetchTrandingGifs();
    getCategories();
    initializeDatabase();
  }

  Future<void> initializeDatabase() async {
    if (_mybox.get("FAVORITELIST") == null) {
      db.createInitialData();
    } else {
      db.loadData();
    }
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  Future<void> getCategories() async {
    var giphyCatApi =
        "https://api.giphy.com/v1/gifs/categories?api_key=K1HxaGhOObjpIjOZh0d3mZcsv1pHflei";
    try {
      final response = await http.get(Uri.parse(giphyCatApi));
      if (response.statusCode != 200) {
        throw Exception('Failed to load categories');
      } else {
        setState(() {
          final data = jsonDecode(response.body);
          categoriesGiphy = data['data'];
          print("categories giphy = ${response.body}");
        });
      }
    } catch (e) {
      print(e);
    }
    var tenorCatApi =
        "https://tenor.googleapis.com/v2/categories?key=AIzaSyBKMCcIReVm4_0YpFUnlhuZkRD_aOfrNCc&client_key=my_test_app";
    try {
      final response = await http.get(Uri.parse(tenorCatApi));
      if (response.statusCode != 200) {
        throw Exception('Failed to load categories');
      } else {
        setState(() {
          final data = jsonDecode(response.body);
          categoriesTenor = data['tags'];
          print("categories tenor = ${response.body}");
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void getFavorites() {
    try {
      isLoadingGifs = true;
      setState(() {
        favorites = db.favoriteGifs;
      });
    } catch (e) {
      print(e);
    } finally {
      isLoadingGifs = false;
    }
  }

  Future<void> searchWithAi(searchText) async {
    // Access your API key as an environment variable (see "Set up your API key" above)
    final apiKey = geminiAIKey;

    // The Gemini 1.5 models are versatile and work with both text-only and multimodal prompts
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final content = [
      Content.text(
          'give me one best keywords for a gif based on this prompt : $searchText')
    ];
    final response = await model.generateContent(content);
    print(searchText);
    print(response.text);
    setState(() {
      resultAI = response.text.toString();
    });
  }

  Future fetchTrandingGifs() async {
    var api =
        "https://api.giphy.com/v1/gifs/trending?api_key=K1HxaGhOObjpIjOZh0d3mZcsv1pHflei&limit=25&offset=0&rating=g&bundle=messaging_non_clips";
    try {
      setState(() {
        isLoadingGifs = true;
      });
      final response = await http.get(Uri.parse(api));
      if (response.statusCode != 200) {
        throw Exception('Failed to load gifs');
      } else {
        setState(() {
          final data = jsonDecode(response.body);
          gifsListGiphy = data['data'];
          isSearch = true;
          print(response.body);
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoadingGifs = false;
      });
    }
  }

  Future fetchGifs() async {
    if (gifsView == GifsProvider.Favorites) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Can't Search on Favorites tab..")),
      );
      return;
    }
    setState(() {
      gifsListGiphy = [];
      gifsListTenor = [];
    });

    var searchValue = searchController.text;

    if (gifsView == GifsProvider.Trending) {
      setState(() {
        gifsView = GifsProvider.Giphy;
      });
    }

    if (gifsView == GifsProvider.Giphy) {
      if (!isSafeChecked) {
        setState(() {
          ratingGiphy = "r";
        });
      } else {
        setState(() {
          ratingGiphy = "g";
        });
      }
      if (isSearchWithAiChecked) {
        await searchWithAi(searchValue);
        setState(() {
          giphyApi =
              'https://api.giphy.com/v1/gifs/search?api_key=$giphyApiKey&q=$resultAI&limit=50&offset=0&rating=$ratingGiphy&lang=en&bundle=messaging_non_clips';
        });
      } else {
        setState(() {
          giphyApi =
              'https://api.giphy.com/v1/gifs/search?api_key=$giphyApiKey&q=$searchValue&limit=50&offset=0&rating=$ratingGiphy&lang=en&bundle=messaging_non_clips';
        });
      }
      print(resultAI);
      try {
        setState(() {
          isLoadingGifs = true;
        });

        final response = await http.get(Uri.parse(giphyApi));
        if (response.statusCode != 200) {
          throw Exception('Failed to load gifs');
        } else {
          setState(() {
            final data = jsonDecode(response.body);
            gifsListGiphy = data['data'];
            isSearch = true;
            print(response.body);
          });
        }
      } catch (e) {
        print(e);
      } finally {
        setState(() {
          isLoadingGifs = false;
        });
      }
    } else if (gifsView == GifsProvider.Tenor) {
      if (!isSafeChecked) {
        setState(() {
          ratingTenor = "off";
        });
      } else {
        setState(() {
          ratingTenor = "high";
        });
      }

      if (isSearchWithAiChecked) {
        await searchWithAi(searchValue);
        setState(() {
          tenorApi =
              "https://tenor.googleapis.com/v2/search?q=$resultAI&key=$tenorApiKey&limit=50&client_key=my_test_app&contentfilter=$ratingTenor";
        });
      } else {
        setState(() {
          tenorApi =
              "https://tenor.googleapis.com/v2/search?q=$searchValue&key=$tenorApiKey&limit=50&client_key=my_test_app&contentfilter=$ratingTenor";
        });
      }

      try {
        setState(() {
          isLoadingGifs = true;
        });
        final response = await http.get(Uri.parse(tenorApi));
        if (response.statusCode != 200) {
          throw Exception('Failed to load gifs');
        } else {
          setState(() {
            final data = jsonDecode(response.body);
            gifsListTenor = data['results'];
            print(response.body);
            isSearch = true;
          });
        }
      } catch (e) {
        print(e);
      } finally {
        setState(() {
          isLoadingGifs = false;
        });
      }
    }
  }

  void clearSearch() {
    fetchTrandingGifs();
    setState(() {
      isSearch = false;
      gifsListGiphy = [];
      gifsListTenor = [];
      searchController.clear();
      gifsView = GifsProvider.Trending;
    });
  }

  Future<void> onGifTap(gifUrl) async {
    try {
      final directory = await getExternalStorageDirectory();

      if (directory == null) {
        throw Exception("Unable to get external storage directory");
      }

      final gifferDirectory = Directory('${directory.path}/giffer');

      // Ensure the directory exists
      if (!await gifferDirectory.exists()) {
        await gifferDirectory.create(recursive: true);
      } else {
        // Clear the directory
        await _clearDirectory(gifferDirectory);
      }
      AndroidDownloadManager.enqueue(
          downloadUrl: gifUrl,
          downloadPath: directory.path + '/giffer',
          fileName: "test.gif",
          notificationVisibility: NotificationVisibility.VISIBILITY_VISIBLE);
      final filePath = '${directory.path}/giffer/test.gif';
      setState(() {
        isLoadingSnackBar = true;
      });
      if (isLoadingSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing GIF to share...')),
        );
      }
      await Future.delayed(Duration(seconds: 5));

      if (await File(filePath).exists()) {
        setState(() {
          isLoadingSnackBar = false;
        });
        await SocialShare.shareOptions("", imagePath: filePath);
      } else {
        throw Exception("File not found after timeout");
      }
    } catch (e) {
      print('Error sharing GIF: $e');
    }
  }

  void onLongPress(gif) {
    final imageProvider = Image.network(gif).image;
    showImageViewer(context, imageProvider, onViewerDismissed: () {
      print("dismissed");
    });
  }

  Future<void> _clearDirectory(Directory directory) async {
    if (await directory.exists()) {
      final files = directory.listSync();
      for (var file in files) {
        try {
          if (file is File) {
            await file.delete();
          } else if (file is Directory) {
            await file.delete(recursive: true);
          }
        } catch (e) {
          print('Error deleting file: $e');
        }
      }
    }
  }

  Future<void> downloadImage(gifUrl, gifId) async {
    try {
      AndroidDownloadManager.enqueue(
          downloadUrl: gifUrl,
          downloadPath: '/storage/emulated/0/Download',
          fileName: "$gifId.gif",
          notificationVisibility: NotificationVisibility.VISIBILITY_VISIBLE);
      setState(() {
        isLoadingSnackBar = true;
      });
      if (isLoadingSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading GIF...')),
        );
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> addToFavorite(String url, String id) async {
    final favorite = FavoriteData(id: id, url: url);

    setState(() {
      if (db.isFavorite(id)) {
        db.deleteFavorite(favorite);
      } else {
        db.addFavorite(favorite);
      }
      isLoadingSnackBar = true;
    });

    if (isLoadingSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(db.isFavorite(id)
              ? 'Added to favorites..'
              : 'Removed from favorites..'),
        ),
      );
    }

    // Print each FavoriteData instance in a readable format
    for (var favorite in db.favoriteGifs) {
      print(favorite);
    }
  }

  Future<void> removeFromFavorites(String url, String id) async {
    final favorite = FavoriteData(id: id, url: url);
    setState(() {
      db.deleteFavorite(favorite);
      favoriteGifIds.remove(id);
    });
  }

  Future<void> removeAllFromFavorites() async {
    await db.deleteAll();
    setState(() {
      favoriteGifIds.clear();
    });
  }

  Color heartColor(String gifId) {
    return favoriteGifIds.contains(gifId) ? Colors.red : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15.0, bottom: 15.0),
              child: SearchBar(
                controller: searchController,
                backgroundColor:
                    MaterialStateProperty.all(Colors.grey.shade200),
                hintText: "Search GIFS...",
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (value) {
                  fetchGifs();
                },
                leading: TextButton(
                    style: ButtonStyle(
                        iconColor: MaterialStateProperty.all(secondaryColor)),
                    onPressed: () => fetchGifs(),
                    child: const Icon(Icons.search)),
                trailing: <Widget>[
                  TextButton(
                      style: ButtonStyle(
                          iconColor: MaterialStateProperty.all(secondaryColor)),
                      onPressed: () => clearSearch(),
                      child: const Icon(Icons.close)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 7.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Safe Search $isSafeSearch "),
                  MSHCheckbox(
                    size: 20,
                    value: isSafeChecked,
                    colorConfig: MSHColorConfig.fromCheckedUncheckedDisabled(
                      checkedColor: secondaryColor,
                    ),
                    style: MSHCheckboxStyle.fillScaleCheck,
                    onChanged: (selected) {
                      setState(() {
                        isSafeChecked = selected;
                        if (!isSafeChecked) {
                          isSafeSearch = "off";
                        } else {
                          isSafeSearch = "on";
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 30),
                  Text("AI Search $isAISearchStatus "),
                  MSHCheckbox(
                    size: 20,
                    value: isSearchWithAiChecked,
                    colorConfig: MSHColorConfig.fromCheckedUncheckedDisabled(
                      checkedColor: secondaryColor,
                    ),
                    style: MSHCheckboxStyle.fillScaleCheck,
                    onChanged: (selected) {
                      setState(() {
                        isSearchWithAiChecked = selected;
                        if (!isSearchWithAiChecked) {
                          isAISearchStatus = "off";
                        } else {
                          isAISearchStatus = "on";
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                height: 30,
                child: SegmentedButton<GifsProvider>(
                    style: SegmentedButton.styleFrom(
                      // maximumSize: const Size(double.infinity, 15),

                      backgroundColor: Colors.grey[200],
                      foregroundColor: secondaryColor,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: secondaryColor,
                    ),
                    segments: const <ButtonSegment<GifsProvider>>[
                      ButtonSegment<GifsProvider>(
                        value: GifsProvider.Giphy,
                        label: Text(
                          'Giphy',
                          style: TextStyle(height: -1.3),
                        ),
                      ),
                      ButtonSegment<GifsProvider>(
                        value: GifsProvider.Trending,
                        label: Text(
                          'Trending',
                          style: TextStyle(height: -1.3),
                        ),
                      ),
                      ButtonSegment<GifsProvider>(
                        value: GifsProvider.Favorites,
                        label: Text(
                          'Favorites',
                          style: TextStyle(height: -1.3),
                        ),
                      ),
                      ButtonSegment<GifsProvider>(
                        value: GifsProvider.Tenor,
                        label: Text(
                          'Tenor',
                          style: TextStyle(height: -1.3),
                        ),
                      ),
                    ],
                    selected: <GifsProvider>{gifsView},
                    onSelectionChanged: (Set<GifsProvider> newSelection) {
                      setState(() {
                        gifsView = newSelection.first;
                        if (gifsView == GifsProvider.Trending) {
                          isFavorite = false;
                          fetchTrandingGifs();
                        } else if (gifsView == GifsProvider.Favorites) {
                          isFavorite = true;
                        } else {
                          isFavorite = false;
                          fetchGifs();
                        }
                      });
                    }),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                gifsView == GifsProvider.Favorites
                    ? ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.grey[200])),
                        onPressed: () => removeAllFromFavorites(),
                        child: const Text("Clear all",
                            style: TextStyle(color: secondaryColor)),
                      )
                    : ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.grey[200])),
                        onPressed: () => onCategoryTap(),
                        child: const Text("Categories",
                            style: TextStyle(color: secondaryColor)),
                      ),
              ],
            ),
            isSearch
                ? Expanded(
                    child: isLoadingGifs
                        ? spinkit
                        : gifsListGiphy.isEmpty &&
                                gifsListTenor.isEmpty &&
                                db.favoriteGifs.isEmpty
                            ? const Text("Couldn't find any GIF...")
                            : GridView.builder(
                                padding: const EdgeInsets.all(10.0),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 10.0,
                                  mainAxisSpacing: 10.0,
                                ),
                                itemCount: () {
                                  if (gifsView == GifsProvider.Giphy) {
                                    return gifsListGiphy.length;
                                  } else if (gifsView ==
                                      GifsProvider.Trending) {
                                    return gifsListGiphy.length;
                                  } else if (gifsView ==
                                      GifsProvider.Favorites) {
                                    return db.favoriteGifs.length;
                                  } else {
                                    return gifsListTenor.length;
                                  }
                                }(),
                                itemBuilder: (context, index) {
                                  String imageUrl;
                                  if (gifsView == GifsProvider.Giphy) {
                                    imageUrl = gifsListGiphy[index]['images']
                                        ['original']['url'];
                                  } else if (gifsView ==
                                      GifsProvider.Trending) {
                                    imageUrl = gifsListGiphy[index]['images']
                                        ['original']['url'];
                                  } else if (gifsView ==
                                      GifsProvider.Favorites) {
                                    imageUrl = db.favoriteGifs[index].url;
                                  } else {
                                    imageUrl = gifsListTenor[index]
                                        ['media_formats']['gif']['url'];
                                  }
                                  return InkWell(
                                    onTap: () => gifsView == GifsProvider.Giphy
                                        ? onGifTap(gifsListGiphy[index]
                                            ['images']['original']['url'])
                                        : gifsView == GifsProvider.Trending
                                            ? onGifTap(gifsListGiphy[index]
                                                ['images']['original']['url'])
                                            : gifsView == GifsProvider.Favorites
                                                ? onGifTap(
                                                    db.favoriteGifs[index].url)
                                                : onGifTap(gifsListTenor[index]
                                                        ['media_formats']['gif']
                                                    ['url']),
                                    onLongPress: () => gifsView ==
                                            GifsProvider.Giphy
                                        ? onLongPress(gifsListGiphy[index]
                                            ['images']['original']['url'])
                                        : gifsView == GifsProvider.Trending
                                            ? onLongPress(gifsListGiphy[index]
                                                ['images']['original']['url'])
                                            : gifsView == GifsProvider.Favorites
                                                ? onLongPress(
                                                    db.favoriteGifs[index].url)
                                                : onLongPress(
                                                    gifsListTenor[index]
                                                            ['media_formats']
                                                        ['gif']['url']),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        child: Stack(
                                          children: [
                                            FutureBuilder(
                                              future: _loadImage(imageUrl),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Center(
                                                      child: smallSpinkit);
                                                } else if (snapshot.hasError) {
                                                  return const Center(
                                                      child: Icon(Icons.error));
                                                } else {
                                                  return ShowNetworkImage(
                                                    imageSrc: imageUrl,
                                                    mobileBoxFit: BoxFit.cover,
                                                    mobileHeight: 300,
                                                    mobileWidth: 300,
                                                  );
                                                }
                                              },
                                            ),
                                            Positioned(
                                              bottom: 10.0,
                                              right: 10.0,
                                              child: GestureDetector(
                                                onTap: () => gifsView ==
                                                        GifsProvider.Giphy
                                                    ? downloadImage(
                                                        gifsListGiphy[index]
                                                                ['images']
                                                            ['original']['url'],
                                                        gifsListGiphy[index]
                                                            ['id'])
                                                    : gifsView ==
                                                            GifsProvider
                                                                .Trending
                                                        ? downloadImage(
                                                            gifsListGiphy[index]
                                                                        ['images']
                                                                    ['original']
                                                                ['url'],
                                                            gifsListGiphy[index]
                                                                ['id'])
                                                        : gifsView ==
                                                                GifsProvider
                                                                    .Favorites
                                                            ? downloadImage(
                                                                db.favoriteGifs[index]
                                                                    .url,
                                                                db.favoriteGifs[index].id)
                                                            : downloadImage(gifsListTenor[index]['media_formats']['gif']['url'], gifsListTenor[index]['id']),
                                                child: const Stack(children: [
                                                  Icon(
                                                    CupertinoIcons
                                                        .arrow_down_square_fill,
                                                    color: Colors.white,
                                                    size: 30.0,
                                                  ),
                                                  Icon(
                                                    CupertinoIcons
                                                        .arrow_down_square,
                                                    color: Colors.black,
                                                    size: 30.0,
                                                  ),
                                                ]),
                                              ),
                                            ),
                                            !isFavorite
                                                ? Positioned(
                                                    bottom: 10.0,
                                                    left: 10.0,
                                                    child: GestureDetector(
                                                      onTap: gifsView ==
                                                              GifsProvider.Giphy
                                                          ? () => addToFavorite(
                                                              gifsListGiphy[index]
                                                                          ['images']
                                                                      ['original']
                                                                  ['url'],
                                                              gifsListGiphy[index]
                                                                  ['id'])
                                                          : gifsView ==
                                                                  GifsProvider
                                                                      .Trending
                                                              ? () => addToFavorite(
                                                                  gifsListGiphy[index]
                                                                              ['images']
                                                                          ['original']
                                                                      ['url'],
                                                                  gifsListGiphy[index]
                                                                      ['id'])
                                                              : () => addToFavorite(
                                                                  gifsListTenor[index]
                                                                              ['media_formats']
                                                                          ['gif']
                                                                      ['url'],
                                                                  gifsListTenor[index]
                                                                      ['id']),
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.favorite,
                                                            color: db
                                                                    .isFavorite(
                                                              gifsView ==
                                                                      GifsProvider
                                                                          .Giphy
                                                                  ? gifsListGiphy[
                                                                          index]
                                                                      ['id']
                                                                  : gifsView ==
                                                                          GifsProvider
                                                                              .Trending
                                                                      ? gifsListGiphy[
                                                                              index]
                                                                          ['id']
                                                                      : gifsListTenor[
                                                                              index]
                                                                          [
                                                                          'id'],
                                                            )
                                                                ? Colors.red
                                                                : Colors.white,
                                                            size: 30.0,
                                                          ),
                                                          const Icon(
                                                            Icons
                                                                .favorite_border,
                                                            color: Colors.black,
                                                            size: 30.0,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : Positioned(
                                                    top: 10.0,
                                                    left: 10.0,
                                                    child: GestureDetector(
                                                      onTap: () =>
                                                          removeFromFavorites(
                                                              db
                                                                  .favoriteGifs[
                                                                      index]
                                                                  .url,
                                                              db
                                                                  .favoriteGifs[
                                                                      index]
                                                                  .id),
                                                      child: const Stack(
                                                          children: [
                                                            Icon(
                                                              CupertinoIcons
                                                                  .xmark_circle_fill,
                                                              color:
                                                                  Colors.white,
                                                              size: 30.0,
                                                            ),
                                                            Icon(
                                                              CupertinoIcons
                                                                  .xmark_circle,
                                                              color:
                                                                  Colors.black,
                                                              size: 30.0,
                                                            ),
                                                          ]),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Future<void> onCategoryTap() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              List<Widget> buttons;

              if (gifsView == GifsProvider.Giphy) {
                buttons = categoriesGiphy.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          searchController.text = category['name'];
                        });

                        fetchGifs();
                        print('Tapped on ${category['name']}');
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.transparent),
                        shadowColor:
                            MaterialStateProperty.all(Colors.transparent),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8), // Less rounded corners
                          ),
                        ),
                      ),
                      child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(category['gif']['images']
                                      ['downsized_still']
                                  ['url']), // or AssetImage if local
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          alignment: Alignment.center,
                          child: Stack(
                            children: [
                              // Border text
                              Text(
                                category['name'],
                                style: TextStyle(
                                  fontSize: 20.0,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 2
                                    ..color = Colors.black, // Border color
                                ),
                              ),
                              // Fill text
                              Text(
                                category['name'],
                                style: const TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.white, // Fill color
                                ),
                              ),
                            ],
                          )),
                    ),
                  );
                }).toList();
              } else if (gifsView == GifsProvider.Trending) {
                buttons = categoriesGiphy.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            searchController.text = category['name'];
                          });

                          fetchGifs();
                          print('Tapped on ${category['name']}');
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.transparent),
                          shadowColor:
                              MaterialStateProperty.all(Colors.transparent),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // Less rounded corners
                            ),
                          ),
                        ),
                        child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(category['gif']['images']
                                        ['downsized_still']
                                    ['url']), // or AssetImage if local
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            alignment: Alignment.center,
                            child: Stack(
                              children: [
                                // Border text
                                Text(
                                  category['name'],
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 2
                                      ..color = Colors.black, // Border color
                                  ),
                                ),
                                // Fill text
                                Text(
                                  category['name'],
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.white, // Fill color
                                  ),
                                ),
                              ],
                            ))),
                  );
                }).toList();
              } else if (gifsView == GifsProvider.Tenor) {
                buttons = categoriesTenor.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            searchController.text = category['searchterm'];
                          });
                          fetchGifs();
                          print('Tapped on ${category['searchterm']}');
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.transparent),
                          shadowColor:
                              MaterialStateProperty.all(Colors.transparent),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // Less rounded corners
                            ),
                          ),
                        ),
                        child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(category['image']),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            alignment: Alignment.center,
                            child: Stack(
                              children: [
                                // Border text
                                Text(
                                  category['searchterm'],
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 2
                                      ..color = Colors.black, // Border color
                                  ),
                                ),
                                // Fill text
                                Text(
                                  category['searchterm'],
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.white, // Fill color
                                  ),
                                ),
                              ],
                            ))),
                  );
                }).toList();
              } else {
                buttons = [];
              }

              return Dialog(
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Container(),
                                ),
                                Text(
                                  gifsView == GifsProvider.Giphy
                                      ? 'Giphy Categories'
                                      : gifsView == GifsProvider.Trending
                                          ? 'Giphy Categories'
                                          : "Tenor Categories",
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...buttons,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _loadImage(String url) async {
    final Completer<void> completer = Completer();
    final image = Image.network(url);

    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(exception);
        }
      },
    );

    image.image.resolve(ImageConfiguration()).addListener(listener);

    return completer.future;
  }
}
