import InlineDiff from '~/content_editor/extensions/inline_diff';
import { createTestEditor, createDocBuilder, triggerMarkInputRule } from '../test_utils';

describe('content_editor/extensions/inline_diff', () => {
  let tiptapEditor;
  let doc;
  let p;
  let inlineDiff;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [InlineDiff] });
    ({
      builders: { doc, p, inlineDiff },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        inlineDiff: { markType: InlineDiff.name },
      },
    }));
  });

  it.each`
    input                         | insertedNode
    ${'hello{+world+}'}           | ${() => p('hello', inlineDiff('world'))}
    ${'hello{+ world +}'}         | ${() => p('hello', inlineDiff(' world '))}
    ${'{+hello with \nnewline+}'} | ${() => p('{+hello with newline+}')}
    ${'{+open only'}              | ${() => p('{+open only')}
    ${'close only+}'}             | ${() => p('close only+}')}
    ${'hello{-world-}'}           | ${() => p('hello', inlineDiff({ type: 'deletion' }, 'world'))}
    ${'hello{- world -}'}         | ${() => p('hello', inlineDiff({ type: 'deletion' }, ' world '))}
    ${'hello {- world-}'}         | ${() => p('hello ', inlineDiff({ type: 'deletion' }, ' world'))}
    ${'{-hello world -}'}         | ${() => p(inlineDiff({ type: 'deletion' }, 'hello world '))}
    ${'{-hello with \nnewline-}'} | ${() => p('{-hello with newline-}')}
    ${'{-open only'}              | ${() => p('{-open only')}
    ${'close only-}'}             | ${() => p('close only-}')}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNode }) => {
    const expectedDoc = doc(insertedNode());

    triggerMarkInputRule({ tiptapEditor, inputRuleText: input });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
