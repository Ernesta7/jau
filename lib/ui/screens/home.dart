import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:jau/model/recipe.dart';
import 'package:jau/utils/store.dart';
import 'package:jau/ui/widgets/recipe_card.dart';
import 'package:jau/model/state.dart';
import 'package:jau/state_widget.dart';
import 'package:jau/ui/screens/login.dart';
import 'package:jau/ui/screens/add.dart';
import 'package:jau/ui/widgets/settings_button.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  StateModel appState;

  DefaultTabController _buildTabView({Widget body}) {
    const double _iconSize = 20.0;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: PreferredSize(
          // We set Size equal to passed height (50.0) and infinite width:
          preferredSize: Size.fromHeight(50.0),
          child: AppBar(
            elevation: 2.0,
            bottom: TabBar(
              labelColor: Theme.of(context).indicatorColor,
              tabs: [
                Tab(icon: Icon(Icons.restaurant, size: _iconSize)),
                Tab(icon: Icon(Icons.local_drink, size: _iconSize)),
                Tab(icon: Icon(Icons.favorite, size: _iconSize)),
                Tab(icon: Icon(Icons.settings, size: _iconSize)),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(5.0),
          child: body,
        ),
//Maybe will be implemented in future
//        floatingActionButton: FloatingActionButton(
//            onPressed: ()=> Navigator.push(
//              context,
//              MaterialPageRoute(
//                builder: (context) => new AddScreen(),
//              ),
//            ),
//            child: Icon(
//                Icons.add,
//                color: Theme.of(context).iconTheme.color
//            ),
//          elevation: 2.0,
//          backgroundColor: Colors.white,
//        ),
      ),
    );
  }
  //For building and showing application data
  Widget _buildContent() {
    if (appState.isLoading) {
      return _buildTabView(
        body: _buildLoadingIndicator(),
      );
    } else if (!appState.isLoading && appState.user == null) {
      return new LoginScreen();
    } else {
      return _buildTabView(
        body: _buildTabsContent(),
      );
    }
  }

  Center _buildLoadingIndicator() {
    return Center(
      child: new CircularProgressIndicator(),
    );
  }
  //Application settings view
  Column _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsButton(
          Icons.exit_to_app,
          "Log out",
          appState.user.displayName,
              () async {
            await StateWidget.of(context).signOutOfGoogle();
          },
        ),
      ],
    );
  }
  //Init application tab menu
  TabBarView _buildTabsContent() {
    Padding _buildRecipes({RecipeType recipeType, List<String> ids}) {
      CollectionReference collectionReference =
      Firestore.instance.collection('recipes');
      Stream<QuerySnapshot> stream;
      // The argument recipeType is set
      if (recipeType != null) {
        stream = collectionReference
            .where("type", isEqualTo: recipeType.index)
            .snapshots();
      } else {
        // Use snapshots of all recipes if recipeType has not been passed
        stream = collectionReference.snapshots();
      }

      // Define query depeneding on passed args
      return Padding(
        // Padding before and after the list view:
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: new StreamBuilder(
                stream: stream,
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) return _buildLoadingIndicator();
                  return new ListView(
                    children: snapshot.data.documents
                    // Check if the argument ids contains document ID if ids has been passed:
                        .where((d) => ids == null || ids.contains(d.documentID))
                        .map((document) {
                      return new RecipeCard(
                        recipe:
                        Recipe.fromMap(document.data, document.documentID),
                        inFavorites:
                        appState.favorites.contains(document.documentID),
                        onFavoriteButtonPressed: _handleFavoritesListChanged,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      children: [
        _buildRecipes(recipeType: RecipeType.food),
        _buildRecipes(recipeType: RecipeType.drink),
        _buildRecipes(ids: appState.favorites),
        _buildSettings(),
      ],
    );
  }

  void _handleFavoritesListChanged(String recipeID) {
    updateFavorites(appState.user.uid, recipeID).then((result) {
      if (result == true) {
        setState(() {
          if (!appState.favorites.contains(recipeID))
            appState.favorites.add(recipeID);
          else
            appState.favorites.remove(recipeID);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build the content depending on the state:
    appState = StateWidget.of(context).state;
    return _buildContent();
  }
}
