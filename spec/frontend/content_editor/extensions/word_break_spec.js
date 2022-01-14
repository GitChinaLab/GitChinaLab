import WordBreak from '~/content_editor/extensions/word_break';
import { createTestEditor, createDocBuilder, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/word_break', () => {
  let tiptapEditor;
  let doc;
  let p;
  let wordBreak;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [WordBreak] });

    ({
      builders: { doc, p, wordBreak },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        wordBreak: { nodeType: WordBreak.name },
      },
    }));
  });

  it.each`
    input      | insertedNode
    ${'<wbr>'} | ${() => p(wordBreak())}
    ${'<wbr'}  | ${() => p()}
    ${'wbr>'}  | ${() => p()}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNode }) => {
    const expectedDoc = doc(insertedNode());

    triggerNodeInputRule({ tiptapEditor, inputRuleText: input });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
