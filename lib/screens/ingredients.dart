import 'package:flutter/material.dart';
import 'package:recipeasy/services/api_services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IngredientsPage extends StatefulWidget {
  const IngredientsPage({Key key}) : super(key: key);
  @override
  _IngredientPageState createState() => _IngredientPageState();
}

class _IngredientPageState extends State<IngredientsPage>{
  List<String> _ingredients = [];

  final myController = TextEditingController();
//  ScrollController _scrollController = new ScrollController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  Widget myInput(){
    return Container(
      width: 370,
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      child: TextField(
        autocorrect: true,
        controller: myController,
        onSubmitted: (myController) {
          _addToList(myController);
          this.myController.clear();
        },
        decoration: InputDecoration(
          hintText: 'Enter Ingredients...',
          hintStyle: TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white70,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
            borderSide: BorderSide(color: Colors.greenAccent, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
            borderSide: BorderSide(color: Colors.greenAccent),
          ),
        ),
      ),
    );
  }

  Widget _ingredientList() {
    return ListView.builder(
        itemCount: _ingredients.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(_ingredients[index]),
              onTap: () => _removeIngredientPrompt(index,1),
            ),
          );
        }
    );
  }

  void _addToList(String ingredient) {
    if(ingredient.length > 0) {
      // Putting our code inside "setState" tells the app that our state has changed, and
      // it will automatically re-render the list
      setState(() => _ingredients.add(ingredient));
    }
  }

  void _removeIngredientPrompt(int index, int mode) {
    if (mode == 1){
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return new AlertDialog(
                title: new Text('Remove "${_ingredients[index]}"?'),
                actions: <Widget>[
                  new FlatButton(
                      child: new Text('CANCEL'),
                      onPressed: () => Navigator.of(context).pop()
                  ),
                  new FlatButton(
                      child: new Text('REMOVE'),
                      textColor: Colors.red,
                      onPressed: () {
                        _removeIngredient(index);
                        Navigator.of(context).pop();
                      }
                  )
                ]
            );
          }
      );
    }
    else if (mode == 2){
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return new AlertDialog(
                title: new Text('Clear Ingredients List?'),
                actions: <Widget>[
                  new FlatButton(
                      child: new Text('CANCEL'),
                      onPressed: () => Navigator.of(context).pop()
                  ),
                  new FlatButton(
                      child: new Text('REMOVE'),
                      textColor: Colors.red,
                      onPressed: () {
                        _clearList();
                        Navigator.of(context).pop();
                      }
                  )
                ]
            );
          }
      );
    }
  }

  void _removeIngredient(int index) {
    setState(() => _ingredients.removeAt(index));
  }

  void _clearList(){
    setState(() => _ingredients.clear());
  }

  void _getRecipeByIngr(BuildContext context, List <String>ingr) async {
    var ingr = _ingredients.join(',');
    var recipes = await ApiService.instance.recipeByIngr(ingr);
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecipesFound(recipes: recipes)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("RECIPEASY"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            myInput(),
            Expanded(
              child: _ingredientList(),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                child: FloatingActionButton(
                  heroTag: 'btn1',
                  onPressed: (){
                    _removeIngredientPrompt(null, 2);
                  },
                  child: Icon(Icons.clear),
                ),
              ),
            ]
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              FloatingActionButton.extended(
                heroTag: 'btn2',
                onPressed: (){
                  _getRecipeByIngr(context,_ingredients);
                },
                label: Text('Get Recipe By Ingredients'),
              ),
            ]
          ),
        ],
      ),
    );
  }
}

class RecipesFound extends StatefulWidget {
  final List<dynamic> recipes;
  RecipesFound({this.recipes});

  @override
  _RecipesFoundState createState() => _RecipesFoundState();
}

class _RecipesFoundState extends State<RecipesFound> {

  _save(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> myList = (prefs.getStringList('mylist') ?? List<String>());

    if(myList.length > 2){
      myList.removeLast();
    }
    myList.insert(0, id.toString());
    await prefs.setStringList('mylist', myList);
  }

  void goToRecipe(int id) async{
    var url = await ApiService.instance.retrieveUrl(id);
    _save(id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewRecipe(url: url)),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("RECIPEASY"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: widget.recipes.length,
        itemBuilder: (context, index) {
          return Container(
            color: Colors.blueGrey[100],
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: InkWell(
              onTap: () {goToRecipe(widget.recipes[index]['id']);},
              child: Padding(
                padding: EdgeInsets.fromLTRB(5, 7, 5, 10),
                child: Column(
                  children: <Widget>[
                    Text(
                      widget.recipes[index]['title'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Image.network(
                        widget.recipes[index]['image'],
                      ),
                    )
                  ],
                ),
              ),
            )
          );
        }
      )
    );
  }
}

class ViewRecipe extends StatefulWidget {
  final String url;
  ViewRecipe({this.url});

  @override
  _ViewRecipeState createState() => _ViewRecipeState();
}

class _ViewRecipeState extends State<ViewRecipe> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("RECIPEASY"),
        centerTitle: true,
      ),
      body: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}