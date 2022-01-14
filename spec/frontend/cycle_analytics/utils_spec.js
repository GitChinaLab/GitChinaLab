import metricsData from 'test_fixtures/projects/analytics/value_stream_analytics/summary.json';
import {
  transformStagesForPathNavigation,
  medianTimeToParsedSeconds,
  formatMedianValues,
  filterStagesByHiddenStatus,
  prepareTimeMetricsData,
  buildCycleAnalyticsInitialData,
} from '~/cycle_analytics/utils';
import { slugify } from '~/lib/utils/text_utility';
import {
  selectedStage,
  allowedStages,
  stageMedians,
  pathNavIssueMetric,
  rawStageMedians,
} from './mock_data';

describe('Value stream analytics utils', () => {
  describe('transformStagesForPathNavigation', () => {
    const stages = allowedStages;
    const response = transformStagesForPathNavigation({
      stages,
      medians: stageMedians,
      selectedStage,
    });

    describe('transforms the data as expected', () => {
      it('returns an array of stages', () => {
        expect(Array.isArray(response)).toBe(true);
        expect(response.length).toBe(stages.length);
      });

      it('selects the correct stage', () => {
        const selected = response.filter((stage) => stage.selected === true)[0];

        expect(selected.title).toBe(selectedStage.title);
      });

      it('includes the correct metric for the associated stage', () => {
        const issue = response.filter((stage) => stage.name === 'issue')[0];

        expect(issue.metric).toBe(pathNavIssueMetric);
      });
    });
  });

  describe('medianTimeToParsedSeconds', () => {
    it.each`
      value      | result
      ${1036800} | ${'1w'}
      ${259200}  | ${'3d'}
      ${172800}  | ${'2d'}
      ${86400}   | ${'1d'}
      ${1000}    | ${'16m'}
      ${61}      | ${'1m'}
      ${59}      | ${'<1m'}
      ${0}       | ${'-'}
    `('will correctly parse $value seconds into $result', ({ value, result }) => {
      expect(medianTimeToParsedSeconds(value)).toBe(result);
    });
  });

  describe('formatMedianValues', () => {
    const calculatedMedians = formatMedianValues(rawStageMedians);

    it('returns an object with each stage and their median formatted for display', () => {
      rawStageMedians.forEach(({ id, value }) => {
        expect(calculatedMedians).toMatchObject({ [id]: medianTimeToParsedSeconds(value) });
      });
    });
  });

  describe('filterStagesByHiddenStatus', () => {
    const hiddenStages = [{ title: 'three', hidden: true }];
    const visibleStages = [
      { title: 'one', hidden: false },
      { title: 'two', hidden: false },
    ];
    const mockStages = [...visibleStages, ...hiddenStages];

    it.each`
      isHidden     | result
      ${false}     | ${visibleStages}
      ${undefined} | ${hiddenStages}
      ${true}      | ${hiddenStages}
    `('with isHidden=$isHidden returns matching stages', ({ isHidden, result }) => {
      expect(filterStagesByHiddenStatus(mockStages, isHidden)).toEqual(result);
    });
  });

  describe('prepareTimeMetricsData', () => {
    let prepared;
    const [first, second] = metricsData;
    const firstKey = slugify(first.title);
    const secondKey = slugify(second.title);

    beforeEach(() => {
      prepared = prepareTimeMetricsData([first, second], {
        [firstKey]: { description: 'Is a value that is good' },
      });
    });

    it('will add a `key` based on the title', () => {
      expect(prepared).toMatchObject([{ key: firstKey }, { key: secondKey }]);
    });

    it('will add a `label` key', () => {
      expect(prepared).toMatchObject([{ label: 'New Issues' }, { label: 'Commits' }]);
    });

    it('will add a popover description using the key if it is provided', () => {
      expect(prepared).toMatchObject([
        { description: 'Is a value that is good' },
        { description: '' },
      ]);
    });
  });

  describe('buildCycleAnalyticsInitialData', () => {
    let res = null;
    const projectId = '5';
    const createdAfter = '2021-09-01';
    const createdBefore = '2021-11-06';
    const groupId = '146';
    const groupPath = 'fake-group';
    const fullPath = 'fake-group/fake-project';
    const labelsPath = '/fake-group/fake-project/-/labels.json';
    const milestonesPath = '/fake-group/fake-project/-/milestones.json';
    const requestPath = '/fake-group/fake-project/-/value_stream_analytics';

    const rawData = {
      projectId,
      createdBefore,
      createdAfter,
      fullPath,
      requestPath,
      labelsPath,
      milestonesPath,
      groupId,
      groupPath,
    };

    describe('with minimal data', () => {
      beforeEach(() => {
        res = buildCycleAnalyticsInitialData(rawData);
      });

      it('sets the projectId', () => {
        expect(res.projectId).toBe(parseInt(projectId, 10));
      });

      it('sets the date range', () => {
        expect(res.createdBefore).toEqual(new Date(createdBefore));
        expect(res.createdAfter).toEqual(new Date(createdAfter));
      });

      it('sets the endpoints', () => {
        const { endpoints } = res;
        expect(endpoints.fullPath).toBe(fullPath);
        expect(endpoints.requestPath).toBe(requestPath);
        expect(endpoints.labelsPath).toBe(labelsPath);
        expect(endpoints.milestonesPath).toBe(milestonesPath);
        expect(endpoints.groupId).toBe(parseInt(groupId, 10));
        expect(endpoints.groupPath).toBe(groupPath);
      });

      it('returns null when there is no stage', () => {
        expect(res.selectedStage).toBeNull();
      });

      it('returns false for missing features', () => {
        expect(res.features.cycleAnalyticsForGroups).toBe(false);
      });
    });

    describe('with a stage set', () => {
      const jsonStage = '{"id":"fakeStage","title":"fakeStage"}';

      it('parses the selectedStage data', () => {
        res = buildCycleAnalyticsInitialData({ ...rawData, stage: jsonStage });

        const { selectedStage: stage } = res;

        expect(stage.id).toBe('fakeStage');
        expect(stage.title).toBe('fakeStage');
      });
    });

    describe('with features set', () => {
      const fakeFeatures = { cycleAnalyticsForGroups: true };

      it('sets the feature flags', () => {
        res = buildCycleAnalyticsInitialData({
          ...rawData,
          gon: { licensed_features: fakeFeatures },
        });
        expect(res.features).toEqual(fakeFeatures);
      });
    });
  });
});
