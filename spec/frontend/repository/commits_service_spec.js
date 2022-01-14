import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { loadCommits, isRequested, resetRequestedCommits } from '~/repository/commits_service';
import httpStatus from '~/lib/utils/http_status';
import createFlash from '~/flash';
import { I18N_COMMIT_DATA_FETCH_ERROR } from '~/repository/constants';

jest.mock('~/flash');

describe('commits service', () => {
  let mock;
  const url = `${gon.relative_url_root || ''}/my-project/-/refs/main/logs_tree/`;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onGet(url).reply(httpStatus.OK, [], {});

    jest.spyOn(axios, 'get');
  });

  afterEach(() => {
    mock.restore();
    resetRequestedCommits();
  });

  const requestCommits = (offset, project = 'my-project', path = '', ref = 'main') =>
    loadCommits(project, path, ref, offset);

  it('calls axios get', async () => {
    const offset = 10;
    const project = 'my-project';
    const path = 'my-path';
    const ref = 'my-ref';
    const testUrl = `${gon.relative_url_root || ''}/${project}/-/refs/${ref}/logs_tree/${path}`;

    await requestCommits(offset, project, path, ref);

    expect(axios.get).toHaveBeenCalledWith(testUrl, { params: { format: 'json', offset } });
  });

  it('encodes the path correctly', async () => {
    await requestCommits(1, 'some-project', 'with $peci@l ch@rs/');

    const encodedUrl = '/some-project/-/refs/main/logs_tree/with%20%24peci%40l%20ch%40rs%2F';
    expect(axios.get).toHaveBeenCalledWith(encodedUrl, expect.anything());
  });

  it('calls axios get once per batch', async () => {
    await Promise.all([requestCommits(0), requestCommits(1), requestCommits(23)]);

    expect(axios.get.mock.calls.length).toEqual(1);
  });

  it('updates the list of requested offsets', async () => {
    await requestCommits(200);

    expect(isRequested(200)).toBe(true);
  });

  it('resets the list of requested offsets', async () => {
    await requestCommits(300);

    resetRequestedCommits();
    expect(isRequested(300)).toBe(false);
  });

  it('calls `createFlash` when the request fails', async () => {
    const invalidPath = '/#@ some/path';
    const invalidUrl = `${url}${invalidPath}`;
    mock.onGet(invalidUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR, [], {});

    await requestCommits(1, 'my-project', invalidPath);

    expect(createFlash).toHaveBeenCalledWith({ message: I18N_COMMIT_DATA_FETCH_ERROR });
  });
});
