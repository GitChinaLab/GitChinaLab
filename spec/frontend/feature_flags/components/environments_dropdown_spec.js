import { GlLoadingIcon, GlButton, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import EnvironmentsDropdown from '~/feature_flags/components/environments_dropdown.vue';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';

describe('Feature flags > Environments dropdown ', () => {
  let wrapper;
  let mock;
  const results = ['production', 'staging'];
  const factory = (props) => {
    wrapper = shallowMount(EnvironmentsDropdown, {
      propsData: {
        ...props,
      },
      provide: {
        environmentsEndpoint: `${TEST_HOST}/environments.json'`,
      },
    });
  };

  const findEnvironmentSearchInput = () => wrapper.find(GlSearchBoxByType);
  const findDropdownMenu = () => wrapper.find('.dropdown-menu');

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  describe('without value', () => {
    it('renders the placeholder', () => {
      factory();
      expect(findEnvironmentSearchInput().vm.$attrs.placeholder).toBe('Search an environment spec');
    });
  });

  describe('with value', () => {
    it('sets filter to equal the value', () => {
      factory({ value: 'production' });
      expect(findEnvironmentSearchInput().props('value')).toBe('production');
    });
  });

  describe('on focus', () => {
    it('sets results with the received data', async () => {
      mock.onGet(`${TEST_HOST}/environments.json'`).replyOnce(httpStatusCodes.OK, results);
      factory();
      findEnvironmentSearchInput().vm.$emit('focus');
      await waitForPromises();
      await wrapper.vm.$nextTick();
      expect(wrapper.find('.dropdown-content > ul').exists()).toBe(true);
      expect(wrapper.findAll('.dropdown-content > ul > li').exists()).toBe(true);
    });
  });

  describe('on keyup', () => {
    it('sets results with the received data', async () => {
      mock.onGet(`${TEST_HOST}/environments.json'`).replyOnce(httpStatusCodes.OK, results);
      factory();
      findEnvironmentSearchInput().vm.$emit('keyup');
      await waitForPromises();
      await wrapper.vm.$nextTick();
      expect(wrapper.find('.dropdown-content > ul').exists()).toBe(true);
      expect(wrapper.findAll('.dropdown-content > ul > li').exists()).toBe(true);
    });
  });

  describe('on input change', () => {
    describe('on success', () => {
      beforeEach(async () => {
        mock.onGet(`${TEST_HOST}/environments.json'`).replyOnce(httpStatusCodes.OK, results);
        factory();
        findEnvironmentSearchInput().vm.$emit('focus');
        findEnvironmentSearchInput().vm.$emit('input', 'production');
        await waitForPromises();
        await wrapper.vm.$nextTick();
      });

      it('sets filter value', () => {
        expect(findEnvironmentSearchInput().props('value')).toBe('production');
      });

      describe('with received data', () => {
        it('sets is loading to false', () => {
          expect(wrapper.vm.isLoading).toBe(false);
          expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
        });

        it('shows the suggestions', () => {
          expect(findDropdownMenu().exists()).toBe(true);
        });

        it('emits event when a suggestion is clicked', async () => {
          const button = wrapper
            .findAll(GlButton)
            .filter((b) => b.text() === 'production')
            .at(0);
          button.vm.$emit('click');
          await wrapper.vm.$nextTick();
          expect(wrapper.emitted('selectEnvironment')).toEqual([['production']]);
        });
      });

      describe('on click clear button', () => {
        beforeEach(async () => {
          wrapper.find(GlButton).vm.$emit('click');
          await wrapper.vm.$nextTick();
        });

        it('resets filter value', () => {
          expect(findEnvironmentSearchInput().props('value')).toBe('');
        });

        it('closes list of suggestions', () => {
          expect(wrapper.vm.showSuggestions).toBe(false);
        });
      });
    });
  });

  describe('on click create button', () => {
    beforeEach(async () => {
      mock.onGet(`${TEST_HOST}/environments.json'`).replyOnce(httpStatusCodes.OK, []);
      factory();
      findEnvironmentSearchInput().vm.$emit('focus');
      findEnvironmentSearchInput().vm.$emit('input', 'production');
      await waitForPromises();
      await wrapper.vm.$nextTick();
    });

    it('emits create event', async () => {
      wrapper.findAll(GlButton).at(0).vm.$emit('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted('createClicked')).toEqual([['production']]);
    });
  });
});
