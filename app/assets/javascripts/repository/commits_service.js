import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { normalizeData } from 'ee_else_ce/repository/utils/commit';
import createFlash from '~/flash';
import { COMMIT_BATCH_SIZE, I18N_COMMIT_DATA_FETCH_ERROR } from './constants';

let requestedOffsets = [];
let fetchedBatches = [];

export const isRequested = (offset) => requestedOffsets.includes(offset);

export const resetRequestedCommits = () => {
  requestedOffsets = [];
  fetchedBatches = [];
};

const addRequestedOffset = (offset) => {
  if (isRequested(offset) || offset < 0) {
    return;
  }

  requestedOffsets.push(offset);
};

const removeLeadingSlash = (path) => path.replace(/^\//, '');

const fetchData = (projectPath, path, ref, offset) => {
  if (fetchedBatches.includes(offset) || offset < 0) {
    return [];
  }

  fetchedBatches.push(offset);

  const url = joinPaths(
    gon.relative_url_root || '/',
    projectPath,
    '/-/refs/',
    ref,
    '/logs_tree/',
    encodeURIComponent(removeLeadingSlash(path)),
  );

  return axios
    .get(url, { params: { format: 'json', offset } })
    .then(({ data }) => normalizeData(data, path))
    .catch(() => createFlash({ message: I18N_COMMIT_DATA_FETCH_ERROR }));
};

export const loadCommits = async (projectPath, path, ref, offset) => {
  if (isRequested(offset)) {
    return [];
  }

  // We fetch in batches of 25, so this ensures we don't refetch
  Array.from(Array(COMMIT_BATCH_SIZE)).forEach((_, i) => addRequestedOffset(offset + i));

  const commits = await fetchData(projectPath, path, ref, offset);

  return commits;
};
