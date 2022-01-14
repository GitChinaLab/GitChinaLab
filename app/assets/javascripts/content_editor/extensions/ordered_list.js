import { OrderedList } from '@tiptap/extension-ordered-list';
import { getMarkdownSource } from '../services/markdown_sourcemap';

export default OrderedList.extend({
  addAttributes() {
    return {
      ...this.parent?.(),

      parens: {
        default: false,
        parseHTML: (element) => /^[0-9]+\)/.test(getMarkdownSource(element)),
      },
    };
  },
});
