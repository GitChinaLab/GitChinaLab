import { shallowMount } from '@vue/test-utils';
import Shortcut from '~/behaviors/shortcuts/shortcut.vue';

describe('Shortcut Vue Component', () => {
  const render = (shortcuts) => shallowMount(Shortcut, { propsData: { shortcuts } }).html();

  afterEach(() => {
    delete window.gl.client;
  });

  describe.each([true, false])('With browser env isMac: %p', (isMac) => {
    beforeEach(() => {
      window.gl = { client: { isMac } };
    });

    it.each([
      ['up', '<kbd>↑</kbd>'],
      ['down', '<kbd>↓</kbd>'],
      ['left', '<kbd>←</kbd>'],
      ['right', '<kbd>→</kbd>'],
      ['ctrl', '<kbd>Ctrl</kbd>'],
      ['shift', '<kbd>Shift</kbd>'],
      ['enter', '<kbd>Enter</kbd>'],
      ['esc', '<kbd>Esc</kbd>'],
      // Some normal ascii letter
      ['a', '<kbd>a</kbd>'],
      // An umlaut letter
      ['ø', '<kbd>ø</kbd>'],
      // A number
      ['5', '<kbd>5</kbd>'],
    ])('renders platform agnostic key %p as: %p', (key, rendered) => {
      expect(render([key])).toEqual(`<div>${rendered}</div>`);
    });

    it('renders keys combined with plus ("+") correctly', () => {
      expect(render(['shift+a+b+c'])).toEqual(
        `<div><kbd>Shift</kbd> + <kbd>a</kbd> + <kbd>b</kbd> + <kbd>c</kbd></div>`,
      );
    });

    it('renders keys combined with space (" ") correctly', () => {
      expect(render(['shift a b c'])).toEqual(
        `<div><kbd>Shift</kbd> then <kbd>a</kbd> then <kbd>b</kbd> then <kbd>c</kbd></div>`,
      );
    });

    it('renders multiple shortcuts correctly', () => {
      expect(render(['shift+[', 'shift+k'])).toEqual(
        `<div><kbd>Shift</kbd> + <kbd>[</kbd> or <br><kbd>Shift</kbd> + <kbd>k</kbd></div>`,
      );
      expect(render(['[', 'k'])).toEqual(`<div><kbd>[</kbd> or <kbd>k</kbd></div>`);
    });
  });

  describe('With browser env isMac: true', () => {
    beforeEach(() => {
      window.gl = { client: { isMac: true } };
    });

    it.each([
      ['mod', '<kbd>⌘</kbd>'],
      ['command', '<kbd>⌘</kbd>'],
      ['meta', '<kbd>⌘</kbd>'],
      ['option', '<kbd>⌥</kbd>'],
      ['alt', '<kbd>⌥</kbd>'],
    ])('renders platform specific key %p as: %p', (key, rendered) => {
      expect(render([key])).toEqual(`<div>${rendered}</div>`);
    });

    it('does render Mac specific shortcuts', () => {
      expect(render(['command+[', 'ctrl+k'])).toEqual(
        `<div><kbd>⌘</kbd> + <kbd>[</kbd> or <br><kbd>Ctrl</kbd> + <kbd>k</kbd></div>`,
      );
    });
  });

  describe('With browser env isMac: false', () => {
    beforeEach(() => {
      window.gl = { client: { isMac: false } };
    });

    it.each([
      ['mod', '<kbd>Ctrl</kbd>'],
      ['command', ''],
      ['meta', ''],
      ['option', '<kbd>Alt</kbd>'],
      ['alt', '<kbd>Alt</kbd>'],
    ])('renders platform specific key %p as: %p', (key, rendered) => {
      expect(render([key])).toEqual(`<div>${rendered}</div>`);
    });

    it('does not render Mac specific shortcuts', () => {
      expect(render(['command+[', 'ctrl+k'])).toEqual(`<div><kbd>Ctrl</kbd> + <kbd>k</kbd></div>`);
    });
  });
});
