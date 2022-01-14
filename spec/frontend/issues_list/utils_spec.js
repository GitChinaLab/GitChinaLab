import {
  apiParams,
  apiParamsWithSpecialValues,
  filteredTokens,
  filteredTokensWithSpecialValues,
  locationSearch,
  locationSearchWithSpecialValues,
  urlParams,
  urlParamsWithSpecialValues,
} from 'jest/issues_list/mock_data';
import {
  defaultPageSizeParams,
  DUE_DATE_VALUES,
  largePageSizeParams,
  RELATIVE_POSITION_ASC,
  urlSortParams,
} from '~/issues_list/constants';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  getDueDateValue,
  getFilterTokens,
  getInitialPageParams,
  getSortKey,
  getSortOptions,
} from '~/issues_list/utils';

describe('getInitialPageParams', () => {
  it.each(Object.keys(urlSortParams))(
    'returns the correct page params for sort key %s',
    (sortKey) => {
      const expectedPageParams =
        sortKey === RELATIVE_POSITION_ASC ? largePageSizeParams : defaultPageSizeParams;

      expect(getInitialPageParams(sortKey)).toBe(expectedPageParams);
    },
  );
});

describe('getSortKey', () => {
  it.each(Object.keys(urlSortParams))('returns %s given the correct inputs', (sortKey) => {
    const sort = urlSortParams[sortKey];
    expect(getSortKey(sort)).toBe(sortKey);
  });
});

describe('getDueDateValue', () => {
  it.each(DUE_DATE_VALUES)('returns the argument when it is `%s`', (value) => {
    expect(getDueDateValue(value)).toBe(value);
  });

  it('returns undefined when the argument is invalid', () => {
    expect(getDueDateValue('invalid value')).toBeUndefined();
  });
});

describe('getSortOptions', () => {
  describe.each`
    hasIssueWeightsFeature | hasBlockedIssuesFeature | length | containsWeight | containsBlocking
    ${false}               | ${false}                | ${9}   | ${false}       | ${false}
    ${true}                | ${false}                | ${10}  | ${true}        | ${false}
    ${false}               | ${true}                 | ${10}  | ${false}       | ${true}
    ${true}                | ${true}                 | ${11}  | ${true}        | ${true}
  `(
    'when hasIssueWeightsFeature=$hasIssueWeightsFeature and hasBlockedIssuesFeature=$hasBlockedIssuesFeature',
    ({
      hasIssueWeightsFeature,
      hasBlockedIssuesFeature,
      length,
      containsWeight,
      containsBlocking,
    }) => {
      const sortOptions = getSortOptions(hasIssueWeightsFeature, hasBlockedIssuesFeature);

      it('returns the correct length of sort options', () => {
        expect(sortOptions).toHaveLength(length);
      });

      it(`${containsWeight ? 'contains' : 'does not contain'} weight option`, () => {
        expect(sortOptions.some((option) => option.title === 'Weight')).toBe(containsWeight);
      });

      it(`${containsBlocking ? 'contains' : 'does not contain'} blocking option`, () => {
        expect(sortOptions.some((option) => option.title === 'Blocking')).toBe(containsBlocking);
      });
    },
  );
});

describe('getFilterTokens', () => {
  it('returns filtered tokens given "window.location.search"', () => {
    expect(getFilterTokens(locationSearch)).toEqual(filteredTokens);
  });

  it('returns filtered tokens given "window.location.search" with special values', () => {
    expect(getFilterTokens(locationSearchWithSpecialValues)).toEqual(
      filteredTokensWithSpecialValues,
    );
  });
});

describe('convertToApiParams', () => {
  it('returns api params given filtered tokens', () => {
    expect(convertToApiParams(filteredTokens)).toEqual(apiParams);
  });

  it('returns api params given filtered tokens with special values', () => {
    expect(convertToApiParams(filteredTokensWithSpecialValues)).toEqual(apiParamsWithSpecialValues);
  });
});

describe('convertToUrlParams', () => {
  it('returns url params given filtered tokens', () => {
    expect(convertToUrlParams(filteredTokens)).toEqual(urlParams);
  });

  it('returns url params given filtered tokens with special values', () => {
    expect(convertToUrlParams(filteredTokensWithSpecialValues)).toEqual(urlParamsWithSpecialValues);
  });
});

describe('convertToSearchQuery', () => {
  it('returns search string given filtered tokens', () => {
    expect(convertToSearchQuery(filteredTokens)).toBe('find issues');
  });
});
