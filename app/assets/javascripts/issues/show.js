import loadAwardsHandler from '~/awards_handler';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { initIssuableHeaderWarnings, initIssuableSidebar } from '~/issuable';
import { IssuableType } from '~/vue_shared/issuable/show/constants';
import Issue from '~/issues/issue';
import { initIncidentApp, initIncidentHeaderActions } from '~/issues/show/incident';
import { initIssuableApp, initIssueHeaderActions } from '~/issues/show/issue';
import { parseIssuableData } from '~/issues/show/utils/parse_data';
import initNotesApp from '~/notes';
import { store } from '~/notes/stores';
import initRelatedMergeRequestsApp from '~/issues/related_merge_requests';
import initSentryErrorStackTraceApp from '~/issues/sentry_error_stack_trace';
import ZenMode from '~/zen_mode';

export default function initShowIssue() {
  initNotesApp();

  const initialDataEl = document.getElementById('js-issuable-app');
  const { issueType, ...issuableData } = parseIssuableData(initialDataEl);

  switch (issueType) {
    case IssuableType.Incident:
      initIncidentApp(issuableData);
      initIncidentHeaderActions(store);
      break;
    case IssuableType.Issue:
      initIssuableApp(issuableData, store);
      initIssueHeaderActions(store);
      break;
    default:
      initIssueHeaderActions(store);
      break;
  }

  initIssuableHeaderWarnings(store);
  initSentryErrorStackTraceApp();
  initRelatedMergeRequestsApp();

  import(/* webpackChunkName: 'design_management' */ '~/design_management')
    .then((module) => module.default())
    .catch(() => {});

  new ZenMode(); // eslint-disable-line no-new

  if (issueType !== IssuableType.TestCase) {
    const awardEmojiEl = document.getElementById('js-vue-awards-block');

    new Issue(); // eslint-disable-line no-new
    new ShortcutsIssuable(); // eslint-disable-line no-new
    initIssuableSidebar();
    if (awardEmojiEl) {
      import('~/emoji/awards_app')
        .then((m) => m.default(awardEmojiEl))
        .catch(() => {});
    } else {
      loadAwardsHandler();
    }
  }
}
