/* eslint-disable no-new */

import $ from 'jquery';
import IssuableForm from 'ee_else_ce/issuable/issuable_form';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import Diff from '~/diff';
import GLForm from '~/gl_form';
import LabelsSelect from '~/labels/labels_select';
import MilestoneSelect from '~/milestones/milestone_select';
import IssuableTemplateSelectors from '~/issuable/issuable_template_selectors';

export default () => {
  new Diff();
  new ShortcutsNavigation();
  new GLForm($('.merge-request-form'));
  new IssuableForm($('.merge-request-form'));
  new LabelsSelect();
  new MilestoneSelect();
  new IssuableTemplateSelectors({
    warnTemplateOverride: true,
  });
};
