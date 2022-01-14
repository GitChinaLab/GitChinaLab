import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import RemoveMemberModal from '~/members/components/modals/remove_member_modal.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { OBSTACLE_TYPES } from '~/vue_shared/components/user_deletion_obstacles/constants';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';

Vue.use(Vuex);

describe('RemoveMemberModal', () => {
  const memberPath = '/gitlab-org/gitlab-test/-/project_members/90';
  const mockObstacles = {
    name: 'User1',
    obstacles: [
      { name: 'Schedule 1', type: OBSTACLE_TYPES.oncallSchedules },
      { name: 'Policy 1', type: OBSTACLE_TYPES.escalationPolicies },
    ],
  };
  let wrapper;

  const actions = {
    hideRemoveMemberModal: jest.fn(),
  };

  const createStore = (removeMemberModalData) =>
    new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          state: {
            removeMemberModalData,
          },
          actions,
        },
      },
    });

  const createComponent = (state) => {
    wrapper = shallowMount(RemoveMemberModal, {
      store: createStore(state),
      provide: {
        namespace: MEMBER_TYPES.user,
      },
    });
  };

  const findForm = () => wrapper.find({ ref: 'form' });
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findUserDeletionObstaclesList = () => wrapper.findComponent(UserDeletionObstaclesList);

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    state                          | memberType         | isAccessRequest | isInvite | actionText               | removeSubMembershipsCheckboxExpected | unassignIssuablesCheckboxExpected | message                                                                                                           | userDeletionObstacles | isPartOfOncall
    ${'removing a group member'}   | ${'GroupMember'}   | ${false}        | ${false} | ${'Remove member'}       | ${true}                              | ${true}                           | ${'Are you sure you want to remove Jane Doe from the Gitlab Org / Gitlab Test project?'}                          | ${{}}                 | ${false}
    ${'removing a project member'} | ${'ProjectMember'} | ${false}        | ${false} | ${'Remove member'}       | ${false}                             | ${true}                           | ${'Are you sure you want to remove Jane Doe from the Gitlab Org / Gitlab Test project?'}                          | ${mockObstacles}      | ${true}
    ${'denying an access request'} | ${'ProjectMember'} | ${true}         | ${false} | ${'Deny access request'} | ${false}                             | ${false}                          | ${"Are you sure you want to deny Jane Doe's request to join the Gitlab Org / Gitlab Test project?"}               | ${{}}                 | ${false}
    ${'revoking invite'}           | ${'ProjectMember'} | ${false}        | ${true}  | ${'Revoke invite'}       | ${false}                             | ${false}                          | ${'Are you sure you want to revoke the invitation for foo@bar.com to join the Gitlab Org / Gitlab Test project?'} | ${mockObstacles}      | ${false}
  `(
    'when $state',
    ({
      actionText,
      memberType,
      isAccessRequest,
      isInvite,
      message,
      removeSubMembershipsCheckboxExpected,
      unassignIssuablesCheckboxExpected,
      userDeletionObstacles,
      isPartOfOncall,
    }) => {
      beforeEach(() => {
        createComponent({
          isAccessRequest,
          isInvite,
          message,
          memberPath,
          memberType,
          userDeletionObstacles,
        });
      });

      it(`has the title ${actionText}`, () => {
        expect(findGlModal().attributes('title')).toBe(actionText);
      });

      it('contains a form action', () => {
        expect(findForm().attributes('action')).toBe(memberPath);
      });

      it('displays a message to the user', () => {
        expect(wrapper.find('p').text()).toBe(message);
      });

      it(`shows ${
        removeSubMembershipsCheckboxExpected ? 'a' : 'no'
      } checkbox to remove direct memberships of subgroups/projects`, () => {
        expect(wrapper.find('[name=remove_sub_memberships]').exists()).toBe(
          removeSubMembershipsCheckboxExpected,
        );
      });

      it(`shows ${
        unassignIssuablesCheckboxExpected ? 'a' : 'no'
      } checkbox to allow removal from related issues and MRs`, () => {
        expect(wrapper.find('[name=unassign_issuables]').exists()).toBe(
          unassignIssuablesCheckboxExpected,
        );
      });

      it(`shows ${isPartOfOncall ? 'all' : 'no'} related on-call schedules or policies`, () => {
        expect(findUserDeletionObstaclesList().exists()).toBe(isPartOfOncall);
      });

      it('submits the form when the modal is submitted', () => {
        const spy = jest.spyOn(findForm().element, 'submit');

        findGlModal().vm.$emit('primary');

        expect(spy).toHaveBeenCalled();

        spy.mockRestore();
      });

      it('calls Vuex action to hide the modal when `GlModal` emits `hide` event', () => {
        findGlModal().vm.$emit('hide');

        expect(actions.hideRemoveMemberModal).toHaveBeenCalled();
      });
    },
  );
});
