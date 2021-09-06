import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<List<GitHubCard>> getGitHubCards(
    String columnPath, String gitHubToken) async {
  final uri = Uri(
    scheme: 'https',
    host: 'api.github.com',
    path: columnPath,
  );
  final headers = {
    'Authorization': 'token $gitHubToken',
    'Accept': 'application/vnd.github.inertia-preview'
  };
  final response = await http.get(uri, headers: headers);
  if (response.statusCode != 200) {
    return Future.error('Error on getGithubCards'
        ':${response.statusCode}'
        ':${response.reasonPhrase}'
        ':${response.body}');
  }
  List jsonCards = jsonDecode(response.body);

  final gitHubCards = jsonCards.map((jsonCard) {
    return GitHubCard.fromJson(jsonCard, gitHubToken);
  }).toList();

  return gitHubCards;
}

Future<List<TrelloCard>> getTrelloCards(String listPath) async {
  var uri = Uri(
    scheme: 'https',
    host: 'api.trello.com',
    path: listPath,
    queryParameters: {
      'key': '021a3efe4bcf1f70095fe0e1373fa808',
      'token':
          '263cb9d8f9ed310d34db125c44f6a155a3ce34c09c1e3cb5f5d7b47c978716c0',
    },
  );
  var response = await http.get(uri);
  if (response.statusCode != 200) {
    return Future.error('Error on getTrelloCards'
        ':${response.statusCode}'
        ':${response.reasonPhrase}'
        ':${response.body}');
  }
  var jsonCards = jsonDecode(response.body);

  final trelloCards = jsonCards.map<TrelloCard>((jsonCard) {
    return TrelloCard.fromJson(jsonCard);
  }).toList();

  return trelloCards;
}

Future<void> createTrelloCard(String content, String listId) async {
  final uri = Uri(
    scheme: 'https',
    host: 'api.trello.com',
    path: '/1/cards',
    queryParameters: {
      'name': content,
      'idList': listId,
      'key': '021a3efe4bcf1f70095fe0e1373fa808',
      'token':
          '263cb9d8f9ed310d34db125c44f6a155a3ce34c09c1e3cb5f5d7b47c978716c0',
    },
  );
  await http.post(uri);
}

Future<void> deleteTrelloCard(String id) async {
  final uri = Uri(
    scheme: 'https',
    host: 'api.trello.com',
    path: '/1/cards/$id',
    queryParameters: {
      'key': '021a3efe4bcf1f70095fe0e1373fa808',
      'token':
          '263cb9d8f9ed310d34db125c44f6a155a3ce34c09c1e3cb5f5d7b47c978716c0',
    },
  );
  await http.delete(uri);
}

Future<void> main(List<String> args) async {
  final file = File(args[0]);
  final settingsJson = file.readAsStringSync();
  final body = jsonDecode(settingsJson);

  final githubApiToken = body['github_api_token'];
  final gitHubColumns = {
    'To Do': '/projects/columns/15793814/cards',
    'In Progress': '/projects/columns/15793815/cards',
    'Done': '/projects/columns/15793816/cards',
  };

  final trelloLists = {
    'To Do': '/1/lists/60f98e572884e949af205a9d/cards',
    'In Progress': '/1/lists/60f98e645d2ca1514b245b4d/cards',
    'Done': '/1/lists/60f98e68d3ae1c1514b04e15/cards',
  };

  final columnNames = gitHubColumns.keys.toList();
  for (var columnName in columnNames) {
    final columnPath = gitHubColumns[columnName];
    final gitHubCards = await getGitHubCards(columnPath!, githubApiToken);
    final trelloCards = await getTrelloCards(trelloLists[columnName]!);

    var allCards = <String>{};
    for (var card in gitHubCards) {
      final title = await card.content;
      if (title == '') return;
      allCards.add(title);
    }
    for (var card in trelloCards) {
      final title = await card.content;
      if (title == '') return;
      allCards.add(title);
    }

    for (var card in allCards) {
      var containsGitHub = false;
      for (var gitHubCard in gitHubCards) {
        if ((await gitHubCard.content) == card) {
          containsGitHub = true;
          break;
        }
      }
      var containsTrello = false;
      for (var trelloCard in trelloCards) {
        if ((await trelloCard.content) == card) {
          containsTrello = true;
          break;
        }
      }

      if (containsGitHub && containsTrello) {
        continue;
      } else if (containsGitHub) {
        await createTrelloCard(card, trelloLists[columnName]!.split('/')[3]);
      } else if (containsTrello) {
        var id = '';
        for (var trelloCard in trelloCards) {
          if (await trelloCard.content == card) {
            id = trelloCard.id;
          }
        }
        await deleteTrelloCard(id);
      }
    }
  }
  ;
}

class GitHubCard extends Card {
  String note = '';
  String contentUrl = '';
  Future<String> _content = Future<String>.value('');

  GitHubCard.fromJson(Map<String, dynamic> json, String githubApiToken) {
    if (json.containsKey('note') && json['note'] != null) {
      note = json['note'];
    }
    if (json.containsKey('content_url')) {
      contentUrl = json['content_url'];
      var headers = {
        'Authorization': 'token $githubApiToken',
        'Accept': 'application/vnd.github.inertia-preview'
      };
      _content =
          http.get(Uri.parse(contentUrl), headers: headers).then((response) {
        if (response.statusCode != 200) return '';
        final body = jsonDecode(response.body);
        return body['title'];
      });
    }
  }

  @override
  Future<String> get content =>
      note.isEmpty ? _content : Future<String>.value(note);
}

class TrelloCard extends Card {
  String name = '';
  String id = '';

  TrelloCard({required this.name});

  TrelloCard.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
  }

  @override
  Future<String> get content async => name;

  Map<String, dynamic> toJson() => {'name': name};
}

abstract class Card {
  Future<String> get content;
}
