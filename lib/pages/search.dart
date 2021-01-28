import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:roaster/models/user.dart';
import 'package:roaster/pages/activity_feed.dart';
import 'package:roaster/pages/home.dart';
import 'package:roaster/widgets/advertisementData.dart';
import 'package:roaster/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  // BannerAd _bannerAd;
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
  }

  @override
  void dispose() {
    super.dispose();
    // try {
    //   _bannerAd?.dispose();
    //   _bannerAd = null;
    // } catch (ex) {
    //   print("banner dispose error");
    // }
  }

  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;
  handleSearch(String query) {
    if (searchController.text.trim() != '') {
      Future<QuerySnapshot> users =
          usersRef.where('displayName', isGreaterThanOrEqualTo: query).get();

      setState(() {
        searchResultsFuture = users;
      });
    }
  }

  clearSearch() {
    searchController.clear();
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        validator: (val) {
          if (val.trim().contains(' ') || val.trim() == '') {
            return 'Username contain whitespace';
          } else {
            return null;
          }
        },
        controller: searchController,
        decoration: InputDecoration(
            hintText: 'Search for a user...',
            filled: true,
            prefixIcon: Icon(
              Icons.account_box,
              size: 28.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: clearSearch,
            )),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 300.0 : 200.0,
            ),
            Text(
              "Find Users",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 60.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.docs.forEach((doc) {
          User user = User.fromDocument(doc);
          UserResult searchResult = UserResult(user);

          searchResults.add(searchResult);
          print(user.username);
        });
        return Container(
          margin: const EdgeInsets.only(top: 60.0),
          child: ListView(
            children: searchResults,
          ),
        );
      },
    );
  }

  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.2),
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}
