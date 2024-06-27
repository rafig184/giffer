import 'package:android_download_manager/android_download_manager.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;

class MemesPage extends StatefulWidget {
  const MemesPage();

  @override
  State<MemesPage> createState() => _MemesPageState();
}

class _MemesPageState extends State<MemesPage> {
  List<dynamic> memesList = [];
  List<dynamic> filteredMemes = [];

  bool isSearch = false;
  TextEditingController searchController = TextEditingController();
  TextEditingController topTextController = TextEditingController();
  TextEditingController bottomTextController = TextEditingController();
  bool isLoadingSnackBar = false;
  bool isLoadingMemes = false;
  bool isLoadingMemesPreview = false;
  bool isMemeSave = false;
  bool isMemeShare = false;
  String memeUrl = "";
  bool isPreviewMeme = false;
  bool isSelectPreview = false;
  String previewMeme = "";

  @override
  void initState() {
    super.initState();
    fetchTopMemes();
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
    topTextController.dispose();
    bottomTextController.dispose();
  }

  final spinkit = const SpinKitFadingCircle(
    color: primaryColor,
    size: 80.0,
  );

  Future<void> fetchTopMemes() async {
    setState(() {
      memesList = [];
    });

    var api = "https://api.imgflip.com/get_memes";
    try {
      setState(() {
        isLoadingMemes = true;
      });
      final response = await http.get(Uri.parse(api));
      print(response.body);
      if (response.statusCode != 200) {
        throw Exception('Failed to load Memes');
      } else {
        setState(() {
          final data = jsonDecode(response.body);
          memesList = data['data']['memes'];
          filteredMemes = memesList;
          isSearch = true;
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoadingMemes = false;
      });
    }
    print(memesList);
  }

  Future<void> createMeme(String topText, String bottomText, id) async {
    await langdetect.initLangDetect();

    if (topText.isNotEmpty) {
      final languageTop = langdetect.detect(topText);
      print('Detected language (top): $languageTop');
      if (languageTop == "he") {
        topText = topText.split('').reversed.join('');
      }
    }

    if (bottomText.isNotEmpty) {
      final languageBottom = langdetect.detect(bottomText);
      print('Detected language (bottom): $languageBottom');
      if (languageBottom == "he") {
        bottomText = bottomText.split('').reversed.join('');
      }
    }

    var url = "https://api.imgflip.com/caption_image";
    var params = {
      "template_id": id.toString(),
      "username": "rafiganon",
      "password": "Rg1841989!",
      "text0": topText,
      "text1": bottomText
    };

    try {
      setState(() {
        isLoadingMemesPreview = true;
        // isPreviewMeme = false;
      });
      final response = await http.post(
        Uri.parse(url),
        body: params,
      );
      print(response);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print(result);

        var memeUrl = result['data']['url'];
        print(memeUrl);
        setState(() {
          previewMeme = memeUrl;
        });

        if (isMemeSave) {
          downloadImage(previewMeme, id);
        } else if (isMemeShare) {
          memeShare(previewMeme);
        }

        setState(() {
          isMemeSave = false;
          isMemeShare = false;
        });
      } else {
        throw Exception('Failed to create meme');
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoadingMemesPreview = false;
      });
    }
  }

  Future<void> searchMemes() async {
    var searchValue = searchController.text;
    setState(() {
      filteredMemes = memesList
          .where((meme) =>
              meme['name'].toLowerCase().contains(searchValue.toLowerCase()))
          .toList();
    });
  }

  void onLongPress(image) {
    final imageProvider = Image.network(image).image;
    showImageViewer(context, imageProvider, onViewerDismissed: () {});
  }

  void clearSearch() {
    setState(() {
      isSearch = false;
      memesList = [];
      searchController.clear();
      fetchTopMemes();
    });
  }

  Future<void> downloadImage(imageUrl, imageID) async {
    try {
      AndroidDownloadManager.enqueue(
          downloadUrl: imageUrl,
          downloadPath: '/storage/emulated/0/Download',
          fileName: "$imageID.jpg",
          notificationVisibility: NotificationVisibility.VISIBILITY_VISIBLE);
      setState(() {
        isLoadingSnackBar = true;
      });
      if (isLoadingSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading Meme...')),
        );
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> memeShare(imageUrl) async {
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
          downloadUrl: imageUrl,
          downloadPath: '${directory.path}/giffer',
          fileName: "test.jpg",
          notificationVisibility: NotificationVisibility.VISIBILITY_VISIBLE);
      final filePath = '${directory.path}/giffer/test.jpg';
      setState(() {
        isLoadingSnackBar = true;
      });
      if (isLoadingSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing meme to share...')),
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
      print('Error sharing image: $e');
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

  Future<void> onMemeTapDialog(imageUrl, id, name) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                                child: Text(
                              name,
                              style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 15.0,
                                  // fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700),
                            )),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  topTextController.clear();
                                  bottomTextController.clear();
                                  setState(() {
                                    previewMeme = "";
                                  });
                                  // isPreviewMeme = false;
                                },
                                child: const Icon(Icons.close)),
                          ],
                        ),
                        // const SizedBox(height: 10),
                        TextField(
                          controller: topTextController,
                          decoration: const InputDecoration(
                            hintText: "Enter Top Text...",
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        TextField(
                          controller: bottomTextController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            hintText: "Enter Bottom Text...",
                          ),
                        ),

                        const SizedBox(height: 15),
                        isLoadingMemesPreview
                            ? spinkit
                            : Image.network(
                                previewMeme.isEmpty ? imageUrl : previewMeme,
                                fit: BoxFit.cover,
                              ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            secondaryColor)),
                                onPressed: () async {
                                  await createMeme(topTextController.text,
                                      bottomTextController.text, id);
                                  setState(() {});
                                },
                                child: const Text(
                                  "Preview",
                                  style: TextStyle(color: Colors.white),
                                )),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            secondaryColor)),
                                onPressed: () async {
                                  setState(() {
                                    isMemeSave = true;
                                  });
                                  await createMeme(topTextController.text,
                                      bottomTextController.text, id);

                                  Navigator.of(context).pop();
                                  topTextController.clear();
                                  bottomTextController.clear();
                                  setState(() {
                                    previewMeme = "";
                                  });
                                },
                                child: const Icon(
                                  Icons.save_alt,
                                  color: Colors.white,
                                )),
                            ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          secondaryColor)),
                              onPressed: () async {
                                setState(() {
                                  isMemeShare = true;
                                });
                                await createMeme(topTextController.text,
                                    bottomTextController.text, id);

                                Navigator.of(context).pop();
                                topTextController.clear();
                                bottomTextController.clear();
                                setState(() {
                                  previewMeme = "";
                                });
                              },
                              child: const Icon(
                                Icons.share,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
                hintText: "Search Memes...",
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (value) {
                  searchMemes();
                },
                leading: TextButton(
                    style: ButtonStyle(
                        iconColor: MaterialStateProperty.all(secondaryColor)),
                    onPressed: () => searchMemes(),
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
            isSearch
                ? Expanded(
                    child: isLoadingMemes
                        ? spinkit
                        : filteredMemes.isEmpty
                            ? const Text("No memes found")
                            : GridView.builder(
                                padding: const EdgeInsets.all(10.0),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 10.0,
                                  mainAxisSpacing: 10.0,
                                ),
                                itemCount: filteredMemes.length,
                                itemBuilder: (context, index) {
                                  final image = filteredMemes[index]['url'];

                                  return InkWell(
                                    onTap: () => onMemeTapDialog(
                                        filteredMemes[index]['url'],
                                        filteredMemes[index]['id'],
                                        filteredMemes[index]['name']),
                                    onLongPress: () => onLongPress(
                                        filteredMemes[index]['url']),
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
                                              imageSrc: image,
                                              mobileBoxFit: BoxFit.cover,
                                              mobileHeight: 300,
                                              mobileWidth: 300,
                                            ),
                                            Positioned(
                                              bottom: 10.0,
                                              right: 10.0,
                                              child: GestureDetector(
                                                onTap: () => downloadImage(
                                                    filteredMemes[index]['url'],
                                                    filteredMemes[index]['id']),
                                                child: const Icon(
                                                  Icons.download,
                                                  color: Colors.white,
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
