import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PinComponent from '~/environments/components/environment_pin.vue';
import eventHub from '~/environments/event_hub';

describe('Pin Component', () => {
  let wrapper;

  const factory = (options = {}) => {
    // This destroys any wrappers created before a nested call to factory reassigns it
    if (wrapper && wrapper.destroy) {
      wrapper.destroy();
    }
    wrapper = shallowMount(PinComponent, {
      ...options,
    });
  };

  const autoStopUrl = '/root/auto-stop-env-test/-/environments/38/cancel_auto_stop';

  beforeEach(() => {
    factory({
      propsData: {
        autoStopUrl,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render the component with descriptive text', () => {
    expect(wrapper.text()).toBe('Prevent auto-stopping');
  });

  it('should emit onPinClick when clicked', () => {
    const eventHubSpy = jest.spyOn(eventHub, '$emit');
    const item = wrapper.find(GlDropdownItem);

    item.vm.$emit('click');

    expect(eventHubSpy).toHaveBeenCalledWith('cancelAutoStop', autoStopUrl);
  });
});
