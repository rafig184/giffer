import 'package:android_download_manager/android_download_manager.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:core';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:msh_checkbox/msh_checkbox.dart';
import 'package:show_network_image/show_network_image.dart';
import 'package:social_share/social_share.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:giffer_flutter/colors.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GifsPage extends StatefulWidget {
  const GifsPage();

  @override
  State<GifsPage> createState() => _GifsPageState();
}

enum GifsProvider { Giphy, Tenor, Trending }

class _GifsPageState extends State<GifsPage> {
  List<dynamic> gifsListGiphy = [];
  List<dynamic> gifsListTenor = [];
  bool isSearch = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          fetchTrandingGifs();
                        } else {
                          fetchGifs();
                        }
                      });
                    }),
              ),
            ),
            isSearch
                ? Expanded(
                    child: isLoadingGifs
                        ? spinkit
                        : gifsListGiphy.isEmpty && gifsListTenor.isEmpty
                            ? const Text("Searching for the right GIF..")
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
                                    onLongPress: () => gifsView ==
                                            GifsProvider.Giphy
                                        ? onLongPress(gifsListGiphy[index]
                                            ['images']['original']['url'])
                                        : gifsView == GifsProvider.Trending
                                            ? onLongPress(gifsListGiphy[index]
                                                ['images']['original']['url'])
                                            : onLongPress(gifsListTenor[index]
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
                                          mobileBoxFit: BoxFit.cover,
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
