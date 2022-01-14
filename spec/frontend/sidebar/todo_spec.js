import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import SidebarTodos from '~/sidebar/components/todo_toggle/todo.vue';

const defaultProps = {
  issuableId: 1,
  issuableType: 'epic',
};

describe('SidebarTodo', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SidebarTodos, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    state    | classes
    ${false} | ${['gl-button', 'btn', 'btn-default', 'btn-todo', 'issuable-header-btn', 'float-right']}
    ${true}  | ${['btn-blank', 'btn-todo', 'sidebar-collapsed-icon', 'js-dont-change-state']}
  `('returns todo button classes for when `collapsed` prop is `$state`', ({ state, classes }) => {
    createComponent({ collapsed: state });
    expect(wrapper.find('button').classes()).toStrictEqual(classes);
  });

  it.each`
    isTodo   | iconClass        | label             | icon
    ${false} | ${''}            | ${'Add a to do'}  | ${'todo-add'}
    ${true}  | ${'todo-undone'} | ${'Mark as done'} | ${'todo-done'}
  `(
    'renders proper button when `isTodo` prop is `$isTodo`',
    ({ isTodo, iconClass, label, icon }) => {
      createComponent({ isTodo });

      expect(wrapper.find(GlIcon).classes().join(' ')).toStrictEqual(iconClass);
      expect(wrapper.find(GlIcon).props('name')).toStrictEqual(icon);
      expect(wrapper.find('button').text()).toBe(label);
    },
  );

  describe('template', () => {
    it('emits `toggleTodo` event when clicked on button', () => {
      createComponent();
      wrapper.find('button').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().toggleTodo).toBeTruthy();
      });
    });

    it('renders component container element with proper data attributes', () => {
      createComponent({
        issuableId: 1,
        issuableType: 'epic',
      });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders button label element when `collapsed` prop is `false`', () => {
      createComponent({ collapsed: false });

      expect(wrapper.find('span.issuable-todo-inner').text()).toBe('Mark as done');
    });

    it('renders button icon when `collapsed` prop is `true`', () => {
      createComponent({ collapsed: true });

      expect(wrapper.find(GlIcon).props('name')).toBe('todo-done');
    });

    it('renders loading icon when `isActionActive` prop is true', () => {
      createComponent({ isActionActive: true });

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('hides button icon when `isActionActive` prop is true', () => {
      createComponent({ collapsed: true, isActionActive: true });

      expect(wrapper.find(GlIcon).isVisible()).toBe(false);
    });
  });
});
