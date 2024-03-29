import 'dart:async';
import 'dart:io';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_editor_pro/image_editor_pro.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:roaster/models/user.dart';
import 'package:roaster/pages/activity_feed.dart';
import 'package:roaster/pages/comments.dart';
import 'package:roaster/pages/home.dart';
import 'package:roaster/pages/upload.dart';
import 'package:roaster/widgets/custom_image.dart';
import 'package:roaster/widgets/progress.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post(
      {this.username,
      this.description,
      this.likes,
      this.location,
      this.mediaUrl,
      this.ownerId,
      this.postId});

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      description: doc['description'],
      likes: doc['likes'],
      location: doc['location'],
      mediaUrl: doc['mediaUrl'],
      ownerId: doc['ownerId'],
      username: doc['username'],
    );
  }

  int getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count++;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
      username: this.username,
      description: this.description,
      likeCount: getLikeCount(this.likes),
      likes: this.likes,
      location: this.location,
      mediaUrl: this.mediaUrl,
      ownerId: this.ownerId,
      postId: this.postId);
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;
  File _image;

  _PostState(
      {this.username,
      this.description,
      this.likes,
      this.location,
      this.mediaUrl,
      this.ownerId,
      this.likeCount,
      this.postId});

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: IconButton(
            onPressed: () => handleDeletePost(context),
            icon: Icon(Icons.more_vert),
          ),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    bool isPostOwner = currentUserId == ownerId;
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: isPostOwner
                ? Text("Remove this post?")
                : Text('Save this post?'),
            children: <Widget>[
              if (isPostOwner)
                SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context);
                      deletePost();
                    },
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    )),
              if (isPostOwner)
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel')),
              SimpleDialogOption(
                  onPressed: _saveNetworkImage, child: Text('Save Post')),
            ],
          );
        });
  }

  void _saveNetworkImage() async {
    String path = await _findPath(imageUrl: mediaUrl);

    print(mediaUrl);
    GallerySaver.saveImage(path).then((bool success) {
      setState(() {
        print('Image is saved');
      });
    });
    // SnackBar snackbar = SnackBar(content: Text("Profile updated!"));
    // _scaffoldKey.currentState.showSnackBar(snackbar);
    Navigator.pop(context);
  }

  // Note: To delete post, ownerId and currentUserId must be equal, so they can be used interchangeably
  deletePost() async {
    // delete post itself
    postsRef.doc(ownerId).collection('userPosts').doc(postId).get().then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete uploaded image for the post
    storageRef.child("post_$postId.jpg").delete();
    // then delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(ownerId)
        .collection("feedItems")
        .where('postId', isEqualTo: postId)
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // then delete all comments
    QuerySnapshot commentsSnapshot =
        await commentsRef.doc(postId).collection('comments').get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  addLikeToActivityFeed() {
    // add a notification to the postOwner's activity feed only if comment made by OTHER user (to avoid getting notification for our own like)
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef.doc(ownerId).collection("feedItems").doc(postId).set({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": timestamp,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  Future<String> _findPath({String imageUrl}) async {
    // final cache = await CacheManager()..getInstance();
    // final file = await cache.getFile(imageUrl);
    var file = await DefaultCacheManager().getSingleFile(imageUrl);
    return file.path;
  }

  Future<void> getimageditor({String filePath}) async {
    var decodedImage =
        await decodeImageFromList(File(filePath).readAsBytesSync());

    final geteditimage =
        Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ImageEditorPro(
        image: File(filePath),
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        appBarColor: Colors.blue,
        bottomBarColor: Colors.blue,
      );
    })).then((geteditimage) {
      if (geteditimage != null) {
        setState(() {
          _image = geteditimage;
          //pass image to upload
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Upload(
                  uploadImage: geteditimage,
                  currentUser: currentUser,
                  roastedId: ownerId),
            ),
          );
        });
      }
    }).catchError((er) {
      print(er);
    });
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (context, anim, child) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80.0,
                      color: Colors.red,
                    ),
                  ),
                )
              : Text(""),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () async {
                final path = await _findPath(imageUrl: mediaUrl);

                getimageditor(
                  filePath: path,
                );
              },
              child: Icon(
                Icons.whatshot,
                size: 28.0,
                color: Colors.red,
              ),
            )
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username ",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [buildPostHeader(), buildPostImage(), buildPostFooter()],
    );
  }
}

showComments(BuildContext context,
    {String postId, String ownerId, String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl,
    );
  }));
}
