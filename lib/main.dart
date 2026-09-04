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



// ============================================================
// VIDEO DATABASE
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

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'channel': channel,
      'type': type,
      'views': views,
      'networkUrl': networkUrl,
    };
  }

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      title: map['title'] ?? '',
      channel: map['channel'] ?? '',
      type: map['type'] ?? 'long',
      views: map['views'] ?? '',
      networkUrl: map['networkUrl'],
    );
  }
}
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
                      views: 'Just now',
                      networkUrl: uploadedUrl,
                    );

                    await FirebaseFirestore.instance
                        .collection('videos')
                        .add(newVideo.toMap());

                    setState(() {
                      globalVideos.insert(0, newVideo);
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
          .map((doc) => VideoModel.fromMap(doc.data()))
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

  @override
  void initState() {
    super.initState();
    initializeVideo();
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.video.title),
      ),
      body: Center(
        child: error != null
            ? Text(error!, style: const TextStyle(color: Colors.grey))
            : controller != null && controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          controller!.value.isPlaying
                              ? controller!.pause()
                              : controller!.play();
                        });
                      },
                      child: VideoPlayer(controller!),
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.redAccent),
      ),
    );
  }
}
// ============================================================
// CHANNEL SCREEN (View any creator's channel)
// ============================================================

class ChannelScreen extends StatelessWidget {
  final String channelName;

  const ChannelScreen({super.key, required this.channelName});

  @override
  Widget build(BuildContext context) {
    final channelVideos = globalVideos
        .where((v) => v.channel == channelName)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(channelName),
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
                      channelName.isNotEmpty
                          ? channelName[0].toUpperCase()
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
                          channelName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '0 subscribers',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () {},
                    child: const Text('Subscribe'),
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
