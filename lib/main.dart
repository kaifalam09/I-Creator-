import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ICreatorApp());
}


// ============================================================
// USER SESSION
// ============================================================

class UserSession {
  static bool isLoggedIn = false;
  static String channelName = 'Guest User';
  static String email = '';
}

// ============================================================
// VIDEO MODEL
// ============================================================

class VideoModel {
  final String? id;
  final String title;
  final String channel;
  final String type;
  final int viewCount;
  final String? networkUrl;
  final String? filePath;
  final String description;
final String description;
  final int likeCount;      // ADD THIS
  final int dislikeCount;   // ADD THIS
  const VideoModel({
    this.id,
    required this.title,
    required this.channel,
    required this.type,
    this.viewCount = 0,
    this.networkUrl,
    this.filePath,
    this.description = '',
  });

  String get views {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$viewCount views';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'channel': channel,
      'type': type,
      'viewCount': viewCount,
      'networkUrl': networkUrl,
      'description': description,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map, String docId) {
    return VideoModel(
      id: docId,
      title: map['title'] ?? '',
      channel: map['channel'] ?? '',
      type: map['type'] ?? 'long',
      viewCount: map['viewCount'] ?? 0,
      networkUrl: map['networkUrl'],
      description: map['description'] ?? '',
    );
  }
}

Future<void> incrementViewCount(String videoId) async {
  await FirebaseFirestore.instance
      .collection('videos')
      .doc(videoId)
      .update({'viewCount': FieldValue.increment(1)});
}

// ============================================================
// VIDEO DATABASE
// ============================================================

final List<VideoModel> globalVideos = [
  const VideoModel(
    title: 'Welcome to I-Creator: Ultimate Platform Tour',
    channel: 'I-Creator Official',
    type: 'long',
    viewCount: 1400000,
    networkUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  ),
  const VideoModel(
    title: 'Top Speed Drift Highlights #Shorts',
    channel: 'SpeedRunner',
    type: 'reel',
    viewCount: 850000,
    networkUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  ),
];

// ============================================================
// APP
// ============================================================

class ICreatorApp extends StatelessWidget {
  const ICreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
        ),
        bottomNavigationBarTheme:
            const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F0F0F),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme:
            const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1E1E1E),
          border: OutlineInputBorder(),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ============================================================
// MAIN SCREEN
// ============================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() =>
      _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      UserSession.isLoggedIn = true;
      UserSession.email = currentUser.email ?? '';
      UserSession.channelName = currentUser.displayName ?? 'My Channel';
    }
  }
  // ==========================================================
  // CREATE MENU
  // ==========================================================

  void showCreateMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),

              // SHORT
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF333333),
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Create a Short',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Share a vertical video',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  pickVideo('reel');
                },
              ),

              // VIDEO
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF333333),
                  child: Icon(
                    Icons.video_library,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Upload a video',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Select a video from your phone',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  pickVideo('long');
                },
              ),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // PICK VIDEO
  // ==========================================================

  Future<void> pickVideo(String type) async {
    if (!UserSession.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please sign in first to upload videos.',
          ),
          action: SnackBarAction(
            label: 'SIGN IN',
            onPressed: () {
              setState(() {
                currentIndex = 4;
              });
            },
          ),
        ),
      );
      return;
    }

    try {
      final XFile? file =
          await picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (file == null || !mounted) {
        return;
      }

      showVideoDetails(
        file.path,
        type,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video select failed: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // UPLOAD TO CLOUDINARY
  // ==========================================================

  Future<String?> uploadToCloudinary(String filePath) async {
    const cloudName = 's88mxyon';
    const uploadPreset = 'ml_default';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);
      return data['secure_url'];
    } else {
      return null;
    }
  }

  // ==========================================================
  // VIDEO DETAILS
  // ==========================================================
  void showVideoDetails(
    String filePath,
    String type,
  ) {
    final TextEditingController titleController =
        TextEditingController();
final TextEditingController descriptionController =
    TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom +
                    20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                type == 'reel'
                    ? 'Add details to Short'
                    : 'Add details to Video',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: titleController,
                textInputAction:
                    TextInputAction.done,
                decoration:
                    const InputDecoration(
                  labelText: 'Video title',
                  hintText: 'Enter a title',
                ),
              ),
