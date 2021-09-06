import 'package:test/test.dart';
import '../bin/trello_integration.dart';

void main() {
  group('GitHub Columns', () {
    const githubApiToken = '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';
    final gitHubColumns = {
      'To Do': '/projects/columns/15793814/cards',
      'In Progress': '/projects/columns/15793815/cards',
      'Done': '/projects/columns/15793816/cards',
    };

    test('Get "To Do" Cards', () async {
      print(
        '''  ---Get "To Do" Cards---\n'''
        '''  This test depends on current number of tasks on GitHub Project.\n'''
        '''  Check them before run this test.''',
      );

      final cards = await getGitHubCards(
        gitHubColumns['To Do']!,
        githubApiToken,
      );

      expect(cards, isNotNull);
      expect(cards, hasLength(7));
      for (var card in cards) {
        expect(card.contentUrl.isNotEmpty || card.note.isNotEmpty, true);
        final title = await card.content;
        expect(title, isNotNull);
        expect(title, isNotEmpty);
      }
    });

    test('Get "In Progress" Cards', () async {
      print(
        '''  ---Get "In Progress" Cards---\n'''
        '''  This test depends on current number of tasks on GitHub Project.\n'''
        '''  Check them before run this test.''',
      );

      final cards = await getGitHubCards(
        gitHubColumns['In Progress']!,
        githubApiToken,
      );

      expect(cards, isNotNull);
      expect(cards, hasLength(2));
      for (var card in cards) {
        expect(card.contentUrl.isNotEmpty || card.note.isNotEmpty, true);
        final title = await card.content;
        expect(title, isNotNull);
        expect(title, isNotEmpty);
      }
    });

    test('Get "Done" Cards', () async {
      print(
        '''  ---Get "Done" Cards---\n'''
        '''  This test depends on current number of tasks on GitHub Project.\n'''
        '''  Check them before run this test.''',
      );

      final cards = await getGitHubCards(
        gitHubColumns['Done']!,
        githubApiToken,
      );

      expect(cards, isNotNull);
      expect(cards, hasLength(1));
      for (var card in cards) {
        expect(card.contentUrl.isNotEmpty || card.note.isNotEmpty, true);
        final title = await card.content;
        expect(title, isNotNull);
        expect(title, isNotEmpty);
      }
    });
  });

  group('Trello Lists', () {
    final trelloLists = {
      'To Do': '/1/lists/60f98e572884e949af205a9d/cards',
      'In Progress': '1/lists/60f98e645d2ca1514b245b4d/cards',
      'Done': '1/lists/60f98e68d3ae1c1514b04e15/cards',
    };

    test('Get "To Do" List', () async {
      final cards = await getTrelloCards(trelloLists['To Do']!);

      expect(cards, isNotNull);
      for (var card in cards) {
        expect(card.name, isNotNull);
        final title = await card.content;
        expect(title, isNotNull);
        expect(title, isNotEmpty);
      }
    });

    test('Get "In Progress" List', () async {
      final cards = await getTrelloCards(trelloLists['In Progress']!);

      expect(cards, isNotNull);
      for (var card in cards) {
        expect(card.name, isNotNull);
        final title = await card.content;
        expect(title, isNotNull);
        expect(title, isNotEmpty);
      }
    });

    test('Get "Done" List', () async {
      final cards = await getTrelloCards(trelloLists['Done']!);

      expect(cards, isNotNull);
      for (var card in cards) {
        expect(card.name, isNotNull);
        final title = await card.content;
        expect(title, isNotNull);
        expect(title, isNotEmpty);
      }
    });

    test('Create Card to To Do List', () async {
      final listId = trelloLists['To Do']!.split('/')[3];
      expect(listId, isNotNull);
      expect(listId, isNotEmpty);
      expect(listId, matches(r'^[0-9a-fA-F]{24}$'));

      final content = 'Hello form Dart Tests';
      await createTrelloCard(content, listId);
      final cards = await getTrelloCards(trelloLists['To Do']!);
      expect(cards, isNotNull);
      expect(cards, isNotEmpty);
      expect(cards.any((card) => card.name == content), true);
    });

    test('Delete Card from To do List', () async {
      final content = 'Hello form Delete Tests';
      final listId = trelloLists['To Do']!.split('/')[3];
      expect(listId, isNotNull);
      expect(listId, isNotEmpty);
      expect(listId, matches(r'^[0-9a-fA-F]{24}$'));

      await createTrelloCard(content, listId);
      final trelloCards = await getTrelloCards(trelloLists['To Do']!);
      expect(trelloCards, isNotEmpty);
      var id = '';
      for (var trelloCard in trelloCards) {
        if (trelloCard.name == content) {
          id = trelloCard.id;
        }
      }
      expect(id, isNotEmpty);
      await deleteTrelloCard(id);
    });
  });
}
