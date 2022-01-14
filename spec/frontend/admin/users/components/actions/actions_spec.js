import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { kebabCase } from 'lodash';
import Actions from '~/admin/users/components/actions';
import SharedDeleteAction from '~/admin/users/components/actions/shared/shared_delete_action.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { OBSTACLE_TYPES } from '~/vue_shared/components/user_deletion_obstacles/constants';
import { CONFIRMATION_ACTIONS, DELETE_ACTIONS } from '../../constants';
import { paths } from '../../mock_data';

describe('Action components', () => {
  let wrapper;

  const findDropdownItem = () => wrapper.find(GlDropdownItem);

  const initComponent = ({ component, props, stubs = {} } = {}) => {
    wrapper = shallowMount(component, {
      propsData: {
        ...props,
      },
      stubs,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('CONFIRMATION_ACTIONS', () => {
    it.each(CONFIRMATION_ACTIONS)('renders a dropdown item for "%s"', async (action) => {
      initComponent({
        component: Actions[capitalizeFirstCharacter(action)],
        props: {
          username: 'John Doe',
          path: '/test',
        },
      });

      await nextTick();
      expect(findDropdownItem().exists()).toBe(true);
    });
  });

  describe('DELETE_ACTION_COMPONENTS', () => {
    const userDeletionObstacles = [
      { name: 'schedule1', type: OBSTACLE_TYPES.oncallSchedules },
      { name: 'policy1', type: OBSTACLE_TYPES.escalationPolicies },
    ];

    it.each(DELETE_ACTIONS.map((action) => [action, paths[action]]))(
      'renders a dropdown item for "%s"',
      async (action, expectedPath) => {
        initComponent({
          component: Actions[capitalizeFirstCharacter(action)],
          props: {
            username: 'John Doe',
            paths,
            userDeletionObstacles,
          },
          stubs: { SharedDeleteAction },
        });

        await nextTick();
        const sharedAction = wrapper.find(SharedDeleteAction);

        expect(sharedAction.attributes('data-block-user-url')).toBe(paths.block);
        expect(sharedAction.attributes('data-delete-user-url')).toBe(expectedPath);
        expect(sharedAction.attributes('data-gl-modal-action')).toBe(kebabCase(action));
        expect(sharedAction.attributes('data-username')).toBe('John Doe');
        expect(sharedAction.attributes('data-user-deletion-obstacles')).toBe(
          JSON.stringify(userDeletionObstacles),
        );

        expect(findDropdownItem().exists()).toBe(true);
      },
    );
  });
});
