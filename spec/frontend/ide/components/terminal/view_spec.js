import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import TerminalEmptyState from '~/ide/components/terminal/empty_state.vue';
import TerminalSession from '~/ide/components/terminal/session.vue';
import TerminalView from '~/ide/components/terminal/view.vue';

const TEST_HELP_PATH = `${TEST_HOST}/help`;
const TEST_SVG_PATH = `${TEST_HOST}/illustration.svg`;

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IDE TerminalView', () => {
  let state;
  let actions;
  let getters;
  let wrapper;

  const factory = async () => {
    const store = new Vuex.Store({
      modules: {
        terminal: {
          namespaced: true,
          state,
          actions,
          getters,
        },
      },
    });

    wrapper = shallowMount(TerminalView, { localVue, store });

    // Uses deferred components, so wait for those to load...
    await waitForPromises();
  };

  beforeEach(() => {
    state = {
      isShowSplash: true,
      paths: {
        webTerminalHelpPath: TEST_HELP_PATH,
        webTerminalSvgPath: TEST_SVG_PATH,
      },
    };

    actions = {
      hideSplash: jest.fn().mockName('hideSplash'),
      startSession: jest.fn().mockName('startSession'),
    };

    getters = {
      allCheck: () => ({
        isLoading: false,
        isValid: false,
        message: 'bad',
      }),
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders empty state', async () => {
    await factory();

    expect(wrapper.find(TerminalEmptyState).props()).toEqual({
      helpPath: TEST_HELP_PATH,
      illustrationPath: TEST_SVG_PATH,
      ...getters.allCheck(),
    });
  });

  it('hides splash and starts, when started', async () => {
    await factory();

    expect(actions.startSession).not.toHaveBeenCalled();
    expect(actions.hideSplash).not.toHaveBeenCalled();

    wrapper.find(TerminalEmptyState).vm.$emit('start');

    expect(actions.startSession).toHaveBeenCalled();
    expect(actions.hideSplash).toHaveBeenCalled();
  });

  it('shows Web Terminal when started', async () => {
    state.isShowSplash = false;
    await factory();

    expect(wrapper.find(TerminalEmptyState).exists()).toBe(false);
    expect(wrapper.find(TerminalSession).exists()).toBe(true);
  });
});
