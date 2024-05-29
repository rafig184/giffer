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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:giffer_flutter/colors.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum GifsProvider { Giphy, Tenor, Trending }

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> gifsListGiphy = [];
  List<dynamic> gifsListTenor = [];
  bool isSearch = false;
  TextEditingController searchController = TextEditingController();
  String giphyApiKey = "K1HxaGhOObjpIjOZh0d3mZcsv1pHflei";
  String tenorApiKey = "AIzaSyBKMCcIReVm4_0YpFUnlhuZkRD_aOfrNCc";
  bool isLoadingSnackBar = false;
  bool isLoadingGifs = false;
  GifsProvider gifsView = GifsProvider.Trending;

  @override
  void initState() {
    super.initState();
    fetchTrandingGifs();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  final spinkit = const SpinKitFadingCircle(
    color: primaryColor,
    size: 80.0,
  );

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
    setState(() {
      gifsListGiphy = [];
      gifsListTenor = [];
    });

    var searchValue = searchController.text;
    if (gifsView == GifsProvider.Giphy) {
      var api =
          'https://api.giphy.com/v1/gifs/search?api_key=$giphyApiKey&q=$searchValue&limit=&offset=0&rating=g&lang=en&bundle=messaging_non_clips';
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
    } else if (gifsView == GifsProvider.Tenor) {
      var api =
          "https://tenor.googleapis.com/v2/search?q=$searchValue&key=$tenorApiKey&client_key=my_test_app&";
      try {
        setState(() {
          isLoadingGifs = true;
        });
        final response = await http.get(Uri.parse(api));
        print('tenor response : ${response.body}');
        if (response.statusCode != 200) {
          throw Exception('Failed to load gifs');
        } else {
          setState(() {
            final data = jsonDecode(response.body);
            print('data : $data');
            gifsListTenor = data['results'];
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
    print('tenor response ===> : ${gifsListTenor}');
  }

  void clearSearch() {
    fetchTrandingGifs();
    setState(() {
      isSearch = false;
      gifsListGiphy = [];
      gifsListTenor = [];
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
        toolbarHeight: 70,
        backgroundColor: primaryColor,
        title: Center(
          child: Image.asset(
            'assets/logo.png',
            height: 40,
          ),
        ),
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
                onSubmitted: (value) {
                  fetchGifs();
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
                    foregroundColor: secondaryColor,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: secondaryColor,
                  ),
                  segments: const <ButtonSegment<GifsProvider>>[
                    ButtonSegment<GifsProvider>(
                      value: GifsProvider.Giphy,
                      label: Text('Giphy'),
                    ),
                    ButtonSegment<GifsProvider>(
                      value: GifsProvider.Trending,
                      label: Text('Trending'),
                    ),
                    ButtonSegment<GifsProvider>(
                      value: GifsProvider.Tenor,
                      label: Text('Tenor'),
                    ),
                  ],
                  selected: <GifsProvider>{gifsView},
                  onSelectionChanged: (Set<GifsProvider> newSelection) {
                    setState(() {
                      gifsView = newSelection.first;
                      if (gifsView == GifsProvider.Trending) {
                        fetchTrandingGifs();
                      } else {
                        fetchGifs();
                      }
                    });
                  }),
            ),
            isSearch
                ? Expanded(
                    child: isLoadingGifs
                        ? spinkit
                        : gifsListGiphy.isEmpty && gifsListTenor.isEmpty
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
                                itemCount: gifsListGiphy.isNotEmpty
                                    ? gifsListGiphy.length
                                    : gifsListTenor.length,
                                itemBuilder: (context, index) {
                                  return InkWell(
                                    onTap: () => gifsView == GifsProvider.Giphy
                                        ? onGifTap(gifsListGiphy[index]
                                            ['images']['original']['url'])
                                        : gifsView == GifsProvider.Trending
                                            ? onGifTap(gifsListGiphy[index]
                                                ['images']['original']['url'])
                                            : onGifTap(gifsListTenor[index]
                                                    ['media_formats']['gif']
                                                ['url']),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        child: ShowNetworkImage(
                                          imageSrc: gifsView ==
                                                  GifsProvider.Giphy
                                              ? gifsListGiphy[index]['images']
                                                  ['original']['url']
                                              : gifsView ==
                                                      GifsProvider.Trending
                                                  ? gifsListGiphy[index]
                                                          ['images']['original']
                                                      ['url']
                                                  : gifsListTenor[index]
                                                          ['media_formats']
                                                      ['gif']['url'],
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
}
