import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ImportActionsCell from '~/import_entities/import_groups/components/import_actions_cell.vue';

describe('import actions cell', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(ImportActionsCell, {
      propsData: {
        isFinished: false,
        isAvailableForImport: false,
        isInvalid: false,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when group is available for import', () => {
    beforeEach(() => {
      createComponent({ isAvailableForImport: true });
    });

    it('renders import button', () => {
      const button = wrapper.findComponent(GlButton);
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Import');
    });

    it('does not render icon with a hint', () => {
      expect(wrapper.findComponent(GlIcon).exists()).toBe(false);
    });
  });

  describe('when group is finished', () => {
    beforeEach(() => {
      createComponent({ isAvailableForImport: true, isFinished: true });
    });

    it('renders re-import button', () => {
      const button = wrapper.findComponent(GlButton);
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Re-import');
    });

    it('renders icon with a hint', () => {
      const icon = wrapper.findComponent(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.attributes().title).toBe(
        'Re-import creates a new group. It does not sync with the existing group.',
      );
    });
  });

  it('does not render import button when group is not available for import', () => {
    createComponent({ isAvailableForImport: false });

    const button = wrapper.findComponent(GlButton);
    expect(button.exists()).toBe(false);
  });

  it('renders import button as disabled when group is invalid', () => {
    createComponent({ isInvalid: true, isAvailableForImport: true });

    const button = wrapper.findComponent(GlButton);
    expect(button.props().disabled).toBe(true);
  });

  it('emits import-group event when import button is clicked', () => {
    createComponent({ isAvailableForImport: true });

    const button = wrapper.findComponent(GlButton);
    button.vm.$emit('click');

    expect(wrapper.emitted('import-group')).toHaveLength(1);
  });
});
