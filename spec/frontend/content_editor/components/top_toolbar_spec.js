import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import {
  TOOLBAR_CONTROL_TRACKING_ACTION,
  CONTENT_EDITOR_TRACKING_LABEL,
} from '~/content_editor/constants';

describe('content_editor/components/top_toolbar', () => {
  let wrapper;
  let trackingSpy;

  const buildWrapper = () => {
    wrapper = shallowMountExtended(TopToolbar);
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    testId               | controlProps
    ${'bold'}            | ${{ contentType: 'bold', iconName: 'bold', label: 'Bold text', editorCommand: 'toggleBold' }}
    ${'italic'}          | ${{ contentType: 'italic', iconName: 'italic', label: 'Italic text', editorCommand: 'toggleItalic' }}
    ${'strike'}          | ${{ contentType: 'strike', iconName: 'strikethrough', label: 'Strikethrough', editorCommand: 'toggleStrike' }}
    ${'code'}            | ${{ contentType: 'code', iconName: 'code', label: 'Code', editorCommand: 'toggleCode' }}
    ${'blockquote'}      | ${{ contentType: 'blockquote', iconName: 'quote', label: 'Insert a quote', editorCommand: 'toggleBlockquote' }}
    ${'bullet-list'}     | ${{ contentType: 'bulletList', iconName: 'list-bulleted', label: 'Add a bullet list', editorCommand: 'toggleBulletList' }}
    ${'ordered-list'}    | ${{ contentType: 'orderedList', iconName: 'list-numbered', label: 'Add a numbered list', editorCommand: 'toggleOrderedList' }}
    ${'details'}         | ${{ contentType: 'details', iconName: 'details-block', label: 'Add a collapsible section', editorCommand: 'toggleDetails' }}
    ${'horizontal-rule'} | ${{ contentType: 'horizontalRule', iconName: 'dash', label: 'Add a horizontal rule', editorCommand: 'setHorizontalRule' }}
    ${'code-block'}      | ${{ contentType: 'codeBlock', iconName: 'doc-code', label: 'Insert a code block', editorCommand: 'toggleCodeBlock' }}
    ${'text-styles'}     | ${{}}
    ${'link'}            | ${{}}
    ${'image'}           | ${{}}
  `('given a $testId toolbar control', ({ testId, controlProps }) => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders the toolbar control with the provided properties', () => {
      expect(wrapper.findByTestId(testId).exists()).toBe(true);

      Object.keys(controlProps).forEach((propName) => {
        expect(wrapper.findByTestId(testId).props(propName)).toBe(controlProps[propName]);
      });
    });

    it('tracks the execution of toolbar controls', () => {
      const eventData = { contentType: 'blockquote', value: 1 };
      const { contentType, value } = eventData;

      wrapper.findByTestId(testId).vm.$emit('execute', eventData);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, TOOLBAR_CONTROL_TRACKING_ACTION, {
        label: CONTENT_EDITOR_TRACKING_LABEL,
        property: contentType,
        value,
      });
    });
  });
});
