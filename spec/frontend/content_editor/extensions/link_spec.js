import Link from '~/content_editor/extensions/link';
import { createTestEditor, createDocBuilder, triggerMarkInputRule } from '../test_utils';

describe('content_editor/extensions/link', () => {
  let tiptapEditor;
  let doc;
  let p;
  let link;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Link] });
    ({
      builders: { doc, p, link },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        link: { markType: Link.name },
      },
    }));
  });

  afterEach(() => {
    tiptapEditor.destroy();
  });

  it.each`
    input                             | insertedNode
    ${'[gitlab](https://gitlab.com)'} | ${() => p(link({ href: 'https://gitlab.com' }, 'gitlab'))}
    ${'[documentation](readme.md)'}   | ${() => p(link({ href: 'readme.md' }, 'documentation'))}
    ${'[link 123](readme.md)'}        | ${() => p(link({ href: 'readme.md' }, 'link 123'))}
    ${'[link 123](read me.md)'}       | ${() => p(link({ href: 'read me.md' }, 'link 123'))}
    ${'text'}                         | ${() => p('text')}
    ${'documentation](readme.md'}     | ${() => p('documentation](readme.md')}
    ${'http://example.com '}          | ${() => p(link({ href: 'http://example.com' }, 'http://example.com'))}
    ${'https://example.com '}         | ${() => p(link({ href: 'https://example.com' }, 'https://example.com'))}
    ${'www.example.com '}             | ${() => p(link({ href: 'www.example.com' }, 'www.example.com'))}
    ${'example.com/ab.html '}         | ${() => p('example.com/ab.html')}
    ${'https://www.google.com '}      | ${() => p(link({ href: 'https://www.google.com' }, 'https://www.google.com'))}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNode }) => {
    const expectedDoc = doc(insertedNode());

    triggerMarkInputRule({ tiptapEditor, inputRuleText: input });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
