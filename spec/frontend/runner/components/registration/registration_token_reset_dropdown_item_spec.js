import { GlDropdownItem, GlLoadingIcon, GlToast } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import RegistrationTokenResetDropdownItem from '~/runner/components/registration/registration_token_reset_dropdown_item.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/runner/constants';
import runnersRegistrationTokenResetMutation from '~/runner/graphql/runners_registration_token_reset.mutation.graphql';
import { captureException } from '~/runner/sentry_utils';

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

const localVue = createLocalVue();
localVue.use(VueApollo);
localVue.use(GlToast);

const mockNewToken = 'NEW_TOKEN';

describe('RegistrationTokenResetDropdownItem', () => {
  let wrapper;
  let runnersRegistrationTokenResetMutationHandler;
  let showToast;

  const findDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = ({ props, provide = {} } = {}) => {
    wrapper = shallowMount(RegistrationTokenResetDropdownItem, {
      localVue,
      provide,
      propsData: {
        type: INSTANCE_TYPE,
        ...props,
      },
      apolloProvider: createMockApollo([
        [runnersRegistrationTokenResetMutation, runnersRegistrationTokenResetMutationHandler],
      ]),
    });

    showToast = wrapper.vm.$toast ? jest.spyOn(wrapper.vm.$toast, 'show') : null;
  };

  beforeEach(() => {
    runnersRegistrationTokenResetMutationHandler = jest.fn().mockResolvedValue({
      data: {
        runnersRegistrationTokenReset: {
          token: mockNewToken,
          errors: [],
        },
      },
    });

    createComponent();

    jest.spyOn(window, 'confirm');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays reset button', () => {
    expect(findDropdownItem().exists()).toBe(true);
  });

  describe('On click and confirmation', () => {
    const mockGroupId = '11';
    const mockProjectId = '22';

    describe.each`
      type             | provide                         | expectedInput
      ${INSTANCE_TYPE} | ${{}}                           | ${{ type: INSTANCE_TYPE }}
      ${GROUP_TYPE}    | ${{ groupId: mockGroupId }}     | ${{ type: GROUP_TYPE, id: `gid://gitlab/Group/${mockGroupId}` }}
      ${PROJECT_TYPE}  | ${{ projectId: mockProjectId }} | ${{ type: PROJECT_TYPE, id: `gid://gitlab/Project/${mockProjectId}` }}
    `('Resets token of type $type', ({ type, provide, expectedInput }) => {
      beforeEach(async () => {
        createComponent({
          provide,
          props: { type },
        });

        window.confirm.mockReturnValueOnce(true);

        findDropdownItem().trigger('click');
        await waitForPromises();
      });

      it('resets token', () => {
        expect(runnersRegistrationTokenResetMutationHandler).toHaveBeenCalledTimes(1);
        expect(runnersRegistrationTokenResetMutationHandler).toHaveBeenCalledWith({
          input: expectedInput,
        });
      });

      it('emits result', () => {
        expect(wrapper.emitted('tokenReset')).toHaveLength(1);
        expect(wrapper.emitted('tokenReset')[0]).toEqual([mockNewToken]);
      });

      it('does not show a loading state', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('shows confirmation', () => {
        expect(showToast).toHaveBeenLastCalledWith(
          expect.stringContaining('registration token generated'),
        );
      });
    });
  });

  describe('On click without confirmation', () => {
    beforeEach(async () => {
      window.confirm.mockReturnValueOnce(false);
      findDropdownItem().vm.$emit('click');
      await waitForPromises();
    });

    it('does not reset token', () => {
      expect(runnersRegistrationTokenResetMutationHandler).not.toHaveBeenCalled();
    });

    it('does not emit any result', () => {
      expect(wrapper.emitted('tokenReset')).toBeUndefined();
    });

    it('does not show a loading state', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not shows confirmation', () => {
      expect(showToast).not.toHaveBeenCalled();
    });
  });

  describe('On error', () => {
    it('On network error, error message is shown', async () => {
      const mockErrorMsg = 'Token reset failed!';

      runnersRegistrationTokenResetMutationHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

      window.confirm.mockReturnValueOnce(true);
      findDropdownItem().trigger('click');
      await waitForPromises();

      expect(createFlash).toHaveBeenLastCalledWith({
        message: `Network error: ${mockErrorMsg}`,
      });
      expect(captureException).toHaveBeenCalledWith({
        error: new Error(`Network error: ${mockErrorMsg}`),
        component: 'RunnerRegistrationTokenReset',
      });
    });

    it('On validation error, error message is shown', async () => {
      const mockErrorMsg = 'User not allowed!';
      const mockErrorMsg2 = 'Type is not valid!';

      runnersRegistrationTokenResetMutationHandler.mockResolvedValue({
        data: {
          runnersRegistrationTokenReset: {
            token: null,
            errors: [mockErrorMsg, mockErrorMsg2],
          },
        },
      });

      window.confirm.mockReturnValueOnce(true);
      findDropdownItem().trigger('click');
      await waitForPromises();

      expect(createFlash).toHaveBeenLastCalledWith({
        message: `${mockErrorMsg} ${mockErrorMsg2}`,
      });
      expect(captureException).toHaveBeenCalledWith({
        error: new Error(`${mockErrorMsg} ${mockErrorMsg2}`),
        component: 'RunnerRegistrationTokenReset',
      });
    });
  });

  describe('Immediately after click', () => {
    it('shows loading state', async () => {
      window.confirm.mockReturnValue(true);
      findDropdownItem().trigger('click');
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });
});
