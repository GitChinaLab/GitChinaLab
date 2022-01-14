import { PROJECT_BADGE } from '~/badges/constants';
import initLegacyConfirmDangerModal from '~/confirm_danger_modal';
import initConfirmDanger from '~/init_confirm_danger';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import initFilePickers from '~/file_pickers';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import initProjectDeleteButton from '~/projects/project_delete_button';
import initServiceDesk from '~/projects/settings_service_desk';
import initTransferProjectForm from '~/projects/settings/init_transfer_project_form';
import initSearchSettings from '~/search_settings';
import initSettingsPanels from '~/settings_panels';
import UserCallout from '~/user_callout';
import initTopicsTokenSelector from '~/projects/settings/topics';
import initProjectPermissionsSettings from '../shared/permissions';
import initProjectLoadingSpinner from '../shared/save_project_loader';

initFilePickers();
initLegacyConfirmDangerModal();
initConfirmDanger();
initSettingsPanels();
initProjectDeleteButton();
mountBadgeSettings(PROJECT_BADGE);

new UserCallout({ className: 'js-service-desk-callout' }); // eslint-disable-line no-new
initServiceDesk();

initProjectLoadingSpinner();
initProjectPermissionsSettings();
initTransferProjectForm();

dirtySubmitFactory(document.querySelectorAll('.js-general-settings-form, .js-mr-settings-form'));

initSearchSettings();
initTopicsTokenSelector();
