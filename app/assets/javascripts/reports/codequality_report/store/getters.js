import { spriteIcon } from '~/lib/utils/common_utils';
import { sprintf, s__ } from '~/locale';
import { LOADING, ERROR, SUCCESS, STATUS_NOT_FOUND } from '../../constants';

export const hasCodequalityIssues = (state) =>
  Boolean(state.newIssues?.length || state.resolvedIssues?.length);

export const codequalityStatus = (state) => {
  if (state.isLoading) {
    return LOADING;
  }
  if (state.hasError) {
    return ERROR;
  }

  return SUCCESS;
};

export const codequalityText = (state) => {
  const { newIssues, resolvedIssues } = state;
  let text;
  if (!newIssues.length && !resolvedIssues.length) {
    text = s__('ciReport|No changes to code quality');
  } else if (newIssues.length && resolvedIssues.length) {
    text = sprintf(
      s__(`ciReport|Code quality scanning detected %{issueCount} changes in merged results`),
      {
        issueCount: newIssues.length + resolvedIssues.length,
      },
    );
  } else if (resolvedIssues.length) {
    text = s__(`ciReport|Code quality improved`);
  } else if (newIssues.length) {
    text = s__(`ciReport|Code quality degraded`);
  }

  return text;
};

export const codequalityPopover = (state) => {
  if (state.status === STATUS_NOT_FOUND) {
    return {
      title: s__('ciReport|Base pipeline codequality artifact not found'),
      content: sprintf(
        s__('ciReport|%{linkStartTag}Learn more about codequality reports %{linkEndTag}'),
        {
          linkStartTag: `<a href="${state.helpPath}" target="_blank" rel="noopener noreferrer">`,
          linkEndTag: `${spriteIcon('external-link', 's16')}</a>`,
        },
        false,
      ),
    };
  }
  return {};
};
