import MockAdapter from 'axios-mock-adapter';
import * as projectsApi from '~/api/projects_api';
import axios from '~/lib/utils/axios_utils';

describe('~/api/projects_api.js', () => {
  let mock;
  let originalGon;

  const projectId = 1;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    originalGon = window.gon;
    window.gon = { api_version: 'v7' };
  });

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
  });

  describe('getProjects', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');
    });

    it('retrieves projects from the correct URL and returns them in the response data', () => {
      const expectedUrl = '/api/v7/projects.json';
      const expectedParams = { params: { per_page: 20, search: '', simple: true } };
      const expectedProjects = [{ name: 'project 1' }];
      const query = '';
      const options = {};

      mock.onGet(expectedUrl).reply(200, { data: expectedProjects });

      return projectsApi.getProjects(query, options).then(({ data }) => {
        expect(axios.get).toHaveBeenCalledWith(expectedUrl, expectedParams);
        expect(data.data).toEqual(expectedProjects);
      });
    });
  });

  describe('importProjectMembers', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'post');
    });

    it('posts to the correct URL and returns the response message', () => {
      const targetId = 2;
      const expectedUrl = '/api/v7/projects/1/import_project_members/2';
      const expectedMessage = 'Successfully imported';

      mock.onPost(expectedUrl).replyOnce(200, expectedMessage);

      return projectsApi.importProjectMembers(projectId, targetId).then(({ data }) => {
        expect(axios.post).toHaveBeenCalledWith(expectedUrl);
        expect(data).toEqual(expectedMessage);
      });
    });
  });
});
