import $ from 'jquery';
import Vue from 'vue';
import initDatePicker from '~/behaviors/date_picker';
import GLForm from '~/gl_form';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Milestone from '~/milestones/milestone';
import Sidebar from '~/right_sidebar';
import MountMilestoneSidebar from '~/sidebar/mount_milestone_sidebar';
import Translate from '~/vue_shared/translate';
import ZenMode from '~/zen_mode';
import DeleteMilestoneModal from './components/delete_milestone_modal.vue';
import PromoteMilestoneModal from './components/promote_milestone_modal.vue';
import eventHub from './event_hub';

export function initForm(initGFM = true) {
  new ZenMode(); // eslint-disable-line no-new
  initDatePicker();

  // eslint-disable-next-line no-new
  new GLForm($('.milestone-form'), {
    emojis: true,
    members: initGFM,
    issues: initGFM,
    mergeRequests: initGFM,
    epics: initGFM,
    milestones: initGFM,
    labels: initGFM,
    snippets: initGFM,
    vulnerabilities: initGFM,
  });
}

export function initShow() {
  new Milestone(); // eslint-disable-line no-new
  new Sidebar(); // eslint-disable-line no-new
  new MountMilestoneSidebar(); // eslint-disable-line no-new
}

export function initPromoteMilestoneModal() {
  Vue.use(Translate);

  const promoteMilestoneModal = document.getElementById('promote-milestone-modal');
  if (!promoteMilestoneModal) {
    return null;
  }

  return new Vue({
    el: promoteMilestoneModal,
    render(createElement) {
      return createElement(PromoteMilestoneModal);
    },
  });
}

export function initDeleteMilestoneModal() {
  Vue.use(Translate);

  const onRequestFinished = ({ milestoneUrl, successful }) => {
    const button = document.querySelector(
      `.js-delete-milestone-button[data-milestone-url="${milestoneUrl}"]`,
    );

    if (!successful) {
      button.removeAttribute('disabled');
    }

    button.querySelector('.js-loading-icon').classList.add('hidden');
  };

  const deleteMilestoneButtons = document.querySelectorAll('.js-delete-milestone-button');

  const onRequestStarted = (milestoneUrl) => {
    const button = document.querySelector(
      `.js-delete-milestone-button[data-milestone-url="${milestoneUrl}"]`,
    );
    button.setAttribute('disabled', '');
    button.querySelector('.js-loading-icon').classList.remove('hidden');
    eventHub.$once('deleteMilestoneModal.requestFinished', onRequestFinished);
  };

  return new Vue({
    el: '#js-delete-milestone-modal',
    data() {
      return {
        modalProps: {
          milestoneId: -1,
          milestoneTitle: '',
          milestoneUrl: '',
          issueCount: -1,
          mergeRequestCount: -1,
        },
      };
    },
    mounted() {
      eventHub.$on('deleteMilestoneModal.props', this.setModalProps);
      deleteMilestoneButtons.forEach((button) => {
        button.removeAttribute('disabled');
        button.addEventListener('click', () => {
          this.$root.$emit(BV_SHOW_MODAL, 'delete-milestone-modal');
          eventHub.$once('deleteMilestoneModal.requestStarted', onRequestStarted);

          this.setModalProps({
            milestoneId: parseInt(button.dataset.milestoneId, 10),
            milestoneTitle: button.dataset.milestoneTitle,
            milestoneUrl: button.dataset.milestoneUrl,
            issueCount: parseInt(button.dataset.milestoneIssueCount, 10),
            mergeRequestCount: parseInt(button.dataset.milestoneMergeRequestCount, 10),
          });
        });
      });
    },
    methods: {
      setModalProps(modalProps) {
        this.modalProps = modalProps;
      },
    },
    render(createElement) {
      return createElement(DeleteMilestoneModal, {
        props: this.modalProps,
      });
    },
  });
}
