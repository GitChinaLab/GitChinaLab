import Blockquote from '~/content_editor/extensions/blockquote';
import { createTestEditor, createDocBuilder, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/blockquote', () => {
  let tiptapEditor;
  let doc;
  let p;
  let blockquote;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Blockquote] });

    ({
      builders: { doc, p, blockquote },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        blockquote: { nodeType: Blockquote.name },
      },
    }));
  });

  it.each`
    input      | insertedNode
    ${'>>> '}  | ${() => blockquote({ multiline: true }, p())}
    ${'> '}    | ${() => blockquote(p())}
    ${' >>> '} | ${() => blockquote({ multiline: true }, p())}
    ${'>> '}   | ${() => p()}
    ${'>>>x '} | ${() => p()}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNode }) => {
    const expectedDoc = doc(insertedNode());

    triggerNodeInputRule({ tiptapEditor, inputRuleText: input });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
