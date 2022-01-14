import MockAdapter from 'axios-mock-adapter';
import { publishPackage } from '~/api/packages_api';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';
  const dummyGon = {
    api_version: dummyApiVersion,
    relative_url_root: dummyUrlRoot,
  };
  let originalGon;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { ...dummyGon };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('packages', () => {
    const projectPath = 'project_a';
    const name = 'foo';
    const packageVersion = '0';
    const apiResponse = [{ id: 1, name: 'foo' }];

    describe('publishPackage', () => {
      it('publishes the package', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/packages/generic/${name}/${packageVersion}/${name}`;

        jest.spyOn(axios, 'put');
        mock.onPut(expectedUrl).replyOnce(httpStatus.OK, apiResponse);

        return publishPackage(
          { projectPath, name, version: 0, fileName: name, files: [{}] },
          { status: 'hidden', select: 'package_file' },
        ).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.put).toHaveBeenCalledWith(expectedUrl, expect.any(FormData), {
            headers: { 'Content-Type': 'multipart/form-data' },
            params: { select: 'package_file', status: 'hidden' },
          });
        });
      });
    });
  });
});
