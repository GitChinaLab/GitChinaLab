import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ResizablePanel from '~/ide/components/resizable_panel.vue';
import { SIDE_LEFT, SIDE_RIGHT } from '~/ide/constants';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';

const TEST_WIDTH = 500;
const TEST_MIN_WIDTH = 400;

describe('~/ide/components/resizable_panel', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;
  let store;

  beforeEach(() => {
    store = new Vuex.Store({});
    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ResizablePanel, {
      propsData: {
        initialWidth: TEST_WIDTH,
        minSize: TEST_MIN_WIDTH,
        side: SIDE_LEFT,
        ...props,
      },
      store,
      localVue,
    });
  };
  const findResizer = () => wrapper.find(PanelResizer);
  const findInlineStyle = () => wrapper.element.style.cssText;
  const createInlineStyle = (width) => `width: ${width}px;`;

  describe.each`
    props                                    | showResizer | resizerSide   | expectedStyle
    ${{ resizable: true, side: SIDE_LEFT }}  | ${true}     | ${SIDE_RIGHT} | ${createInlineStyle(TEST_WIDTH)}
    ${{ resizable: true, side: SIDE_RIGHT }} | ${true}     | ${SIDE_LEFT}  | ${createInlineStyle(TEST_WIDTH)}
    ${{ resizable: false, side: SIDE_LEFT }} | ${false}    | ${SIDE_RIGHT} | ${''}
  `('with props $props', ({ props, showResizer, resizerSide, expectedStyle }) => {
    beforeEach(() => {
      createComponent(props);
    });

    it(`show resizer is ${showResizer}`, () => {
      const expectedDisplay = showResizer ? '' : 'none';
      const resizer = findResizer();

      expect(resizer.exists()).toBe(true);
      expect(resizer.element.style.display).toBe(expectedDisplay);
    });

    it(`resizer side is '${resizerSide}'`, () => {
      const resizer = findResizer();

      expect(resizer.props('side')).toBe(resizerSide);
    });

    it(`has style '${expectedStyle}'`, () => {
      expect(findInlineStyle()).toBe(expectedStyle);
    });
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not dispatch anything', () => {
      expect(store.dispatch).not.toHaveBeenCalled();
    });

    it.each`
      event             | dispatchArgs
      ${'resize-start'} | ${['setResizingStatus', true]}
      ${'resize-end'}   | ${['setResizingStatus', false]}
    `('when resizer emits $event, dispatch $dispatchArgs', ({ event, dispatchArgs }) => {
      const resizer = findResizer();

      resizer.vm.$emit(event);

      expect(store.dispatch).toHaveBeenCalledWith(...dispatchArgs);
    });

    it('renders resizer', () => {
      const resizer = findResizer();

      expect(resizer.props()).toMatchObject({
        maxSize: window.innerWidth / 2,
        minSize: TEST_MIN_WIDTH,
        startSize: TEST_WIDTH,
      });
    });

    it('when resizer emits update:size, changes inline width', () => {
      const newSize = TEST_WIDTH - 100;
      const resizer = findResizer();

      resizer.vm.$emit('update:size', newSize);

      return wrapper.vm.$nextTick().then(() => {
        expect(findInlineStyle()).toBe(createInlineStyle(newSize));
      });
    });
  });
});
