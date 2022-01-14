import { GlAlert, GlKeysetPagination, GlLoadingIcon, GlSprintf, GlTab } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ClusterAgentShow from '~/clusters/agents/components/show.vue';
import TokenTable from '~/clusters/agents/components/token_table.vue';
import ActivityEvents from '~/clusters/agents/components/activity_events_list.vue';
import getAgentQuery from '~/clusters/agents/graphql/queries/get_cluster_agent.query.graphql';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('ClusterAgentShow', () => {
  let wrapper;
  useFakeDate([2021, 2, 15]);

  const propsData = {
    agentName: 'cluster-agent',
    projectPath: 'path/to/project',
  };

  const defaultClusterAgent = {
    id: '1',
    createdAt: '2021-02-13T00:00:00Z',
    createdByUser: {
      id: 'user-1',
      name: 'user-1',
    },
    name: 'token-1',
    tokens: {
      count: 1,
      nodes: [],
      pageInfo: null,
    },
  };

  const createWrapper = ({ clusterAgent, queryResponse = null }) => {
    const agentQueryResponse =
      queryResponse ||
      jest.fn().mockResolvedValue({ data: { project: { id: 'project-1', clusterAgent } } });
    const apolloProvider = createMockApollo([[getAgentQuery, agentQueryResponse]]);

    wrapper = extendedWrapper(
      shallowMount(ClusterAgentShow, {
        localVue,
        apolloProvider,
        propsData,
        stubs: { GlSprintf, TimeAgoTooltip, GlTab },
      }),
    );
  };

  const createWrapperWithoutApollo = ({ clusterAgent, loading = false, slots = {} }) => {
    const $apollo = { queries: { clusterAgent: { loading } } };

    wrapper = extendedWrapper(
      shallowMount(ClusterAgentShow, {
        propsData,
        mocks: { $apollo, clusterAgent },
        slots,
        stubs: { GlTab },
      }),
    );
  };

  const findCreatedText = () => wrapper.findByTestId('cluster-agent-create-info').text();
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPaginationButtons = () => wrapper.findComponent(GlKeysetPagination);
  const findTokenCount = () => wrapper.findByTestId('cluster-agent-token-count').text();
  const findEESecurityTabSlot = () => wrapper.findByTestId('ee-security-tab');
  const findActivity = () => wrapper.findComponent(ActivityEvents);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default behaviour', () => {
    beforeEach(() => {
      return createWrapper({ clusterAgent: defaultClusterAgent });
    });

    it('displays the agent name', () => {
      expect(wrapper.text()).toContain(propsData.agentName);
    });

    it('displays agent create information', () => {
      expect(findCreatedText()).toMatchInterpolatedText('Created by user-1 2 days ago');
    });

    it('displays token count', () => {
      expect(findTokenCount()).toMatchInterpolatedText(
        `${ClusterAgentShow.i18n.tokens} ${defaultClusterAgent.tokens.count}`,
      );
    });

    it('renders token table', () => {
      expect(wrapper.findComponent(TokenTable).exists()).toBe(true);
    });

    it('should not render pagination buttons when there are no additional pages', () => {
      expect(findPaginationButtons().exists()).toBe(false);
    });

    it('renders activity events list', () => {
      expect(findActivity().exists()).toBe(true);
    });
  });

  describe('when create user is unknown', () => {
    const missingUser = {
      ...defaultClusterAgent,
      createdByUser: null,
    };

    beforeEach(() => {
      return createWrapper({ clusterAgent: missingUser });
    });

    it('displays agent create information with unknown user', () => {
      expect(findCreatedText()).toMatchInterpolatedText('Created by Unknown user 2 days ago');
    });
  });

  describe('when token count is missing', () => {
    const missingTokens = {
      ...defaultClusterAgent,
      tokens: null,
    };

    beforeEach(() => {
      return createWrapper({ clusterAgent: missingTokens });
    });

    it('displays token header with no count', () => {
      expect(findTokenCount()).toMatchInterpolatedText(`${ClusterAgentShow.i18n.tokens}`);
    });
  });

  describe('when the token list has additional pages', () => {
    const pageInfo = {
      hasNextPage: true,
      hasPreviousPage: false,
      startCursor: 'prev',
      endCursor: 'next',
    };

    const tokenPagination = {
      ...defaultClusterAgent,
      tokens: {
        ...defaultClusterAgent.tokens,
        pageInfo,
      },
    };

    beforeEach(() => {
      return createWrapper({ clusterAgent: tokenPagination });
    });

    it('should render pagination buttons', () => {
      expect(findPaginationButtons().exists()).toBe(true);
    });

    it('should pass pageInfo to the pagination component', () => {
      expect(findPaginationButtons().props()).toMatchObject(pageInfo);
    });
  });

  describe('when the agent query is loading', () => {
    describe('when the clusterAgent is missing', () => {
      beforeEach(() => {
        return createWrapper({
          clusterAgent: null,
          queryResponse: jest.fn().mockReturnValue(new Promise(() => {})),
        });
      });

      it('displays a loading icon and hides the token tab', () => {
        expect(findLoadingIcon().exists()).toBe(true);
        expect(wrapper.text()).not.toContain(ClusterAgentShow.i18n.tokens);
      });
    });

    describe('when the clusterAgent is present', () => {
      beforeEach(() => {
        createWrapperWithoutApollo({ clusterAgent: defaultClusterAgent, loading: true });
      });

      it('displays a loading icon and token tab', () => {
        expect(findLoadingIcon().exists()).toBe(true);
        expect(wrapper.text()).toContain(ClusterAgentShow.i18n.tokens);
      });
    });
  });

  describe('when the agent query has errored', () => {
    beforeEach(() => {
      createWrapper({ clusterAgent: null, queryResponse: jest.fn().mockRejectedValue() });
      return waitForPromises();
    });

    it('displays an alert message', () => {
      expect(wrapper.findComponent(GlAlert).exists()).toBe(true);
      expect(wrapper.text()).toContain(ClusterAgentShow.i18n.loadingError);
    });
  });

  describe('ee-security-tab slot', () => {
    it('does not display when a slot is not passed in', async () => {
      createWrapperWithoutApollo({ clusterAgent: defaultClusterAgent });
      await nextTick();
      expect(findEESecurityTabSlot().exists()).toBe(false);
    });

    it('does display when a slot is passed in', async () => {
      createWrapperWithoutApollo({
        clusterAgent: defaultClusterAgent,
        slots: {
          'ee-security-tab': `<gl-tab data-testid="ee-security-tab">Security Tab!</gl-tab>`,
        },
      });
      await nextTick();
      expect(findEESecurityTabSlot().exists()).toBe(true);
    });
  });
});
