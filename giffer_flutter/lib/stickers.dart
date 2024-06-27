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

class StickersPage extends StatefulWidget {
  const StickersPage();

  @override
  State<StickersPage> createState() => _StickersPageState();
}

enum StickerProvider { Tenor, Trending }

class _StickersPageState extends State<StickersPage> {
  List<dynamic> stickerListGiphy = [];
  List<dynamic> stickerListTenor = [];
  bool isSearch = false;
  TextEditingController searchController = TextEditingController();
  String tenorApiKey = "AIzaSyBKMCcIReVm4_0YpFUnlhuZkRD_aOfrNCc";
  String geminiAIKey = "AIzaSyDq-ujx6iqbRrhLJPOSoCMxME30AuWUj_I";
  bool isLoadingSnackBar = false;
  bool isLoadingSticker = false;
  bool isSearchWithAiChecked = false;
  String isAISearchStatus = "off";
  StickerProvider stickerView = StickerProvider.Trending;
  bool isSafeChecked = true;
  String isSafeSearch = "on";
  String ratingTenor = "high";
  String resultAI = "";
  String giphyApi = "";
  String tenorApi = "";

  @override
  void initState() {
    super.initState();
    fetchTrandingStickers();
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
          'give me one best keywords for a sticker based on this prompt : $searchText')
    ];
    final response = await model.generateContent(content);
    print(searchText);
    print(response.text);
    setState(() {
      resultAI = response.text.toString();
    });
  }

  Future fetchTrandingStickers() async {
    var api =
        "https://g.tenor.com/v1/trending?key=LIVDSRZULELA&searchfilter=sticker,static&limit=50";
    var categoriesApi = "https://g.tenor.com/v1/categories?key=LIVDSRZULELA";
    try {
      setState(() {
        isLoadingSticker = true;
      });
      final response = await http.get(Uri.parse(api));
      if (response.statusCode != 200) {
        throw Exception('Failed to load stickers');
      } else {
        setState(() {
          final data = jsonDecode(response.body);
          stickerListTenor = data['results'];
          isSearch = true;
          print(response.body);
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoadingSticker = false;
      });
    }
  }

  Future fetchStickers() async {
    setState(() {
      stickerListGiphy = [];
      stickerListTenor = [];
    });

    var searchValue = searchController.text;

    if (stickerView == StickerProvider.Trending) {
      setState(() {
        stickerView = StickerProvider.Tenor;
      });
    }

    if (stickerView == StickerProvider.Tenor) {
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
              "https://tenor.googleapis.com/v2/search?q=$resultAI&key=$tenorApiKey&limit=100&client_key=my_test_app&contentfilter=$ratingTenor&searchfilter=sticker,static";
        });
      } else {
        setState(() {
          tenorApi =
              "https://tenor.googleapis.com/v2/search?q=$searchValue&key=$tenorApiKey&limit=100&client_key=my_test_app&contentfilter=$ratingTenor&searchfilter=sticker,static";
        });
      }
      print(tenorApi);
      try {
        setState(() {
          isLoadingSticker = true;
        });
        final response = await http.get(Uri.parse(tenorApi));
        if (response.statusCode != 200) {
          throw Exception('Failed to load Stickers');
        } else {
          setState(() {
            final data = jsonDecode(response.body);
            stickerListTenor = data['results'];
            print(response.body);
            isSearch = true;
          });
        }
      } catch (e) {
        print(e);
      } finally {
        setState(() {
          isLoadingSticker = false;
        });
      }
    }
  }

  void clearSearch() {
    fetchTrandingStickers();
    setState(() {
      isSearch = false;
      stickerListGiphy = [];
      stickerListTenor = [];
      searchController.clear();
      stickerView = StickerProvider.Trending;
    });
  }

  Future<void> onStickerTap(strickerURL) async {
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
          downloadUrl: strickerURL,
          downloadPath: directory.path + '/giffer',
          fileName: "test.png",
          notificationVisibility: NotificationVisibility.VISIBILITY_VISIBLE);
      final filePath = '${directory.path}/giffer/test.png';
      setState(() {
        isLoadingSnackBar = true;
      });
      if (isLoadingSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing Sticker to share...')),
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
      print('Error sharing Sticker: $e');
    }
  }

  void onLongPress(sticker) {
    final imageProvider = Image.network(sticker).image;
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

  Future<void> downloadImage(stickerUrl, stickerId) async {
    try {
      AndroidDownloadManager.enqueue(
          downloadUrl: stickerUrl,
          downloadPath: '/storage/emulated/0/Download',
          fileName: "$stickerId.png",
          notificationVisibility: NotificationVisibility.VISIBILITY_VISIBLE);
      setState(() {
        isLoadingSnackBar = true;
      });
      if (isLoadingSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading Sticker...')),
        );
      }
    } catch (error) {
      print(error);
    }
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
                hintText: "Search Stickers...",
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (value) {
                  fetchStickers();
                },
                leading: TextButton(
                    style: ButtonStyle(
                        iconColor: MaterialStateProperty.all(secondaryColor)),
                    onPressed: () => fetchStickers(),
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
                child: SegmentedButton<StickerProvider>(
                    style: SegmentedButton.styleFrom(
                      // maximumSize: const Size(double.infinity, 15),

                      backgroundColor: Colors.grey[200],
                      foregroundColor: secondaryColor,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: secondaryColor,
                    ),
                    segments: const <ButtonSegment<StickerProvider>>[
                      ButtonSegment<StickerProvider>(
                        value: StickerProvider.Trending,
                        label: Text(
                          'Trending',
                          style: TextStyle(height: -1.3),
                        ),
                      ),
                      ButtonSegment<StickerProvider>(
                        value: StickerProvider.Tenor,
                        label: Text(
                          'Tenor',
                          style: TextStyle(height: -1.3),
                        ),
                      ),
                    ],
                    selected: <StickerProvider>{stickerView},
                    onSelectionChanged: (Set<StickerProvider> newSelection) {
                      setState(() {
                        stickerView = newSelection.first;
                        if (stickerView == StickerProvider.Trending) {
                          fetchTrandingStickers();
                        } else {
                          fetchStickers();
                        }
                      });
                    }),
              ),
            ),
            isSearch
                ? Expanded(
                    child: isLoadingSticker
                        ? spinkit
                        : stickerListGiphy.isEmpty && stickerListTenor.isEmpty
                            ? const Text("Searching for the right Sticker..")
                            : GridView.builder(
                                padding: const EdgeInsets.all(10.0),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 10.0,
                                  mainAxisSpacing: 10.0,
                                ),
                                itemCount: stickerListGiphy.isNotEmpty
                                    ? stickerListGiphy.length
                                    : stickerListTenor.length,
                                itemBuilder: (context, index) {
                                  return InkWell(
                                    onTap: () => stickerView ==
                                            StickerProvider.Trending
                                        ? onStickerTap(stickerListTenor[index]
                                            ['media'][0]['gif']['url'])
                                        : onStickerTap(stickerListTenor[index]
                                                ['media_formats']
                                            ['tinygifpreview']['url']),
                                    onLongPress: () => stickerView ==
                                            StickerProvider.Trending
                                        ? onLongPress(stickerListTenor[index]
                                            ['media'][0]['gif']['url'])
                                        : onLongPress(stickerListTenor[index]
                                            ['media_formats']['gif']['url']),
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
                                            ShowNetworkImage(
                                              imageSrc: stickerView ==
                                                      StickerProvider.Trending
                                                  ? stickerListTenor[index]
                                                      ['media'][0]['gif']['url']
                                                  : stickerListTenor[index]
                                                          ['media_formats']
                                                      ['gif']['url'],
                                              mobileBoxFit: BoxFit.cover,
                                              mobileHeight: 300,
                                              mobileWidth: 300,
                                            ),
                                            Positioned(
                                              bottom: 10.0,
                                              right: 10.0,
                                              child: GestureDetector(
                                                onTap: stickerView ==
                                                        StickerProvider.Trending
                                                    ? () => downloadImage(
                                                        stickerListTenor[index]
                                                                ['media'][0]
                                                            ['gif']['url'],
                                                        stickerListTenor[index]
                                                            ['id'])
                                                    : () => downloadImage(
                                                        stickerListTenor[index][
                                                                    'media_formats']
                                                                ['tinygifpreview']
                                                            ['url'],
                                                        stickerListTenor[index]
                                                            ['id']),
                                                child: const Icon(
                                                  Icons.download,
                                                  color: Colors.grey,
                                                  size: 30.0,
                                                ),
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
}
