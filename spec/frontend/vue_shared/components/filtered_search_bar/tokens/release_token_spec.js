import { GlFilteredSearchToken, GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import ReleaseToken from '~/vue_shared/components/filtered_search_bar/tokens/release_token.vue';
import { mockReleaseToken } from '../mock_data';

jest.mock('~/flash');

describe('ReleaseToken', () => {
  const id = '123';
  let wrapper;

  const createComponent = ({ config = mockReleaseToken, value = { data: '' } } = {}) =>
    mount(ReleaseToken, {
      propsData: {
        active: false,
        config,
        value,
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
        suggestionsListClass: () => 'custom-class',
      },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders release value', async () => {
    wrapper = createComponent({ value: { data: id } });
    await wrapper.vm.$nextTick();

    const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

    expect(tokenSegments).toHaveLength(3); // `Release` `=` `v1`
    expect(tokenSegments.at(2).text()).toBe(id.toString());
  });

  it('fetches initial values', () => {
    const fetchReleasesSpy = jest.fn().mockResolvedValue();

    wrapper = createComponent({
      config: { ...mockReleaseToken, fetchReleases: fetchReleasesSpy },
      value: { data: id },
    });

    expect(fetchReleasesSpy).toHaveBeenCalledWith(id);
  });

  it('fetches releases on user input', () => {
    const search = 'hello';
    const fetchReleasesSpy = jest.fn().mockResolvedValue();

    wrapper = createComponent({
      config: { ...mockReleaseToken, fetchReleases: fetchReleasesSpy },
    });

    wrapper.findComponent(GlFilteredSearchToken).vm.$emit('input', { data: search });

    expect(fetchReleasesSpy).toHaveBeenCalledWith(search);
  });

  it('renders error message when request fails', async () => {
    const fetchReleasesSpy = jest.fn().mockRejectedValue();

    wrapper = createComponent({
      config: { ...mockReleaseToken, fetchReleases: fetchReleasesSpy },
    });
    await waitForPromises();

    expect(createFlash).toHaveBeenCalledWith({
      message: 'There was a problem fetching releases.',
    });
  });
});
