import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PokemonQuiz(),
    );
  }
}

class PokemonQuiz extends StatefulWidget {
  @override
  _PokemonQuizState createState() => _PokemonQuizState();
}

class _PokemonQuizState extends State<PokemonQuiz> {
  List<dynamic> pokemonList = [];
  String correctAnswer = '';
  String correctPokemonImageUrl = '';
  List<String> options = [];
  int questionCount = 0;

  @override
  void initState() {
    super.initState();
    fetchPokemonList();
  }

  Future<void> fetchPokemonList() async {
    final response = await http
        .get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=150'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        pokemonList = data['results'];
        generateQuestion();
      });
    } else {
      throw Exception('Failed to load Pokémon list');
    }
  }

  Future<void> fetchPokemonDetails(String pokemonName) async {
    final response = await http
        .get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$pokemonName'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        correctPokemonImageUrl = data['sprites']['front_default'];
      });
    } else {
      throw Exception('Failed to load Pokémon details');
    }
  }

  void generateQuestion() {
    if (questionCount < 10) {
      final random = Random();
      final correctIndex = random.nextInt(pokemonList.length);
      final correctPokemon = pokemonList[correctIndex];
      correctAnswer = correctPokemon['name'];
      fetchPokemonDetails(correctAnswer);

      options = [];
      for (int i = 0; i < 3; i++) {
        final randomOptionIndex = random.nextInt(pokemonList.length);
        options.add(pokemonList[randomOptionIndex]['name']);
      }
      options.add(correctAnswer);

      options.shuffle();
      questionCount++;
    } else {
      // O quiz foi encerrado após 10 perguntas
      showRestartAlertDialog();
    }
  }

  void restartQuiz() {
    questionCount = 0;
    acertos = 0;
    erros = 0;
    generateQuestion();
    Navigator.of(context).pop(); // Fecha o alerta de reinicialização
  }

  void showRestartAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quiz Concluído'),
          content:
              Text('Você respondeu a 10 perguntas. Deseja reiniciar o quiz?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                restartQuiz();
              },
              child: Text('Reiniciar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  int acertos = 0;
  int erros = 0;
  void checkAnswer(String answer) {
    if (answer == correctAnswer) {
      setState(() {
        acertos++;
      });
    } else {
      setState(() {
        erros++;
      });
    }
    generateQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Acertos: $acertos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text('Erros: $erros',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * .1,
          ),
          Text(
            'Qual é o nome deste Pokémon?',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20),
          Image.network(
            correctPokemonImageUrl,
            scale: .3,
          ),
          SizedBox(height: 20),
          Column(
            children: options
                .map((option) => Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(Size(
                                  MediaQuery.of(context).size.width * .8, 40))),
                          onPressed: () => checkAnswer(option),
                          child: Text(option.toUpperCase()),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
