import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';

import BoardCard from '~/boards/components/board_card.vue';
import BoardList from '~/boards/components/board_list.vue';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import BoardNewItem from '~/boards/components/board_new_item.vue';
import defaultState from '~/boards/stores/state';
import createMockApollo from 'helpers/mock_apollo_helper';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import {
  mockList,
  mockIssuesByListId,
  issues,
  mockGroupProjects,
  boardListQueryResponse,
} from './mock_data';

export default function createComponent({
  listIssueProps = {},
  componentProps = {},
  listProps = {},
  actions = {},
  getters = {},
  provide = {},
  data = {},
  state = defaultState,
  stubs = {
    BoardNewIssue,
    BoardNewItem,
    BoardCard,
  },
  issuesCount,
} = {}) {
  const localVue = createLocalVue();
  localVue.use(VueApollo);
  localVue.use(Vuex);

  const fakeApollo = createMockApollo([
    [listQuery, jest.fn().mockResolvedValue(boardListQueryResponse(issuesCount))],
  ]);

  const store = new Vuex.Store({
    state: {
      selectedProject: mockGroupProjects[0],
      boardItemsByListId: mockIssuesByListId,
      boardItems: issues,
      pageInfoByListId: {
        'gid://gitlab/List/1': { hasNextPage: true },
        'gid://gitlab/List/2': {},
      },
      listsFlags: {
        'gid://gitlab/List/1': {},
        'gid://gitlab/List/2': {},
      },
      selectedBoardItems: [],
      ...state,
    },
    getters: {
      isGroupBoard: () => false,
      isProjectBoard: () => true,
      isEpicBoard: () => false,
      ...getters,
    },
    actions,
  });

  const list = {
    ...mockList,
    ...listProps,
  };
  const issue = {
    title: 'Testing',
    id: 1,
    iid: 1,
    confidential: false,
    labels: [],
    assignees: [],
    ...listIssueProps,
  };
  if (!Object.prototype.hasOwnProperty.call(listProps, 'issuesCount')) {
    list.issuesCount = 1;
  }

  const component = shallowMount(BoardList, {
    apolloProvider: fakeApollo,
    localVue,
    store,
    propsData: {
      disabled: false,
      list,
      boardItems: [issue],
      canAdminList: true,
      ...componentProps,
    },
    provide: {
      groupId: null,
      rootPath: '/',
      boardId: '1',
      weightFeatureAvailable: false,
      boardWeight: null,
      canAdminList: true,
      ...provide,
    },
    stubs,
    data() {
      return {
        ...data,
      };
    },
  });

  return component;
}
