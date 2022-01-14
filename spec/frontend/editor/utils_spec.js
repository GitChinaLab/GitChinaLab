import { editor as monacoEditor } from 'monaco-editor';
import * as utils from '~/editor/utils';
import { DEFAULT_THEME } from '~/ide/lib/themes';

describe('Source Editor utils', () => {
  let el;

  const stubUserColorScheme = (value) => {
    if (window.gon == null) {
      window.gon = {};
    }
    window.gon.user_color_scheme = value;
  };

  describe('clearDomElement', () => {
    beforeEach(() => {
      setFixtures('<div id="foo"><div id="bar">Foo</div></div>');
      el = document.getElementById('foo');
    });

    it('removes all child nodes from an element', () => {
      expect(el.children.length).toBe(1);
      utils.clearDomElement(el);
      expect(el.children.length).toBe(0);
    });
  });

  describe('setupEditorTheme', () => {
    beforeEach(() => {
      jest.spyOn(monacoEditor, 'defineTheme').mockImplementation();
      jest.spyOn(monacoEditor, 'setTheme').mockImplementation();
    });

    it.each`
      themeName            | expectedThemeName
      ${'solarized-light'} | ${'solarized-light'}
      ${DEFAULT_THEME}     | ${DEFAULT_THEME}
      ${'non-existent'}    | ${DEFAULT_THEME}
    `(
      'sets the $expectedThemeName theme when $themeName is set in the user preference',
      ({ themeName, expectedThemeName }) => {
        stubUserColorScheme(themeName);
        utils.setupEditorTheme();

        expect(monacoEditor.setTheme).toHaveBeenCalledWith(expectedThemeName);
      },
    );
  });

  describe('getBlobLanguage', () => {
    it.each`
      path           | expectedLanguage
      ${'foo.js'}    | ${'javascript'}
      ${'foo.js.rb'} | ${'ruby'}
      ${'foo.bar'}   | ${'plaintext'}
      ${undefined}   | ${'plaintext'}
    `(
      'sets the $expectedThemeName theme when $themeName is set in the user preference',
      ({ path, expectedLanguage }) => {
        const language = utils.getBlobLanguage(path);

        expect(language).toEqual(expectedLanguage);
      },
    );
  });

  describe('setupCodeSnipet', () => {
    beforeEach(() => {
      jest.spyOn(monacoEditor, 'colorizeElement').mockImplementation();
      jest.spyOn(monacoEditor, 'setTheme').mockImplementation();
      setFixtures('<pre id="foo"></pre>');
      el = document.getElementById('foo');
    });

    it('colorizes the element and applies the preference theme', () => {
      expect(monacoEditor.colorizeElement).not.toHaveBeenCalled();
      expect(monacoEditor.setTheme).not.toHaveBeenCalled();

      utils.setupCodeSnippet(el);

      expect(monacoEditor.colorizeElement).toHaveBeenCalledWith(el);
      expect(monacoEditor.setTheme).toHaveBeenCalled();
    });
  });
});
