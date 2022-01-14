import { Node } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default Node.create({
  name: 'detailsContent',
  content: 'block+',
  defining: true,

  parseHTML() {
    return [
      { tag: '*', consuming: false, context: 'details/', priority: PARSE_HTML_PRIORITY_HIGHEST },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['li', HTMLAttributes, 0];
  },

  addKeyboardShortcuts() {
    return {
      Enter: () => this.editor.commands.splitListItem('detailsContent'),
      'Shift-Tab': () => this.editor.commands.liftListItem('detailsContent'),
    };
  },
});