const SizedBox(height: 15),

TextField(
  controller: descriptionController,
  maxLines: 4,
  textInputAction: TextInputAction.done,
  decoration: const InputDecoration(
    labelText: 'Description',
    hintText: 'Tell viewers about your video',
  ),
),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.redAccent,
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed: () async {
                    final title =
                        titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a title.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Uploading video, please wait...',
                        ),
                      ),
                    );

                    final uploadedUrl =
                        await uploadToCloudinary(filePath);

                    if (uploadedUrl == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Upload failed. Please try again.',
                          ),
                        ),
                      );
                      return;
                    }

                    final newVideo = VideoModel(
  title: title,
  channel: UserSession.channelName,
  type: type,
  networkUrl: uploadedUrl,
  description: descriptionController.text.trim(),
);

final docRef = await FirebaseFirestore.instance
    .collection('videos')
    .add(newVideo.toMap());

final savedVideo = VideoModel(
  id: docRef.id,
  title: title,
  channel: UserSession.channelName,
  type: type,
  networkUrl: uploadedUrl,
  description: descriptionController.text.trim(),
);

setState(() {
  globalVideos.insert(0, savedVideo);
});

                    if (!mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Video published successfully!',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Publish Video',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      ReelsScreen(key: UniqueKey()),
      const SizedBox.shrink(),
      const SubscriptionsScreen(),
      ProfileScreen(
        onStateChanged: () {
          setState(() {});
        },
      ),
    ];

    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          if (index == 2) {
            showCreateMenu();
            return;
          }

          setState(() {
            currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.play_circle_outline,
            ),
            label: 'Shorts',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle,
              size: 36,
              color: Colors.white,
            ),
            label: '',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.subscriptions_outlined,
            ),
            label: 'Subscriptions',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_circle_outlined,
            ),
            label: 'You',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    loadVideosFromFirestore();
  }

  Future<void> loadVideosFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('videos')
          .get();

      final loadedVideos = snapshot.docs
          .map((doc) => VideoModel.fromMap(
                doc.data(),
                doc.id,
              ))
          .toList();

      if (mounted) {
        setState(() {
          for (final video in loadedVideos.reversed) {
            final alreadyExists = globalVideos.any(
              (v) => v.title == video.title && v.networkUrl == video.networkUrl,
            );
            if (!alreadyExists) {
              globalVideos.insert(0, video);
            }
          }
        });
      }
    } catch (_) {
      // silently ignore for now
    }
  }

  @override
  Widget build(BuildContext context) {
    final videos = globalVideos
        .where(
          (video) => video.type == 'long',
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: Colors.redAccent,
              size: 32,
            ),

            SizedBox(width: 5),

            Text(
              'I-Creator',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.cast),
            onPressed: () {},
          ),

          IconButton(
            icon: const Icon(
              Icons.notifications_none,
            ),
            onPressed: () {},
          ),

          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),

      body: videos.isEmpty
          ? const Center(
              child: Text(
                'No videos available',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              itemCount: videos.length + 1,
              itemBuilder: (context, index) {
                if (index == 2) {
                  return _buildShortsRow(context);
                }

                final videoIndex = index > 2 ? index - 1 : index;

                if (videoIndex >= videos.length) {
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VideoPlayerScreen(video: videos[videoIndex]),
                      ),
                    );
                  },
                  child: VideoCard(
                    video: videos[videoIndex],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildShortsRow(BuildContext context) {
    final shorts =
        globalVideos.where((v) => v.type == 'reel').toList();

    if (shorts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.play_circle_fill_rounded,
                    color: Colors.redAccent, size: 22),
                SizedBox(width: 6),
                Text(
                  'Shorts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: shorts.length > 5 ? 5 : shorts.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReelsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                        Positioned(
                          left: 6,
                          right: 6,
                          bottom: 6,
                          child: Text(
                            shorts[index].title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
      

// ============================================================
// VIDEO CARD
// ============================================================
class VideoCard extends StatefulWidget {
  final VideoModel video;

  const VideoCard({
    super.key,
    required this.video,
  });

  @override
  State<VideoCard> createState() =>
      _VideoCardState();
}

class _VideoCardState
    extends State<VideoCard> {
  VideoPlayerController? controller;

  String? error;

  @override
  void initState() {
    super.initState();

    initializeVideo();
  }

  Future<void> initializeVideo() async {
    try {
      if (widget.video.filePath != null) {
        controller =
            VideoPlayerController.file(
          File(
            widget.video.filePath!,
          ),
        );
      } else if (
          widget.video.networkUrl != null) {
        controller =
            VideoPlayerController.networkUrl(
          Uri.parse(
            widget.video.networkUrl!,
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            error =
                'Video source unavailable';
          });
        }

        return;
      }

      await controller!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error =
              'Unable to load video';
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget player;

    if (error != null) {
      player = Center(
        child: Text(
          error!,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    } else if (
        controller != null &&
        controller!.value.isInitialized
    ) {
      player = FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width:
              controller!.value.size.width,
          height:
              controller!.value.size.height,
          child: VideoPlayer(
            controller!,
          ),
        ),
      );
    } else {
      player = const Center(
        child: CircularProgressIndicator(
          color: Colors.redAccent,
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: player,
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.all(12),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChannelScreen(
                        channelName: widget.video.channel,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundColor:
                      Colors.redAccent,

                  child: Text(
                    widget.video.channel
                            .isNotEmpty
                        ? widget.video.channel[0]
                            .toUpperCase()
                        : 'U',

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${widget.video.channel} • ${widget.video.views}',

                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.more_vert,
                color: Colors.grey,
              ),
            ],
          ),
        ),

        const SizedBox(height: 5),
      ],
    );
  }
}
                
    

// ============================================================
// SHORTS
// ============================================================

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reels = globalVideos
        .where((video) => video.type == 'reel')
        .toList();

    if (reels.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No Shorts available',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          return ShortVideo(
            video: reels[index],
          );
        },
      ),
    );
  }
}
// ============================================================
// SHORT VIDEO (used inside ReelsScreen)
// ============================================================

