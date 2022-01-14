/* eslint-disable @gitlab/require-i18n-strings */

import { OBSTACLE_TYPES } from './constants';
import UserDeletionObstaclesList from './user_deletion_obstacles_list.vue';

export default {
  component: UserDeletionObstaclesList,
  title: 'vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list',
};

const Template = (args, { argTypes }) => ({
  components: { UserDeletionObstaclesList },
  props: Object.keys(argTypes),
  template: '<user-deletion-obstacles-list v-bind="$props" v-on="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  obstacles: [
    {
      type: OBSTACLE_TYPES.oncallSchedules,
      name: 'APAC',
      url: 'https://domain.com/group/main-application/oncall_schedules',
      projectName: 'main-application',
      projectUrl: 'https://domain.com/group/main-application',
    },
    {
      type: OBSTACLE_TYPES.escalationPolicies,
      name: 'Engineering On-call',
      url: 'https://domain.com/group/microservice-backend/escalation_policies',
      projectName: 'Microservice Backend',
      projectUrl: 'https://domain.com/group/microservice-backend',
    },
  ],
  userName: 'Thomspon Smith',
  isCurrentUser: false,
};
