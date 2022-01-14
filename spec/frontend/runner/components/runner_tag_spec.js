import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import RunnerTag from '~/runner/components/runner_tag.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

const mockTag = 'tag1';

describe('RunnerTag', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const getTooltipValue = () => getBinding(findBadge().element, 'gl-tooltip').value;

  const setDimensions = ({ scrollWidth, offsetWidth }) => {
    jest.spyOn(findBadge().element, 'scrollWidth', 'get').mockReturnValue(scrollWidth);
    jest.spyOn(findBadge().element, 'offsetWidth', 'get').mockReturnValue(offsetWidth);

    // Mock trigger resize
    getBinding(findBadge().element, 'gl-resize-observer').value();
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerTag, {
      propsData: {
        tag: mockTag,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
        GlResizeObserver: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays tag text', () => {
    expect(wrapper.text()).toBe(mockTag);
  });

  it('Displays tags with correct style', () => {
    expect(findBadge().props()).toMatchObject({
      size: 'sm',
      variant: 'neutral',
    });
  });

  it('Displays tags with md size', () => {
    createComponent({
      props: { size: 'md' },
    });

    expect(findBadge().props('size')).toBe('md');
  });

  it.each`
    case                    | scrollWidth | offsetWidth | expectedTooltip
    ${'overflowing'}        | ${110}      | ${100}      | ${mockTag}
    ${'not overflowing'}    | ${90}       | ${100}      | ${''}
    ${'almost overflowing'} | ${100}      | ${100}      | ${''}
  `(
    'Sets "$expectedTooltip" as tooltip when $case',
    async ({ scrollWidth, offsetWidth, expectedTooltip }) => {
      setDimensions({ scrollWidth, offsetWidth });
      await nextTick();

      expect(getTooltipValue()).toBe(expectedTooltip);
    },
  );
});
