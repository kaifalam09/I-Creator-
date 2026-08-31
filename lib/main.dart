import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  final String title;
  final String channel;
  final String type;
  final String views;
  final String? networkUrl;
  final String? filePath;

  const VideoModel({
    required this.title,
    required this.channel,
    required this.type,
    required this.views,
    this.networkUrl,
    this.filePath,
  });
}

// ============================================================
// VIDEO DATABASE
// ============================================================

final List<VideoModel> globalVideos = [
  const VideoModel(
    title: 'Welcome to I-Creator: Ultimate Platform Tour',
    channel: 'I-Creator Official',
    type: 'long',
    views: '1.4M views • 1 day ago',
    networkUrl:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  ),
  const VideoModel(
    title: 'Top Speed Drift Highlights #Shorts',
    channel: 'SpeedRunner',
    type: 'reel',
    views: '850K views',
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
  // VIDEO DETAILS
  // ==========================================================

  void showVideoDetails(
    String filePath,
    String type,
  ) {
    final TextEditingController titleController =
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
                  onPressed: () {
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

                    setState(() {
                      globalVideos.insert(
                        0,
                        VideoModel(
                          title: title,
                          channel:
                              UserSession.channelName,
                          type: type,
                          views: 'Just now',
                          filePath: filePath,
                        ),
                      );
                    });

                    Navigator.pop(ctx);

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
      const ReelsScreen(),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              itemCount: videos.length,
              itemBuilder:
                  (context, index) {
                return VideoCard(
                  video: videos[index],
                );
              },
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

          child: GestureDetector(
            onTap: () {
              if (controller == null ||
                  !controller!
                      .value
                      .isInitialized) {
                return;
              }

              if (controller!
                  .value
                  .isPlaying) {
                controller!.pause();
              } else {
                controller!.play();
              }

              setState(() {});
            },

            child: Container(
              color: Colors.black,
              child: player,
            ),
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.all(12),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              CircleAvatar(
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
  const ReelsScreen({super.ke
