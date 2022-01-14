import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { each } from 'lodash';
import { trimText } from 'helpers/text_helper';
import { TEST_HOST } from 'spec/test_constants';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

describe('User Avatar Link Component', () => {
  let wrapper;

  const defaultProps = {
    linkHref: `${TEST_HOST}/myavatarurl.com`,
    imgSize: 99,
    imgSrc: `${TEST_HOST}/myavatarurl.com`,
    imgAlt: 'mydisplayname',
    imgCssClasses: 'myextraavatarclass',
    tooltipText: 'tooltip text',
    tooltipPlacement: 'bottom',
    username: 'username',
  };

  const createWrapper = (props) => {
    wrapper = shallowMount(UserAvatarLink, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should have user-avatar-image registered as child component', () => {
    expect(wrapper.vm.$options.components.userAvatarImage).toBeDefined();
  });

  it('user-avatar-link should have user-avatar-image as child component', () => {
    expect(wrapper.find(UserAvatarImage).exists()).toBe(true);
  });

  it('should render GlLink as a child element', () => {
    const link = wrapper.find(GlLink);

    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe(defaultProps.linkHref);
  });

  it('should return necessary props as defined', () => {
    each(defaultProps, (val, key) => {
      expect(wrapper.vm[key]).toBeDefined();
    });
  });

  describe('no username', () => {
    beforeEach(() => {
      createWrapper({
        username: '',
      });
    });

    it('should only render image tag in link', () => {
      const childElements = wrapper.vm.$el.childNodes;

      expect(wrapper.find('img')).not.toBe('null');

      // Vue will render the hidden component as <!---->
      expect(childElements[1].tagName).toBeUndefined();
    });

    it('should render avatar image tooltip', () => {
      expect(wrapper.vm.shouldShowUsername).toBe(false);
      expect(wrapper.vm.avatarTooltipText).toEqual(defaultProps.tooltipText);
    });
  });

  describe('username', () => {
    it('should not render avatar image tooltip', () => {
      expect(wrapper.find('.js-user-avatar-image-tooltip').exists()).toBe(false);
    });

    it('should render username prop in <span>', () => {
      expect(trimText(wrapper.find('.js-user-avatar-link-username').text())).toEqual(
        defaultProps.username,
      );
    });

    it('should render text tooltip for <span>', () => {
      expect(wrapper.find('.js-user-avatar-link-username').attributes('title')).toEqual(
        defaultProps.tooltipText,
      );
    });

    it('should render text tooltip placement for <span>', () => {
      expect(wrapper.find('.js-user-avatar-link-username').attributes('tooltip-placement')).toBe(
        defaultProps.tooltipPlacement,
      );
    });
  });

  describe('lazy', () => {
    it('passes lazy prop to avatar image', () => {
      createWrapper({
        username: '',
        lazy: true,
      });

      expect(wrapper.find(UserAvatarImage).props('lazy')).toBe(true);
    });
  });
});
