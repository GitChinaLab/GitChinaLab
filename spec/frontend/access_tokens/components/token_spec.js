import { mountExtended } from 'helpers/vue_test_utils_helper';

import Token from '~/access_tokens/components/token.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';

describe('Token', () => {
  let wrapper;

  const defaultPropsData = {
    token: 'az4a2l5f8ssa0zvdfbhidbzlx',
    inputId: 'feed_token',
    inputLabel: 'Feed token',
    copyButtonTitle: 'Copy feed token',
  };

  const defaultSlots = {
    title: 'Feed token title',
    description: 'Feed token description',
    'input-description': 'Feed token input description',
  };

  const createComponent = () => {
    wrapper = mountExtended(Token, { propsData: defaultPropsData, slots: defaultSlots });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders title slot', () => {
    createComponent();

    expect(wrapper.findByText(defaultSlots.title, { selector: 'h4' }).exists()).toBe(true);
  });

  it('renders description slot', () => {
    createComponent();

    expect(wrapper.findByText(defaultSlots.description).exists()).toBe(true);
  });

  it('renders input description slot', () => {
    createComponent();

    expect(wrapper.findByText(defaultSlots['input-description']).exists()).toBe(true);
  });

  it('correctly passes props to `InputCopyToggleVisibility` component', () => {
    createComponent();

    const inputCopyToggleVisibilityComponent = wrapper.findComponent(InputCopyToggleVisibility);

    expect(inputCopyToggleVisibilityComponent.props()).toMatchObject({
      formInputGroupProps: {
        id: defaultPropsData.inputId,
      },
      value: defaultPropsData.token,
      copyButtonTitle: defaultPropsData.copyButtonTitle,
    });
    expect(inputCopyToggleVisibilityComponent.attributes()).toMatchObject({
      label: defaultPropsData.inputLabel,
      'label-for': defaultPropsData.inputId,
    });
  });
});
