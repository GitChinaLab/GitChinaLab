import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import issuableInitBulkUpdateSidebar from '~/issuable/bulk_update_sidebar/issuable_init_bulk_update_sidebar';
import { mountIssuablesListApp, mountIssuesListApp } from '~/issues_list';
import initManualOrdering from '~/issues/manual_ordering';
import { FILTERED_SEARCH } from '~/filtered_search/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import projectSelect from '~/project_select';

if (gon.features?.vueIssuesList) {
  mountIssuesListApp();
} else {
  const ISSUE_BULK_UPDATE_PREFIX = 'issue_';

  IssuableFilteredSearchTokenKeys.addExtraTokensForIssues();
  IssuableFilteredSearchTokenKeys.removeTokensForKeys('release');
  issuableInitBulkUpdateSidebar.init(ISSUE_BULK_UPDATE_PREFIX);

  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    isGroupDecendent: true,
    useDefaultState: true,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });
  projectSelect();
  initManualOrdering();

  if (gon.features?.vueIssuablesList) {
    mountIssuablesListApp();
  }
}
