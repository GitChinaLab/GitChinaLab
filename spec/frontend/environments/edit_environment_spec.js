import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EditEnvironment from '~/environments/components/edit_environment.vue';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/flash');

const DEFAULT_OPTS = {
  provide: {
    projectEnvironmentsPath: '/projects/environments',
    updateEnvironmentPath: '/proejcts/environments/1',
  },
  propsData: { environment: { id: '0', name: 'foo', external_url: 'https://foo.example.com' } },
};

describe('~/environments/components/edit.vue', () => {
  let wrapper;
  let mock;

  const createWrapper = (opts = {}) =>
    mountExtended(EditEnvironment, {
      ...DEFAULT_OPTS,
      ...opts,
    });

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = createWrapper();
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  const findNameInput = () => wrapper.findByLabelText('Name');
  const findExternalUrlInput = () => wrapper.findByLabelText('External URL');
  const findForm = () => wrapper.findByRole('form', { name: 'Edit environment' });

  const showsLoading = () => wrapper.find(GlLoadingIcon).exists();

  const submitForm = async (expected, response) => {
    mock
      .onPut(DEFAULT_OPTS.provide.updateEnvironmentPath, {
        external_url: expected.url,
        id: '0',
      })
      .reply(...response);
    await findExternalUrlInput().setValue(expected.url);

    await findForm().trigger('submit');
    await waitForPromises();
  };

  it('sets the title to Edit environment', () => {
    const header = wrapper.findByRole('heading', { name: 'Edit environment' });
    expect(header.exists()).toBe(true);
  });

  it('shows loader after form is submitted', async () => {
    const expected = { url: 'https://google.ca' };

    expect(showsLoading()).toBe(false);

    await submitForm(expected, [200, { path: '/test' }]);

    expect(showsLoading()).toBe(true);
  });

  it('submits the updated environment on submit', async () => {
    const expected = { url: 'https://google.ca' };

    await submitForm(expected, [200, { path: '/test' }]);

    expect(visitUrl).toHaveBeenCalledWith('/test');
  });

  it('shows errors on error', async () => {
    const expected = { url: 'https://google.ca' };

    await submitForm(expected, [400, { message: ['uh oh!'] }]);

    expect(createFlash).toHaveBeenCalledWith({ message: 'uh oh!' });
    expect(showsLoading()).toBe(false);
  });

  it('renders a disabled "Name" field', () => {
    const nameInput = findNameInput();

    expect(nameInput.attributes().disabled).toBe('disabled');
    expect(nameInput.element.value).toBe('foo');
  });

  it('renders an "External URL" field', () => {
    const urlInput = findExternalUrlInput();

    expect(urlInput.element.value).toBe('https://foo.example.com');
  });
});
