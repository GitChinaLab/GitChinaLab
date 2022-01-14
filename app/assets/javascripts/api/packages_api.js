import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const PUBLISH_PACKAGE_PATH =
  '/api/:version/projects/:id/packages/generic/:package_name/:package_version/:file_name';

export function publishPackage(
  { projectPath, name, version, fileName, files },
  options,
  axiosOptions = {},
) {
  const url = buildApiUrl(PUBLISH_PACKAGE_PATH)
    .replace(':id', encodeURIComponent(projectPath))
    .replace(':package_name', name)
    .replace(':package_version', version)
    .replace(':file_name', fileName);

  const defaults = {
    status: 'default',
  };

  const formData = new FormData();
  formData.append('file', files[0]);

  return axios.put(url, formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
    params: Object.assign(defaults, options),
    ...axiosOptions,
  });
}
