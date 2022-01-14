import { GlAlert, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTypeAlert from '~/runner/components/runner_type_alert.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/runner/constants';

describe('RunnerTypeAlert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerTypeAlert, {
      propsData: {
        type: INSTANCE_TYPE,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    type             | exampleText                                                            | anchor
    ${INSTANCE_TYPE} | ${'This runner is available to all groups and projects'}               | ${'#shared-runners'}
    ${GROUP_TYPE}    | ${'This runner is available to all projects and subgroups in a group'} | ${'#group-runners'}
    ${PROJECT_TYPE}  | ${'This runner is associated with one or more projects'}               | ${'#specific-runners'}
  `('When it is an $type level runner', ({ type, exampleText, anchor }) => {
    beforeEach(() => {
      createComponent({ props: { type } });
    });

    it('Describes runner type', () => {
      expect(wrapper.text()).toMatch(exampleText);
    });

    it(`Shows an "info" variant`, () => {
      expect(findAlert().props('variant')).toBe('info');
    });

    it(`Links to anchor "${anchor}"`, () => {
      expect(findLink().attributes('href')).toBe(`/help/ci/runners/runners_scope${anchor}`);
    });
  });

  describe('When runner type is not correct', () => {
    it('Does not render content when type is missing', () => {
      createComponent({ props: { type: undefined } });

      expect(wrapper.html()).toBe('');
    });

    it('Validation fails for an incorrect type', () => {
      expect(() => {
        createComponent({ props: { type: 'NOT_A_TYPE' } });
      }).toThrow();
    });
  });
});
