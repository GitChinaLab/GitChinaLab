import { GlFormGroup, GlDropdown, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssueTypeField, { i18n } from '~/issues/show/components/fields/type.vue';
import { IssuableTypes } from '~/issues/show/constants';
import {
  getIssueStateQueryResponse,
  updateIssueStateQueryResponse,
} from '../../mock_data/apollo_mock';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Issue type field component', () => {
  let wrapper;
  let fakeApollo;
  let mockIssueStateData;

  const mockResolvers = {
    Query: {
      issueState() {
        return {
          __typename: 'IssueState',
          rawData: mockIssueStateData(),
        };
      },
    },
    Mutation: {
      updateIssueState: jest.fn().mockResolvedValue(updateIssueStateQueryResponse),
    },
  };

  const findTypeFromGroup = () => wrapper.findComponent(GlFormGroup);
  const findTypeFromDropDown = () => wrapper.findComponent(GlDropdown);
  const findTypeFromDropDownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findTypeFromDropDownItemAt = (at) => findTypeFromDropDownItems().at(at);
  const findTypeFromDropDownItemIconAt = (at) =>
    findTypeFromDropDownItems().at(at).findComponent(GlIcon);

  const createComponent = ({ data } = {}, provide) => {
    fakeApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMount(IssueTypeField, {
      localVue,
      apolloProvider: fakeApollo,
      data() {
        return {
          issueState: {},
          ...data,
        };
      },
      provide: {
        canCreateIncident: true,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    mockIssueStateData = jest.fn();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    at   | text                     | icon
    ${0} | ${IssuableTypes[0].text} | ${IssuableTypes[0].icon}
    ${1} | ${IssuableTypes[1].text} | ${IssuableTypes[1].icon}
  `(`renders the issue type $text with an icon in the dropdown`, ({ at, text, icon }) => {
    expect(findTypeFromDropDownItemIconAt(at).attributes('name')).toBe(icon);
    expect(findTypeFromDropDownItemAt(at).text()).toBe(text);
  });

  it('renders a form group with the correct label', () => {
    expect(findTypeFromGroup().attributes('label')).toBe(i18n.label);
  });

  it('renders a form select with the `issue_type` value', () => {
    expect(findTypeFromDropDown().attributes('value')).toBe(IssuableTypes.issue);
  });

  describe('with Apollo cache mock', () => {
    it('renders the selected issueType', async () => {
      mockIssueStateData.mockResolvedValue(getIssueStateQueryResponse);
      await waitForPromises();
      expect(findTypeFromDropDown().attributes('value')).toBe(IssuableTypes.issue);
    });

    it('updates the `issue_type` in the apollo cache when the value is changed', async () => {
      findTypeFromDropDownItems().at(1).vm.$emit('click', IssuableTypes.incident);
      await wrapper.vm.$nextTick();
      expect(findTypeFromDropDown().attributes('value')).toBe(IssuableTypes.incident);
    });

    describe('when user is a guest', () => {
      it('hides the incident type from the dropdown', async () => {
        createComponent({}, { canCreateIncident: false, issueType: 'issue' });
        await waitForPromises();

        expect(findTypeFromDropDownItemAt(0).isVisible()).toBe(true);
        expect(findTypeFromDropDownItemAt(1).isVisible()).toBe(false);
        expect(findTypeFromDropDown().attributes('value')).toBe(IssuableTypes.issue);
      });

      it('and incident is selected, includes incident in the dropdown', async () => {
        createComponent({}, { canCreateIncident: false, issueType: 'incident' });
        await waitForPromises();

        expect(findTypeFromDropDownItemAt(0).isVisible()).toBe(true);
        expect(findTypeFromDropDownItemAt(1).isVisible()).toBe(true);
        expect(findTypeFromDropDown().attributes('value')).toBe(IssuableTypes.incident);
      });
    });
  });
});
