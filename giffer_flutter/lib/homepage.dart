import 'package:android_download_manager/android_download_manager.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:core';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:show_network_image/show_network_image.dart';
import 'package:social_share/social_share.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MyHomePage extends StatefulWidget {
  const MyHomePage();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum GifsProvider { Giphy, Tenor }

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> gifsList = [];
  bool isSearch = false;
  TextEditingController searchController = TextEditingController();
  String giphyApiKey = "K1HxaGhOObjpIjOZh0d3mZcsv1pHflei";
  String tenorApiKey = "AIzaSyBKMCcIReVm4_0YpFUnlhuZkRD_aOfrNCc";
  bool isLoading = false;
  GifsProvider gifsView = GifsProvider.Giphy;

  @override
  void initState() {
    super.initState();
    fetchTrandingGifs();
  }

  Future fetchTrandingGifs() async {
    var api =
        "https://api.giphy.com/v1/gifs/trending?api_key=K1HxaGhOObjpIjOZh0d3mZcsv1pHflei&limit=25&offset=0&rating=g&bundle=messaging_non_clips";
    try {
      final response = await http.get(Uri.parse(api));
      if (response.statusCode != 200) {
        throw Exception('Failed to load gifs');
      } else {
        setState(() {
          final data = jsonDecode(response.body);
          gifsList = data['data'];
          isSearch = true;
          print(response.body);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future fetchGifs() async {
    setState(() {
      gifsList = [];
    });

    var searchValue = searchController.text;
    if (gifsView == GifsProvider.Giphy) {
      var api =
          'https://api.giphy.com/v1/gifs/search?api_key=$giphyApiKey&q=$searchValue&limit=&offset=0&rating=g&lang=en&bundle=messaging_non_clips';
      try {
        final response = await http.get(Uri.parse(api));
        if (response.statusCode != 200) {
          throw Exception('Failed to load gifs');
        } else {
          setState(() {
            final data = jsonDecode(response.body);
            gifsList = data['data'];
            isSearch = true;
            print(response.body);
          });
        }
      } catch (e) {
        print(e);
      }
    } else if (gifsView == GifsProvider.Tenor) {
      var api =
          "https://tenor.googleapis.com/v2/search?q=$searchValue&key=$tenorApiKey&client_key=my_test_app&";
      try {
        final response = await http.get(Uri.parse(api));
        print('tenor response : ${response.body}');
        if (response.statusCode != 200) {
          throw Exception('Failed to load gifs');
        } else {
          setState(() {
            final data = jsonDecode(response.body);
            gifsList = data['data'];
            isSearch = true;
          });
          print('tenor response : $gifsList');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  void clearSearch() {
    setState(() {
      isSearch = false;
      gifsList = [];
      searchController.clear();
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
        isLoading = true;
      });
      if (isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing GIF to share...')),
        );
      }
      await Future.delayed(Duration(seconds: 5));

      if (await File(filePath).exists()) {
        setState(() {
          isLoading = false;
        });
        await SocialShare.shareOptions("", imagePath: filePath);
      } else {
        throw Exception("File not found after timeout");
      }
    } catch (e) {
      print('Error sharing GIF: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Giffer"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  left: 10.0, right: 10.0, top: 15.0, bottom: 15.0),
              child: SearchBar(
                controller: searchController,
                backgroundColor:
                    MaterialStateProperty.all(Colors.grey.shade100),
                hintText: "Search gifs...",
                onChanged: (value) {
                  setState(() {});
                },
                trailing: <Widget>[
                  TextButton(
                      onPressed: () => fetchGifs(),
                      child: const Icon(Icons.search)),
                  TextButton(
                      onPressed: () => clearSearch(),
                      child: const Icon(Icons.close)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SegmentedButton<GifsProvider>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: Size(50, 15),
                    backgroundColor: Colors.grey[200],
                    foregroundColor: const Color.fromARGB(255, 54, 98, 244),
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: Colors.green,
                  ),
                  segments: const <ButtonSegment<GifsProvider>>[
                    ButtonSegment<GifsProvider>(
                      value: GifsProvider.Giphy,
                      label: Text('Giphy'),
                    ),
                    ButtonSegment<GifsProvider>(
                      value: GifsProvider.Tenor,
                      label: Text('Tenor'),
                    ),
                  ],
                  selected: <GifsProvider>{gifsView},
                  onSelectionChanged: (Set<GifsProvider> newSelection) {
                    setState(() {
                      // By default there is only a single segment that can be
                      // selected at one time, so its value is always the first
                      // item in the selected set.
                      gifsView = newSelection.first;
                    });
                  }),
            ),
            isSearch
                ? Expanded(
                    child: gifsList.isEmpty
                        ? const Text("No GIFs found")
                        : GridView.builder(
                            padding: const EdgeInsets.all(10.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 10.0,
                            ),
                            itemCount: gifsList.length,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () => onGifTap(gifsList[index]['images']
                                    ['original']['url']),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: ShowNetworkImage(
                                      imageSrc: gifsList[index]['images']
                                          ['original']['url'],
                                      mobileBoxFit: BoxFit.fill,
                                      mobileHeight: 300,
                                      mobileWidth: 300,
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

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }
}
