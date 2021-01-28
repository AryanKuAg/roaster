import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:roaster/widgets/advertisementData.dart';
import 'package:roaster/widgets/header.dart';
import '../models/user.dart';
import '../pages/home.dart';
import '../widgets/post.dart';
import '../widgets/progress.dart';
import '../pages/search.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  // BannerAd _bannerAd;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    // FirebaseAdMob.instance
    //     .initialize(appId: 'ca-app-pub-3739926644625425~2711043189');
    //
    // _bannerAd = AdvertisementData().createBannerAd()
    //   ..load().then((value) {
    //     if (value && this.mounted) {
    //       _bannerAd..show(anchorType: AnchorType.top, anchorOffset: 85.0);
    //     }
    //   });
    getTimeline();
    getFollowing();
  }

  // @override
  // void dispose() {
  //   super.dispose();
  //   try {
  //     _bannerAd?.dispose();
  //     _bannerAd = null;
  //   } catch (ex) {
  //     print("banner dispose error");
  //   }
  // }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .get();

    List<Post> posts =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();

    setState(() {
      this.posts = posts;
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return Container(child: ListView(children: posts));
    }
  }

  buildUsersToFollow() {
    return Container(
      child: StreamBuilder(
        stream: usersRef
            .orderBy('timestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> userResults = [];
          snapshot.data.docs.forEach((doc) {
            User user = User.fromDocument(doc);
            final bool isAuthUser = currentUser.id == user.id;
            final bool isFollowingUser = followingList.contains(user.id);
            // remove auth user from recommended list
            if (isAuthUser) {
              return;
            } else if (isFollowingUser) {
              return;
            } else {
              UserResult userResult = UserResult(user);
              userResults.add(userResult);
            }
          });
          return Container(
            color: Theme.of(context).accentColor.withOpacity(0.2),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.person_add,
                        color: Theme.of(context).primaryColor,
                        size: 30.0,
                      ),
                      SizedBox(
                        width: 8.0,
                      ),
                      Text(
                        "Users to Follow",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 30.0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (userResults != null)
                  Column(children: userResults)
                else
                  Container(child: Text('')),
              ],
            ),
          );
        },
      ),
    );
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(currentUser.id)
        .collection('userFollowing')
        .get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  @override
  Widget build(context) {
    return Scaffold(
        appBar: header(isAppTitle: true),
        body: RefreshIndicator(
          onRefresh: () => getTimeline(),
          child: buildTimeline(),
        ));
  }
}