class ShortVideo extends StatefulWidget {
  final VideoModel video;

  const ShortVideo({super.key, required this.video});

  @override
  State<ShortVideo> createState() => _ShortVideoState();
}

class _ShortVideoState extends State<ShortVideo> {
  VideoPlayerController? controller;
  String? error;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  Future<void> initializeVideo() async {
    try {
      if (widget.video.filePath != null) {
        controller = VideoPlayerController.file(
          File(widget.video.filePath!),
        );
      } else if (widget.video.networkUrl != null) {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.networkUrl!),
        );
      } else {
        if (mounted) {
          setState(() {
            error = 'Video source unavailable';
          });
        }
        return;
      }

      await controller!.initialize();
      controller!.setLooping(true);
      controller!.play();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Unable to load video';
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget player;

    if (error != null) {
      player = Center(
        child: Text(
          error!,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    } else if (controller != null && controller!.value.isInitialized) {
      player = FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller!.value.size.width,
          height: controller!.value.size.height,
          child: VideoPlayer(controller!),
        ),
      );
    } else {
      player = const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      );
    }

    return GestureDetector(
      onTap: () {
        if (controller == null || !controller!.value.isInitialized) return;
        setState(() {
          controller!.value.isPlaying
              ? controller!.pause()
              : controller!.play();
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black, child: player),
          Positioned(
            left: 16,
            right: 70,
            bottom: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.channel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUBSCRIPTIONS SCREEN
// ============================================================

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subscriptions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text(
          'No subscriptions yet',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

     // ============================================================
// PROFILE SCREEN (Google Sign-In)
// ============================================================
class ProfileScreen extends StatefulWidget {
  final VoidCallback onStateChanged;

  const ProfileScreen({super.key, required this.onStateChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  bool isLoading = false;

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      String finalChannelName = user?.displayName ?? 'My Channel';

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['channelName'] != null) {
          finalChannelName = doc.data()!['channelName'];
        }
      }

      setState(() {
        UserSession.isLoggedIn = true;
        UserSession.email = user?.email ?? '';
        UserSession.channelName = finalChannelName;
        isLoading = false;
      });

      widget.onStateChanged();
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    }
  }

  Future<void> signOut() async {
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();

    setState(() {
      UserSession.isLoggedIn = false;
      UserSession.email = '';
      UserSession.channelName = 'Guest User';
    });

    widget.onStateChanged();
  }
Future<void> editChannelName() async {
    final controller = TextEditingController(text: UserSession.channelName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Edit channel name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter channel name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'channelName': newName,
    });

    setState(() {
      UserSession.channelName = newName;
    });

    widget.onStateChanged();
}
  Widget _buildMyVideosGrid() {
    final myVideos = globalVideos
        .where((v) => v.channel == UserSession.channelName)
        .toList();

    if (myVideos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No videos uploaded yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: myVideos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 16 / 12,
      ),
      itemBuilder: (context, index) {
        final video = myVideos[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(video: video),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'You',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: UserSession.isLoggedIn
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.shade700,
                            Colors.redAccent.shade200,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -35),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 37,
                              backgroundColor: Colors.redAccent,
                              child: Text(
                                UserSession.channelName.isNotEmpty
                                    ? UserSession.channelName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                UserSession.channelName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: editChannelName,
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            UserSession.email,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '0 subscribers',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                              ),
                              onPressed: signOut,
                              child: const Text('Sign out'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text(
                            'My Videos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMyVideosGrid(),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.redAccent,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sign in to I-Creator',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: signInWithGoogle,
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              label: const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}
        
            
// ============================================================
// FULL VIDEO PLAYER SCREEN
// ============================================================

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? controller;
  String? error;
  
bool _showFullDescription = false; // NEW
final TextEditingController _commentController = TextEditingController(); // NEW
  @override
  void initState() {
    super.initState();
    initializeVideo();

    if (widget.video.id != null) {
      incrementViewCount(widget.video.id!);
    }
  }

  Future<void> initializeVideo() async {
    try {
      if (widget.video.filePath != null) {
        controller = VideoPlayerController.file(File(widget.video.filePath!));
      } else if (widget.video.networkUrl != null) {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.networkUrl!),
        );
      } else {
        setState(() {
          error = 'Video source unavailable';
        });
        return;
      }

      await controller!.initialize();
      controller!.play();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Unable to load video';
        });
      }
    }
  }
Future<void> _postComment() async {
  final text = _commentController.text.trim();
  if (text.isEmpty) return;

  if (!UserSession.isLoggedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to comment')),
    );
    return;
  }

  if (widget.video.id == null) return;

  await FirebaseFirestore.instance.collection('comments').add({
    'videoId': widget.video.id,
    'username': UserSession.channelName,
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
  });
if (!mounted) return; // NEW
  _commentController.clear();
  FocusScope.of(context).unfocus();
}

