import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import Api from '~/api';
import Form from '~/feature_flags/components/form.vue';
import Strategy from '~/feature_flags/components/strategy.vue';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
} from '~/feature_flags/constants';
import RelatedIssuesRoot from '~/related_issues/components/related_issues_root.vue';
import { featureFlag, userList, allUsersStrategy } from '../mock_data';

jest.mock('~/api.js');

describe('feature flag form', () => {
  let wrapper;
  const requiredProps = {
    cancelPath: 'feature_flags',
    submitText: 'Create',
  };

  const requiredInjections = {
    environmentsEndpoint: '/environments.json',
    projectId: '1',
  };

  const factory = (props = {}, provide = {}) => {
    wrapper = extendedWrapper(
      shallowMount(Form, {
        propsData: { ...requiredProps, ...props },
        provide: {
          ...requiredInjections,
          ...provide,
        },
      }),
    );
  };

  beforeEach(() => {
    Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [] });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render provided submitText', () => {
    factory(requiredProps);

    expect(wrapper.find('.js-ff-submit').text()).toEqual(requiredProps.submitText);
  });

  it('should render provided cancelPath', () => {
    factory(requiredProps);

    expect(wrapper.find('.js-ff-cancel').attributes('href')).toEqual(requiredProps.cancelPath);
  });

  it('does not render the related issues widget without the featureFlagIssuesEndpoint', () => {
    factory(requiredProps);

    expect(wrapper.find(RelatedIssuesRoot).exists()).toBe(false);
  });

  it('renders the related issues widget when the featureFlagIssuesEndpoint is provided', () => {
    factory(
      {},
      {
        ...requiredInjections,
        featureFlagIssuesEndpoint: '/some/endpoint',
      },
    );

    expect(wrapper.find(RelatedIssuesRoot).exists()).toBe(true);
  });

  describe('without provided data', () => {
    beforeEach(() => {
      factory(requiredProps);
    });

    it('should render name input text', () => {
      expect(wrapper.find('#feature-flag-name').exists()).toBe(true);
    });

    it('should render description textarea', () => {
      expect(wrapper.find('#feature-flag-description').exists()).toBe(true);
    });
  });

  describe('with strategies', () => {
    beforeEach(() => {
      Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [userList] });
      factory({
        ...requiredProps,
        name: featureFlag.name,
        description: featureFlag.description,
        active: true,
        strategies: [
          {
            type: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
            parameters: { percentage: '30' },
            scopes: [],
          },
          {
            type: ROLLOUT_STRATEGY_ALL_USERS,
            parameters: {},
            scopes: [{ environment_scope: 'review/*' }],
          },
        ],
      });
    });

    it('should show the strategy component', () => {
      const strategy = wrapper.find(Strategy);
      expect(strategy.exists()).toBe(true);
      expect(strategy.props('strategy')).toEqual({
        type: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
        parameters: { percentage: '30' },
        scopes: [],
      });
    });

    it('should show one strategy component per strategy', () => {
      expect(wrapper.findAll(Strategy)).toHaveLength(2);
    });

    it('adds an all users strategy when clicking the Add button', () => {
      wrapper.find(GlButton).vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        const strategies = wrapper.findAll(Strategy);

        expect(strategies).toHaveLength(3);
        expect(strategies.at(2).props('strategy')).toEqual(allUsersStrategy);
      });
    });

    it('should remove a strategy on delete', () => {
      const strategy = {
        type: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
        parameters: { percentage: '30' },
        scopes: [],
      };
      wrapper.find(Strategy).vm.$emit('delete');
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.findAll(Strategy)).toHaveLength(1);
        expect(wrapper.find(Strategy).props('strategy')).not.toEqual(strategy);
      });
    });
  });
});
