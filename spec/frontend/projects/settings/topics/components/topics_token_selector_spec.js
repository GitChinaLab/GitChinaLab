import { GlTokenSelector, GlToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import TopicsTokenSelector from '~/projects/settings/topics/components/topics_token_selector.vue';

const mockTopics = [
  { id: 1, name: 'topic1', avatarUrl: 'avatar.com/topic1.png' },
  { id: 2, name: 'GitLab', avatarUrl: 'avatar.com/GitLab.png' },
];

describe('TopicsTokenSelector', () => {
  let wrapper;
  let div;
  let input;

  const createComponent = (selected) => {
    wrapper = mount(TopicsTokenSelector, {
      attachTo: div,
      propsData: {
        selected,
      },
      data() {
        return {
          topics: mockTopics,
        };
      },
      mocks: {
        $apollo: {
          queries: {
            topics: { loading: false },
          },
        },
      },
    });
  };

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);

  const findTokenSelectorInput = () => findTokenSelector().find('input[type="text"]');

  const setTokenSelectorInputValue = (value) => {
    const tokenSelectorInput = findTokenSelectorInput();

    tokenSelectorInput.element.value = value;
    tokenSelectorInput.trigger('input');

    return nextTick();
  };

  const tokenSelectorTriggerEnter = (event) => {
    const tokenSelectorInput = findTokenSelectorInput();
    tokenSelectorInput.trigger('keydown.enter', event);
  };

  beforeEach(() => {
    div = document.createElement('div');
    input = document.createElement('input');
    input.setAttribute('type', 'text');
    input.id = 'project_topic_list_field';
    document.body.appendChild(div);
    document.body.appendChild(input);
  });

  afterEach(() => {
    wrapper.destroy();
    div.remove();
    input.remove();
  });

  describe('when component is mounted', () => {
    it('parses selected into tokens', async () => {
      const selected = [
        { id: 11, name: 'topic1' },
        { id: 12, name: 'topic2' },
        { id: 13, name: 'topic3' },
      ];
      createComponent(selected);
      await nextTick();

      wrapper.findAllComponents(GlToken).wrappers.forEach((tokenWrapper, index) => {
        expect(tokenWrapper.text()).toBe(selected[index].name);
      });
    });
  });

  describe('when enter key is pressed', () => {
    it('does not submit the form if token selector text input has a value', async () => {
      createComponent();

      await setTokenSelectorInputValue('topic');

      const event = { preventDefault: jest.fn() };
      tokenSelectorTriggerEnter(event);

      expect(event.preventDefault).toHaveBeenCalled();
    });
  });
});
