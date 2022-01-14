import { Node, mergeAttributes } from '@tiptap/core';

export default Node.create({
  name: 'descriptionItem',
  content: 'block+',
  defining: true,

  addAttributes() {
    return {
      isTerm: {
        default: true,
        parseHTML: (element) => element.tagName.toLowerCase() === 'dt',
      },
    };
  },

  parseHTML() {
    return [{ tag: 'dt' }, { tag: 'dd' }];
  },

  renderHTML({ HTMLAttributes: { isTerm, ...HTMLAttributes } }) {
    return [
      'li',
      mergeAttributes(HTMLAttributes, { class: isTerm ? 'dl-term' : 'dl-description' }),
      0,
    ];
  },

  addKeyboardShortcuts() {
    return {
      Enter: () => {
        return this.editor.commands.splitListItem('descriptionItem');
      },
      Tab: () => {
        const { isTerm } = this.editor.getAttributes('descriptionItem');
        if (isTerm)
          return this.editor.commands.updateAttributes('descriptionItem', { isTerm: !isTerm });

        return false;
      },
      'Shift-Tab': () => {
        const { isTerm } = this.editor.getAttributes('descriptionItem');
        if (isTerm) return this.editor.commands.liftListItem('descriptionItem');

        return this.editor.commands.updateAttributes('descriptionItem', { isTerm: true });
      },
    };
  },
});
