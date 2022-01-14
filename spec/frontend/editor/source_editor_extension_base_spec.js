import { Range } from 'monaco-editor';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  EDITOR_TYPE_CODE,
  EDITOR_TYPE_DIFF,
  EXTENSION_BASE_LINE_LINK_ANCHOR_CLASS,
  EXTENSION_BASE_LINE_NUMBERS_CLASS,
} from '~/editor/constants';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';
import EditorInstance from '~/editor/source_editor_instance';

describe('The basis for an Source Editor extension', () => {
  const defaultLine = 3;
  let event;

  const findLine = (num) => {
    return document.querySelector(`.${EXTENSION_BASE_LINE_NUMBERS_CLASS}:nth-child(${num})`);
  };
  const generateLines = () => {
    let res = '';
    for (let line = 1, lines = 5; line <= lines; line += 1) {
      res += `<div class="${EXTENSION_BASE_LINE_NUMBERS_CLASS}">${line}</div>`;
    }
    return res;
  };
  const generateEventMock = ({ line = defaultLine, el = null } = {}) => {
    return {
      target: {
        element: el || findLine(line),
        position: {
          lineNumber: line,
        },
      },
    };
  };
  const createInstance = (baseInstance = {}) => {
    return new EditorInstance(baseInstance);
  };

  beforeEach(() => {
    setFixtures(generateLines());
    event = generateEventMock();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('onUse callback', () => {
    it('initializes the line highlighting', () => {
      const instance = createInstance();
      const spy = jest.spyOn(SourceEditorExtension, 'highlightLines');

      instance.use({ definition: SourceEditorExtension });
      expect(spy).toHaveBeenCalled();
    });

    it.each`
      description          | instanceType        | shouldBeCalled
      ${'Sets up'}         | ${EDITOR_TYPE_CODE} | ${true}
      ${'Does not set up'} | ${EDITOR_TYPE_DIFF} | ${false}
    `(
      '$description the line linking for $instanceType instance',
      ({ instanceType, shouldBeCalled }) => {
        const instance = createInstance({
          getEditorType: jest.fn().mockReturnValue(instanceType),
          onMouseMove: jest.fn(),
          onMouseDown: jest.fn(),
        });
        const spy = jest.spyOn(SourceEditorExtension, 'setupLineLinking');

        instance.use({ definition: SourceEditorExtension });
        if (shouldBeCalled) {
          expect(spy).toHaveBeenCalledWith(instance);
        } else {
          expect(spy).not.toHaveBeenCalled();
        }
      },
    );
  });

  describe('highlightLines', () => {
    const revealSpy = jest.fn();
    const decorationsSpy = jest.fn();
    const instance = createInstance({
      revealLineInCenter: revealSpy,
      deltaDecorations: decorationsSpy,
    });
    instance.use({ definition: SourceEditorExtension });
    const defaultDecorationOptions = {
      isWholeLine: true,
      className: 'active-line-text',
    };

    useFakeRequestAnimationFrame();

    beforeEach(() => {
      setWindowLocation('https://localhost');
    });

    it.each`
      desc                                                  | hash         | bounds          | shouldReveal | expectedRange
      ${'properly decorates a single line'}                 | ${'#L10'}    | ${undefined}    | ${true}      | ${[10, 1, 10, 1]}
      ${'properly decorates multiple lines'}                | ${'#L7-42'}  | ${undefined}    | ${true}      | ${[7, 1, 42, 1]}
      ${'correctly highlights if lines are reversed'}       | ${'#L42-7'}  | ${undefined}    | ${true}      | ${[7, 1, 42, 1]}
      ${'highlights one line if start/end are the same'}    | ${'#L7-7'}   | ${undefined}    | ${true}      | ${[7, 1, 7, 1]}
      ${'does not highlight if there is no hash'}           | ${''}        | ${undefined}    | ${false}     | ${null}
      ${'does not highlight if the hash is undefined'}      | ${undefined} | ${undefined}    | ${false}     | ${null}
      ${'does not highlight if hash is incomplete 1'}       | ${'#L'}      | ${undefined}    | ${false}     | ${null}
      ${'does not highlight if hash is incomplete 2'}       | ${'#L-'}     | ${undefined}    | ${false}     | ${null}
      ${'highlights lines if bounds are passed'}            | ${undefined} | ${[17, 42]}     | ${true}      | ${[17, 1, 42, 1]}
      ${'highlights one line if bounds has a single value'} | ${undefined} | ${[17]}         | ${true}      | ${[17, 1, 17, 1]}
      ${'does not highlight if bounds is invalid'}          | ${undefined} | ${[Number.NaN]} | ${false}     | ${null}
      ${'uses bounds if both hash and bounds exist'}        | ${'#L7-42'}  | ${[3, 5]}       | ${true}      | ${[3, 1, 5, 1]}
    `('$desc', ({ hash, bounds, shouldReveal, expectedRange } = {}) => {
      window.location.hash = hash;
      instance.highlightLines(bounds);
      if (!shouldReveal) {
        expect(revealSpy).not.toHaveBeenCalled();
        expect(decorationsSpy).not.toHaveBeenCalled();
      } else {
        expect(revealSpy).toHaveBeenCalledWith(expectedRange[0]);
        expect(decorationsSpy).toHaveBeenCalledWith(
          [],
          [
            {
              range: new Range(...expectedRange),
              options: defaultDecorationOptions,
            },
          ],
        );
      }
    });

    it('stores the line decorations on the instance', () => {
      decorationsSpy.mockReturnValue('foo');
      window.location.hash = '#L10';
      expect(instance.lineDecorations).toBeUndefined();
      instance.highlightLines();
      expect(instance.lineDecorations).toBe('foo');
    });

    it('replaces existing line highlights', () => {
      const oldLineDecorations = [
        {
          range: new Range(1, 1, 20, 1),
          options: { isWholeLine: true, className: 'active-line-text' },
        },
      ];
      const newLineDecorations = [
        {
          range: new Range(7, 1, 10, 1),
          options: { isWholeLine: true, className: 'active-line-text' },
        },
      ];
      instance.lineDecorations = oldLineDecorations;
      instance.highlightLines([7, 10]);
      expect(decorationsSpy).toHaveBeenCalledWith(oldLineDecorations, newLineDecorations);
    });
  });

  describe('removeHighlights', () => {
    const decorationsSpy = jest.fn();
    const lineDecorations = [
      {
        range: new Range(1, 1, 20, 1),
        options: { isWholeLine: true, className: 'active-line-text' },
      },
    ];
    let instance;

    beforeEach(() => {
      instance = createInstance({
        deltaDecorations: decorationsSpy,
        lineDecorations,
      });
      instance.use({ definition: SourceEditorExtension });
    });

    it('removes all existing decorations', () => {
      instance.removeHighlights();
      expect(decorationsSpy).toHaveBeenCalledWith(lineDecorations, []);
    });
  });

  describe('setupLineLinking', () => {
    const instance = {
      onMouseMove: jest.fn(),
      onMouseDown: jest.fn(),
      deltaDecorations: jest.fn(),
      lineDecorations: 'foo',
    };

    beforeEach(() => {
      SourceEditorExtension.onMouseMoveHandler(event); // generate the anchor
    });

    it.each`
      desc             | spy
      ${'onMouseMove'} | ${instance.onMouseMove}
      ${'onMouseDown'} | ${instance.onMouseDown}
    `('sets up the $desc listener', ({ spy } = {}) => {
      SourceEditorExtension.setupLineLinking(instance);
      expect(spy).toHaveBeenCalled();
    });

    it.each`
      desc                                                                                | eventTrigger                                   | shouldRemove
      ${'does not remove the line decorations if the event is triggered on a wrong node'} | ${null}                                        | ${false}
      ${'removes existing line decorations when clicking a line number'}                  | ${`.${EXTENSION_BASE_LINE_LINK_ANCHOR_CLASS}`} | ${true}
    `('$desc', ({ eventTrigger, shouldRemove } = {}) => {
      event = generateEventMock({ el: eventTrigger ? document.querySelector(eventTrigger) : null });
      instance.onMouseDown.mockImplementation((fn) => {
        fn(event);
      });

      SourceEditorExtension.setupLineLinking(instance);
      if (shouldRemove) {
        expect(instance.deltaDecorations).toHaveBeenCalledWith(instance.lineDecorations, []);
      } else {
        expect(instance.deltaDecorations).not.toHaveBeenCalled();
      }
    });
  });

  describe('onMouseMoveHandler', () => {
    it('stops propagation for contextmenu event on the generated anchor', () => {
      SourceEditorExtension.onMouseMoveHandler(event);
      const anchor = findLine(defaultLine).querySelector('a');
      const contextMenuEvent = new Event('contextmenu');

      jest.spyOn(contextMenuEvent, 'stopPropagation');
      anchor.dispatchEvent(contextMenuEvent);

      expect(contextMenuEvent.stopPropagation).toHaveBeenCalled();
    });

    it('creates an anchor if it does not exist yet', () => {
      expect(findLine(defaultLine).querySelector('a')).toBe(null);
      SourceEditorExtension.onMouseMoveHandler(event);
      expect(findLine(defaultLine).querySelector('a')).not.toBe(null);
    });

    it('does not create a new anchor if it exists', () => {
      SourceEditorExtension.onMouseMoveHandler(event);
      expect(findLine(defaultLine).querySelector('a')).not.toBe(null);

      SourceEditorExtension.createAnchor = jest.fn();
      SourceEditorExtension.onMouseMoveHandler(event);
      expect(SourceEditorExtension.createAnchor).not.toHaveBeenCalled();
      expect(findLine(defaultLine).querySelectorAll('a')).toHaveLength(1);
    });

    it('does not create a link if the event is triggered on a wrong node', () => {
      setFixtures('<div class="wrong-class">3</div>');
      SourceEditorExtension.createAnchor = jest.fn();
      const wrongEvent = generateEventMock({ el: document.querySelector('.wrong-class') });

      SourceEditorExtension.onMouseMoveHandler(wrongEvent);
      expect(SourceEditorExtension.createAnchor).not.toHaveBeenCalled();
    });
  });
});
