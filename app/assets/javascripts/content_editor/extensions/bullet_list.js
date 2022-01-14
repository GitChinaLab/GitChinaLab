import { BulletList } from '@tiptap/extension-bullet-list';
import { getMarkdownSource } from '../services/markdown_sourcemap';

export default BulletList.extend({
  addAttributes() {
    return {
      ...this.parent?.(),

      bullet: {
        default: '*',
        parseHTML(element) {
          const bullet = getMarkdownSource(element)?.charAt(0);

          return '*+-'.includes(bullet) ? bullet : '*';
        },
      },
    };
  },
});
