/// Generic models: converters, selectors and schema glue with type args.
library;

import 'package:flutter_example/models/manual_user3.dart';
import 'package:flutter_example/models/simple_generic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers.dart';

void main() {
  test('generic model round-trips through the generated converter', () async {
    final (_, odm) = newDb();
    final book = Book(title: 'Clean Code', author: 'Robert Martin');
    final profile = ManualUser3Profile<Book>(
      email: 'm@example.com',
      age: 40,
      customList: [book],
      customIList: [book],
    );
    final model = ManualUser3<ManualUser3Profile<Book>>(
      id: 'm1',
      name: 'Manual',
      customField: profile,
    );
    await odm.manualUsers3.set(model);
    final read = await odm.manualUsers3('m1').get();
    expect(read?.customField.email, 'm@example.com');
    expect(read?.customField.customIList.single.title, 'Clean Code');
  });

  test('generic selectors work for both instantiations', () async {
    final (_, odm) = newDb();
    await odm.stringGenerics.set(
      StringGeneric(id: 's1', value: 'hello', type: 'string'),
    );
    await odm.intGenerics.set(IntGeneric(id: 'i1', value: 42, type: 'int'));

    expect((await odm.stringGenerics('s1').get())?.value, 'hello');
    expect((await odm.intGenerics('i1').get())?.value, 42);

    final filtered = await odm.stringGenerics
        .where(($) => $.type(isEqualTo: 'string'))
        .get();
    expect(filtered.single.id, 's1');
  });

  test('generic patch builder supports typed set', () async {
    final (_, odm) = newDb();
    await odm.stringGenerics.set(
      StringGeneric(id: 's1', value: 'a', type: 'string'),
    );
    await odm.stringGenerics.patch('s1', (p) => [p.value.set('b')]);
    expect((await odm.stringGenerics('s1').get())?.value, 'b');
  });
}