String _formatCommentTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

@override
void dispose() {
  controller?.dispose();
  _commentController.dispose(); // NEW
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Center(
                child: error != null
                    ? Text(error!, style: const TextStyle(color: Colors.grey))
                    : controller != null && controller!.value.isInitialized
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                controller!.value.isPlaying
                                    ? controller!.pause()
                                    : controller!.play();
                              });
                            },
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: controller!.value.size.width,
                                height: controller!.value.size.height,
                                child: VideoPlayer(controller!),
                              ),
                            ),
                          )
                        : const CircularProgressIndicator(color: Colors.redAccent),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.video.views,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    // ---------- NEW: DESCRIPTION BLOCK ----------
                    if (widget.video.description.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showFullDescription = !_showFullDescription;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.video.description,
                                maxLines: _showFullDescription ? null : 2,
                                overflow: _showFullDescription
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _showFullDescription ? 'Show less' : 'Show more',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // ---------- END DESCRIPTION BLOCK ----------

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChannelScreen(
                              channelName: widget.video.channel,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Text(
                              widget.video.channel.isNotEmpty
                                  ? widget.video.channel[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                      widget.video.channel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.grey),
              const SizedBox(height: 12),

// ---------- COMMENT SECTION ----------
Row(
  children: [
    CircleAvatar(
      radius: 16,
      backgroundColor: Colors.redAccent,
      child: Text(
        UserSession.channelName.isNotEmpty
            ? UserSession.channelName[0].toUpperCase()
            : 'U',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: TextField(
        controller: _commentController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Add a comment...',
          hintStyle: TextStyle(color: Colors.grey),
          border: UnderlineInputBorder(),
        ),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.send, color: Colors.redAccent, size: 20),
      onPressed: _postComment,
    ),
  ],
),
const SizedBox(height: 16),

StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('comments')
      .where('videoId', isEqualTo: widget.video.id)
      .orderBy('timestamp', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    }
if (snapshot.hasError) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      'Error: ${snapshot.error}',
      style: const TextStyle(color: Colors.red, fontSize: 12),
    ),
  );
}
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No comments yet. Be the first!',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    final comments = snapshot.data!.docs;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final data = comments[index].data() as Map<String, dynamic>;
        final username = data['username'] ?? 'User';
        final text = data['text'] ?? '';
        final timestamp = data['timestamp'] as Timestamp?;
        final timeText =
            timestamp != null ? _formatCommentTime(timestamp.toDate()) : '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.grey[800],
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeText,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text,
                      style: const TextStyle(fontSize: 13.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  },
),
// ---------- END COMMENT SECTION ----------
                        ],
                      ),
                    ),
                  
                ),
              ),
            
          
        ],
      ),
    );
  }
}
      
                   
// ============================================================
// CHANNEL SCREEN (View any creator's channel)
// ============================================================

