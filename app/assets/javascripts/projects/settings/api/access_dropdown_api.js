import axios from '~/lib/utils/axios_utils';

const USERS_PATH = '/-/autocomplete/users.json';
const GROUPS_PATH = '/-/autocomplete/project_groups.json';
const DEPLOY_KEYS_PATH = '/-/autocomplete/deploy_keys_with_owners.json';

const buildUrl = (urlRoot, url) => {
  let newUrl;
  if (urlRoot != null) {
    newUrl = urlRoot.replace(/\/$/, '') + url;
  }
  return newUrl;
};

export const getUsers = (query) => {
  return axios.get(buildUrl(gon.relative_url_root || '', USERS_PATH), {
    params: {
      search: query,
      per_page: 20,
      active: true,
      project_id: gon.current_project_id,
      push_code: true,
    },
  });
};

export const getGroups = () => {
  return axios.get(buildUrl(gon.relative_url_root || '', GROUPS_PATH), {
    params: {
      project_id: gon.current_project_id,
    },
  });
};

export const getDeployKeys = (query) => {
  return axios.get(buildUrl(gon.relative_url_root || '', DEPLOY_KEYS_PATH), {
    params: {
      search: query,
      per_page: 20,
      active: true,
      project_id: gon.current_project_id,
      push_code: true,
    },
  });
};
