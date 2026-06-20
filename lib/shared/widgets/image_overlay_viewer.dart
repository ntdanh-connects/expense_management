import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';

class ImageOverlayViewer extends StatefulWidget {
  final String? imageUrl;
  final File? imageFile;
  final String heroTag;

  const ImageOverlayViewer({
    super.key,
    this.imageUrl,
    this.imageFile,
    required this.heroTag,
  });

  static void show(
    BuildContext context, {
    String? imageUrl,
    File? imageFile,
    required String heroTag,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.5),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ImageOverlayViewer(
              imageUrl: imageUrl,
              imageFile: imageFile,
              heroTag: heroTag,
            ),
          );
        },
      ),
    );
  }

  @override
  State<ImageOverlayViewer> createState() => _ImageOverlayViewerState();
}

class _ImageOverlayViewerState extends State<ImageOverlayViewer> {
  bool _isDownloading = false;

  Future<void> _shareAndSaveImage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      String? filePath;
      if (widget.imageFile != null) {
        filePath = widget.imageFile!.path;
      } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        String extension = 'jpg';
        try {
          final uri = Uri.parse(widget.imageUrl!);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final lastSegment = pathSegments.last;
            if (lastSegment.contains('.')) {
              extension = lastSegment.split('.').last;
            }
          }
        } catch (_) {}
        
        filePath = '${tempDir.path}/EM_image_${DateTime.now().millisecondsSinceEpoch}.$extension';
        await Dio().download(widget.imageUrl!, filePath);
      }

      if (filePath != null && mounted) {
        await Share.shareXFiles([XFile(filePath)], text: 'EM App Image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải ảnh: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Nền kính mờ
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
            ),
          ),
          
          // Khu vực hiển thị ảnh với InteractiveViewer (pinch-to-zoom)
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80.0),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: GestureDetector(
                      onTap: () {}, // chặn sự kiện tap vào ảnh để không bị pop
                      child: Hero(
                        tag: widget.heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildImage(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Nút bấm điều khiển phía trên
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút Close
                    ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: Colors.white.withOpacity(0.15),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                    
                    // Nút Download/Share
                    ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: Colors.white.withOpacity(0.15),
                          child: _isDownloading
                              ? const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 22),
                                  onPressed: _shareAndSaveImage,
                                  tooltip: 'Chia sẻ & Lưu ảnh',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageFile != null) {
      return Image.file(
        widget.imageFile!,
        fit: BoxFit.contain,
      );
    } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: Colors.white54,
            size: 48,
          ),
        ),
      );
    } else {
      return const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white54,
          size: 48,
        ),
      );
    }
  }
}
