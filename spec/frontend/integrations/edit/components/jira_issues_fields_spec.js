import { GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { VALIDATE_INTEGRATION_FORM_EVENT } from '~/integrations/constants';
import JiraIssuesFields from '~/integrations/edit/components/jira_issues_fields.vue';
import eventHub from '~/integrations/edit/event_hub';
import { createStore } from '~/integrations/edit/store';

describe('JiraIssuesFields', () => {
  let store;
  let wrapper;

  const defaultProps = {
    editProjectPath: '/edit',
    showJiraIssuesIntegration: true,
    showJiraVulnerabilitiesIntegration: true,
    upgradePlanPath: 'https://gitlab.com',
  };

  const createComponent = ({
    isInheriting = false,
    mountFn = mountExtended,
    props,
    ...options
  } = {}) => {
    store = createStore({
      defaultState: isInheriting ? {} : undefined,
    });

    wrapper = mountFn(JiraIssuesFields, {
      propsData: { ...defaultProps, ...props },
      store,
      stubs: ['jira-issue-creation-vulnerabilities'],
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findEnableCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findEnableCheckboxDisabled = () =>
    findEnableCheckbox().find('[type=checkbox]').attributes('disabled');
  const findProjectKey = () => wrapper.findComponent(GlFormInput);
  const findProjectKeyFormGroup = () => wrapper.findByTestId('project-key-form-group');
  const findPremiumUpgradeCTA = () => wrapper.findByTestId('premium-upgrade-cta');
  const findUltimateUpgradeCTA = () => wrapper.findByTestId('ultimate-upgrade-cta');
  const findJiraForVulnerabilities = () => wrapper.findByTestId('jira-for-vulnerabilities');
  const findConflictWarning = () => wrapper.findByTestId('conflict-warning-text');
  const setEnableCheckbox = async (isEnabled = true) =>
    findEnableCheckbox().vm.$emit('input', isEnabled);

  const assertProjectKeyState = (expectedStateValue) => {
    expect(findProjectKey().attributes('state')).toBe(expectedStateValue);
    expect(findProjectKeyFormGroup().attributes('state')).toBe(expectedStateValue);
  };

  describe('template', () => {
    describe.each`
      showJiraIssuesIntegration | showJiraVulnerabilitiesIntegration
      ${false}                  | ${false}
      ${false}                  | ${true}
      ${true}                   | ${false}
      ${true}                   | ${true}
    `(
      'when `showJiraIssuesIntegration` is $jiraIssues and `showJiraVulnerabilitiesIntegration` is $jiraVulnerabilities',
      ({ showJiraIssuesIntegration, showJiraVulnerabilitiesIntegration }) => {
        beforeEach(() => {
          createComponent({
            props: {
              showJiraIssuesIntegration,
              showJiraVulnerabilitiesIntegration,
            },
          });
        });

        if (showJiraIssuesIntegration) {
          it('renders checkbox and input field', () => {
            expect(findEnableCheckbox().exists()).toBe(true);
            expect(findEnableCheckboxDisabled()).toBeUndefined();
            expect(findProjectKey().exists()).toBe(true);
          });

          it('does not render the Premium CTA', () => {
            expect(findPremiumUpgradeCTA().exists()).toBe(false);
          });

          if (!showJiraVulnerabilitiesIntegration) {
            it.each`
              scenario                                                                          | enableJiraIssues
              ${'when "Enable Jira issues" is checked, renders Ultimate upgrade CTA'}           | ${true}
              ${'when "Enable Jira issues" is unchecked, does not render Ultimate upgrade CTA'} | ${false}
            `('$scenario', async ({ enableJiraIssues }) => {
              if (enableJiraIssues) {
                await setEnableCheckbox();
              }
              expect(findUltimateUpgradeCTA().exists()).toBe(enableJiraIssues);
            });
          }
        } else {
          it('does not render checkbox and input field', () => {
            expect(findEnableCheckbox().exists()).toBe(false);
            expect(findProjectKey().exists()).toBe(false);
          });

          it('renders the Premium CTA', () => {
            const premiumUpgradeCTA = findPremiumUpgradeCTA();

            expect(premiumUpgradeCTA.exists()).toBe(true);
            expect(premiumUpgradeCTA.props('upgradePlanPath')).toBe(defaultProps.upgradePlanPath);
          });
        }

        it('does not render the Ultimate CTA', () => {
          expect(findUltimateUpgradeCTA().exists()).toBe(false);
        });
      },
    );

    describe('Enable Jira issues checkbox', () => {
      beforeEach(() => {
        createComponent({ props: { initialProjectKey: '' } });
      });

      it('renders disabled project_key input', () => {
        const projectKey = findProjectKey();

        expect(projectKey.exists()).toBe(true);
        expect(projectKey.attributes('disabled')).toBe('disabled');
        expect(projectKey.attributes('required')).toBeUndefined();
      });

      // As per https://vuejs.org/v2/guide/forms.html#Checkbox-1,
      // browsers don't include unchecked boxes in form submissions.
      it('includes issues_enabled as false even if unchecked', () => {
        expect(wrapper.find('input[name="service[issues_enabled]"]').exists()).toBe(true);
      });

      describe('when isInheriting = true', () => {
        it('disables checkbox and sets input as readonly', () => {
          createComponent({ isInheriting: true });

          expect(findEnableCheckboxDisabled()).toBe('disabled');
          expect(findProjectKey().attributes('readonly')).toBe('readonly');
        });
      });

      describe('on enable issues', () => {
        it('enables project_key input as required', async () => {
          await setEnableCheckbox(true);

          expect(findProjectKey().attributes('disabled')).toBeUndefined();
          expect(findProjectKey().attributes('required')).toBe('required');
        });
      });
    });

    it('contains link to editProjectPath', () => {
      createComponent();

      expect(wrapper.find(`a[href="${defaultProps.editProjectPath}"]`).exists()).toBe(true);
    });

    describe('GitLab issues warning', () => {
      it.each`
        gitlabIssuesEnabled | scenario
        ${true}             | ${'displays conflict warning'}
        ${false}            | ${'does not display conflict warning'}
      `(
        '$scenario when `gitlabIssuesEnabled` is `$gitlabIssuesEnabled`',
        ({ gitlabIssuesEnabled }) => {
          createComponent({ props: { gitlabIssuesEnabled } });

          expect(findConflictWarning().exists()).toBe(gitlabIssuesEnabled);
        },
      );
    });

    describe('Vulnerabilities creation', () => {
      beforeEach(() => {
        createComponent();
      });

      it.each([true, false])(
        'shows the jira-vulnerabilities component correctly when jira issues enables is set to "%s"',
        async (hasJiraIssuesEnabled) => {
          await setEnableCheckbox(hasJiraIssuesEnabled);

          expect(findJiraForVulnerabilities().exists()).toBe(hasJiraIssuesEnabled);
        },
      );

      it('passes down the correct show-full-feature property', async () => {
        await setEnableCheckbox(true);
        expect(findJiraForVulnerabilities().attributes('show-full-feature')).toBe('true');
        wrapper.setProps({ showJiraVulnerabilitiesIntegration: false });
        await wrapper.vm.$nextTick();
        expect(findJiraForVulnerabilities().attributes('show-full-feature')).toBeUndefined();
      });

      it('passes down the correct initial-issue-type-id value when value is empty', async () => {
        await setEnableCheckbox(true);
        expect(findJiraForVulnerabilities().attributes('initial-issue-type-id')).toBeUndefined();
      });

      it('passes down the correct initial-issue-type-id value when value is not empty', async () => {
        const jiraIssueType = 'some-jira-issue-type';
        wrapper.setProps({ initialVulnerabilitiesIssuetype: jiraIssueType });
        await setEnableCheckbox(true);
        expect(findJiraForVulnerabilities().attributes('initial-issue-type-id')).toBe(
          jiraIssueType,
        );
      });

      it('emits "request-jira-issue-types` when the jira-vulnerabilities component requests to fetch issue types', async () => {
        await setEnableCheckbox(true);
        await findJiraForVulnerabilities().vm.$emit('request-jira-issue-types');

        expect(wrapper.emitted('request-jira-issue-types')).toHaveLength(1);
      });
    });

    describe('Project key input field', () => {
      beforeEach(() => {
        createComponent({
          props: {
            initialProjectKey: '',
            initialEnableJiraIssues: true,
          },
          mountFn: shallowMountExtended,
        });
      });

      it('sets Project Key `state` attribute to `true` by default', () => {
        assertProjectKeyState('true');
      });

      describe('when event hub recieves `VALIDATE_INTEGRATION_FORM_EVENT` event', () => {
        describe('with no project key', () => {
          it('sets Project Key `state` attribute to `undefined`', async () => {
            eventHub.$emit(VALIDATE_INTEGRATION_FORM_EVENT);
            await wrapper.vm.$nextTick();

            assertProjectKeyState(undefined);
          });
        });

        describe('when project key is set', () => {
          it('sets Project Key `state` attribute to `true`', async () => {
            eventHub.$emit(VALIDATE_INTEGRATION_FORM_EVENT);

            // set the project key
            await findProjectKey().vm.$emit('input', 'AB');
            await wrapper.vm.$nextTick();

            assertProjectKeyState('true');
          });
        });
      });
    });
  });
});