class ChannelScreen extends StatefulWidget {
  final String channelName;

  const ChannelScreen({super.key, required this.channelName});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  bool isSubscribed = false;
  int subscriberCount = 0;
  bool isLoading = true;

  String get subDocId {
    final user = FirebaseAuth.instance.currentUser;
    return '${user?.uid}_${widget.channelName}';
  }

  @override
  void initState() {
    super.initState();
    loadSubscriptionData();
  }

  Future<void> loadSubscriptionData() async {
    final user = FirebaseAuth.instance.currentUser;

    final countSnapshot = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('channelName', isEqualTo: widget.channelName)
        .get();

    bool subscribed = false;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(subDocId)
          .get();
      subscribed = doc.exists;
    }

    if (mounted) {
      setState(() {
        subscriberCount = countSnapshot.docs.length;
        isSubscribed = subscribed;
        isLoading = false;
      });
    }
  }

  Future<void> toggleSubscribe() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to subscribe.')),
      );
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('subscriptions')
        .doc(subDocId);

    if (isSubscribed) {
      await ref.delete();
      setState(() {
        isSubscribed = false;
        subscriberCount -= 1;
      });
    } else {
      await ref.set({
        'userId': user.uid,
        'channelName': widget.channelName,
      });
      setState(() {
        isSubscribed = true;
        subscriberCount += 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelVideos = globalVideos
        .where((v) => v.channel == widget.channelName)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.shade700,
                    Colors.redAccent.shade200,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.redAccent,
                    child: Text(
                      widget.channelName.isNotEmpty
                          ? widget.channelName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.channelName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLoading
                              ? 'Loading...'
                              : '$subscriberCount subscribers',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSubscribed
                          ? const Color(0xFF333333)
                          : Colors.redAccent,
                    ),
                    onPressed: isLoading ? null : toggleSubscribe,
                    child: Text(isSubscribed ? 'Subscribed' : 'Subscribe'),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Videos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (channelVideos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No videos yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: channelVideos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VideoPlayerScreen(video: channelVideos[index]),
                        ),
                      );
                    },
                    child: VideoCard(video: channelVideos[index]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
