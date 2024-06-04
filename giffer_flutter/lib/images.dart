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

class ImagesPage extends StatefulWidget {
  const ImagesPage();

  @override
  State<ImagesPage> createState() => _ImagesPageState();
}

enum ImageProvider { Pixabay, Pexels }

class _ImagesPageState extends State<ImagesPage> {
  List<dynamic> imageListPixaBay = [];
  List<dynamic> imageListPexels = [];

  bool isSearch = false;
  TextEditingController searchController = TextEditingController();
  String pixabayKey = "44205117-8bb98a8bc59103bef2a013009";
  String pexelsKey = "kXOUGfQ9o2rjErnylqmOtexVYnFHBChRP095JUoXsttbNOTVMCA9xWoo";
  bool isLoadingSnackBar = false;
  bool isLoadingGifs = false;
  ImageProvider imageView = ImageProvider.Pixabay;
  bool isSafeChecked = true;
  String isSafeSearch = "on";
  bool pixabaySafeSearch = true;
  @override
  void initState() {
    super.initState();
    fetchImages();
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

  Future<void> fetchImages() async {
    setState(() {
      imageListPixaBay = [];
    });

    var searchValue = searchController.text;

    if (imageView == ImageProvider.Pixabay) {
      if (!isSafeChecked) {
        setState(() {
          pixabaySafeSearch = false;
        });
      } else {
        setState(() {
          pixabaySafeSearch = true;
        });
      }
      var api =
          "https://pixabay.com/api/?key=$pixabayKey&q=$searchValue&per_page=200&image_type=photo&pretty=true&safesearch=$pixabaySafeSearch";

      try {
        setState(() {
          isLoadingGifs = true;
        });
        final response = await http.get(Uri.parse(api));
        if (response.statusCode != 200) {
          throw Exception('Failed to load Images');
        } else {
          setState(() {
            final data = jsonDecode(response.body);
            imageListPixaBay = data['hits'];
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
      print(imageListPixaBay);
    } else if (imageView == ImageProvider.Pexels) {
      var api =
          "https://api.pexels.com/v1/search?query=$searchValue&per_page=100";
      try {
        setState(() {
          isLoadingGifs = true;
        });
        final response = await http.get(
          Uri.parse(api),
          headers: {
            HttpHeaders.authorizationHeader: pexelsKey,
          },
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to load Images');
        } else {
          setState(() {
            final data = jsonDecode(response.body);
            print(data);
            imageListPexels = data['photos'];
            isSearch = true;
          });
        }
        print(imageListPexels);
      } catch (e) {
        print(e);
      } finally {
        setState(() {
          isLoadingGifs = false;
        });
      }
    }
  }

  void onLongPress(image) {
    final imageProvider = Image.network(image).image;
    showImageViewer(context, imageProvider, onViewerDismissed: () {});
  }

  void clearSearch() {
    setState(() {
      isSearch = false;
      imageListPixaBay = [];
      imageListPexels = [];
      searchController.clear();
      fetchImages();
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
          const SnackBar(content: Text('Downloading image...')),
        );
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> onImageTap(imageUrl) async {
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
          const SnackBar(content: Text('Preparing image to share...')),
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
                hintText: "Search images...",
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (value) {
                  fetchImages();
                },
                trailing: <Widget>[
                  TextButton(
                      onPressed: () => fetchImages(),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                height: 30,
                child: SegmentedButton<ImageProvider>(
                    style: SegmentedButton.styleFrom(
                      // maximumSize: const Size(double.infinity, 15),

                      backgroundColor: Colors.grey[200],
                      foregroundColor: secondaryColor,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: secondaryColor,
                    ),
                    segments: const <ButtonSegment<ImageProvider>>[
                      ButtonSegment<ImageProvider>(
                        value: ImageProvider.Pixabay,
                        label: Text(
                          'Pixabay',
                          style: TextStyle(height: -1.3),
                        ),
                      ),
                      ButtonSegment<ImageProvider>(
                        value: ImageProvider.Pexels,
                        label: Text(
                          'Pexels',
                          style: TextStyle(height: -1.3),
                        ),
                      ),
                    ],
                    selected: <ImageProvider>{imageView},
                    onSelectionChanged: (Set<ImageProvider> newSelection) {
                      setState(() {
                        imageView = newSelection.first;
                        fetchImages();
                      });
                    }),
              ),
            ),
            isSearch
                ? Expanded(
                    child: isLoadingGifs
                        ? spinkit
                        : imageListPixaBay.isEmpty && imageListPexels.isEmpty
                            ? const Text("No images found")
                            : GridView.builder(
                                padding: const EdgeInsets.all(10.0),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 10.0,
                                  mainAxisSpacing: 10.0,
                                ),
                                itemCount: imageView == ImageProvider.Pixabay
                                    ? imageListPixaBay.length
                                    : imageListPexels.length,
                                itemBuilder: (context, index) {
                                  final image = imageView ==
                                          ImageProvider.Pixabay
                                      ? imageListPixaBay[index]['webformatURL']
                                      : imageListPexels[index]['src']['medium'];

                                  return InkWell(
                                    onTap: () =>
                                        imageView == ImageProvider.Pixabay
                                            ? onImageTap(imageListPixaBay[index]
                                                ['largeImageURL'])
                                            : onImageTap(imageListPexels[index]
                                                ['src']['original']),
                                    onLongPress: () => imageView ==
                                            ImageProvider.Pixabay
                                        ? onLongPress(imageListPixaBay[index]
                                            ['webformatURL'])
                                        : onLongPress(imageListPexels[index]
                                            ['src']['large2x']),
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
                                                  imageView ==
                                                          ImageProvider.Pixabay
                                                      ? imageListPixaBay[index]
                                                          ['largeImageURL']
                                                      : imageListPexels[index]
                                                          ['src']['original'],
                                                  imageView ==
                                                          ImageProvider.Pixabay
                                                      ? imageListPixaBay[index]
                                                          ['id']
                                                      : imageListPexels[index]
                                                          ['id'],
                                                ),
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
