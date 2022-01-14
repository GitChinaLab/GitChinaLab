import { GlAvatar, GlSprintf, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import component from '~/vue_shared/components/registry/title_area.vue';

describe('title area', () => {
  let wrapper;

  const DYNAMIC_SLOT = 'metadata-dynamic-slot';

  const findSubHeaderSlot = () => wrapper.findByTestId('sub-header');
  const findRightActionsSlot = () => wrapper.findByTestId('right-actions');
  const findMetadataSlot = (name) => wrapper.findByTestId(name);
  const findTitle = () => wrapper.findByTestId('title');
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findInfoMessages = () => wrapper.findAllByTestId('info-message');
  const findDynamicSlot = () => wrapper.findByTestId(DYNAMIC_SLOT);
  const findSlotOrderElements = () => wrapper.findAll('[slot-test]');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const mountComponent = ({ propsData = { title: 'foo' }, slots } = {}) => {
    wrapper = shallowMountExtended(component, {
      propsData,
      stubs: { GlSprintf },
      slots: {
        'sub-header': '<div data-testid="sub-header" />',
        'right-actions': '<div data-testid="right-actions" />',
        ...slots,
      },
    });
  };

  const generateSlotMocks = (names) =>
    names.reduce((acc, current) => {
      acc[current] = `<div data-testid="${current}" />`;
      return acc;
    }, {});

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('title', () => {
    it('if slot is not present defaults to prop', () => {
      mountComponent();

      expect(findTitle().text()).toBe('foo');
    });

    it('if slot is present uses slot', () => {
      mountComponent({
        slots: {
          title: 'slot_title',
        },
      });
      expect(findTitle().text()).toBe('slot_title');
    });
  });

  describe('avatar', () => {
    it('is shown if avatar props exist', () => {
      mountComponent({ propsData: { title: 'foo', avatar: 'baz' } });

      expect(findAvatar().props('src')).toBe('baz');
    });

    it('is hidden if avatar props does not exist', () => {
      mountComponent();

      expect(findAvatar().exists()).toBe(false);
    });
  });

  describe.each`
    slotName           | finderFunction
    ${'sub-header'}    | ${findSubHeaderSlot}
    ${'right-actions'} | ${findRightActionsSlot}
  `('$slotName slot', ({ finderFunction, slotName }) => {
    it('exist when the slot is filled', () => {
      mountComponent();

      expect(finderFunction().exists()).toBe(true);
    });

    it('does not exist when the slot is empty', () => {
      mountComponent({ slots: { [slotName]: '' } });

      expect(finderFunction().exists()).toBe(false);
    });
  });

  describe.each`
    slotNames
    ${['metadata-foo']}
    ${['metadata-foo', 'metadata-bar']}
    ${['metadata-foo', 'metadata-bar', 'metadata-baz']}
  `('$slotNames metadata slots', ({ slotNames }) => {
    const slots = generateSlotMocks(slotNames);

    it('exist when the slot is present', async () => {
      mountComponent({ slots });

      await nextTick();
      slotNames.forEach((name) => {
        expect(findMetadataSlot(name).exists()).toBe(true);
      });
    });

    it('is/are hidden when metadata-loading is true', async () => {
      mountComponent({ slots, propsData: { title: 'foo', metadataLoading: true } });

      await nextTick();
      slotNames.forEach((name) => {
        expect(findMetadataSlot(name).exists()).toBe(false);
      });
    });
  });

  describe('metadata skeleton loader', () => {
    const slots = generateSlotMocks(['metadata-foo']);

    it('is hidden when metadata loading is false', async () => {
      mountComponent({ slots });

      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('is shown when metadata loading is true', async () => {
      mountComponent({ propsData: { metadataLoading: true }, slots });

      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('dynamic slots', () => {
    const createDynamicSlot = () => {
      return wrapper.vm.$createElement('div', {
        attrs: {
          'data-testid': DYNAMIC_SLOT,
          'slot-test': true,
        },
      });
    };

    it('shows dynamic slots', async () => {
      mountComponent();
      // we manually add a new slot to simulate dynamic slots being evaluated after the initial mount
      wrapper.vm.$slots[DYNAMIC_SLOT] = createDynamicSlot();

      // updating the slots like we do on line 141 does not cause the updated lifecycle-hook to be triggered
      wrapper.vm.$forceUpdate();
      await nextTick();

      expect(findDynamicSlot().exists()).toBe(true);
    });

    it('preserve the order of the slots', async () => {
      mountComponent({
        slots: {
          'metadata-foo': '<div slot-test data-testid="metadata-foo"></div>',
        },
      });

      // rewrite slot putting dynamic slot as first
      wrapper.vm.$slots = {
        'metadata-dynamic-slot': createDynamicSlot(),
        'metadata-foo': wrapper.vm.$slots['metadata-foo'],
      };

      // updating the slots like we do on line 159 does not cause the updated lifecycle-hook to be triggered
      wrapper.vm.$forceUpdate();
      await nextTick();

      expect(findSlotOrderElements().at(0).attributes('data-testid')).toBe(DYNAMIC_SLOT);
      expect(findSlotOrderElements().at(1).attributes('data-testid')).toBe('metadata-foo');
    });
  });

  describe('info-messages', () => {
    it('shows a message when the props contains one', () => {
      mountComponent({ propsData: { infoMessages: [{ text: 'foo foo bar bar' }] } });

      const messages = findInfoMessages();
      expect(messages).toHaveLength(1);
      expect(messages.at(0).text()).toBe('foo foo bar bar');
    });

    it('shows a link when the props contains one', () => {
      mountComponent({
        propsData: {
          infoMessages: [{ text: 'foo %{docLinkStart}link%{docLinkEnd}', link: 'bar' }],
        },
      });

      const message = findInfoMessages().at(0);

      expect(message.find(GlLink).attributes('href')).toBe('bar');
      expect(message.text()).toBe('foo link');
    });

    it('multiple messages generates multiple spans', () => {
      mountComponent({ propsData: { infoMessages: [{ text: 'foo' }, { text: 'bar' }] } });

      expect(findInfoMessages()).toHaveLength(2);
    });
  });
});
