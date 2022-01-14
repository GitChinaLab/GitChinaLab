import $ from 'jquery';
import { Rails } from '~/lib/utils/rails_ujs';
import { rstrip } from './lib/utils/common_utils';

function openConfirmDangerModal($form, $modal, text) {
  const $input = $('.js-legacy-confirm-danger-input', $modal);
  $input.val('');

  $('.js-confirm-text', $modal).text(text || '');
  $modal.modal('show');

  const confirmTextMatch = $('.js-legacy-confirm-danger-match', $modal).text();
  const $submit = $('.js-legacy-confirm-danger-submit', $modal);
  $submit.disable();
  $input.focus();

  // eslint-disable-next-line @gitlab/no-global-event-off
  $input.off('input').on('input', function handleInput() {
    const confirmText = rstrip($(this).val());
    if (confirmText === confirmTextMatch) {
      $submit.enable();
    } else {
      $submit.disable();
    }
  });

  // eslint-disable-next-line @gitlab/no-global-event-off
  $('.js-legacy-confirm-danger-submit', $modal)
    .off('click')
    .on('click', () => {
      if ($form.data('remote')) {
        Rails.fire($form[0], 'submit');
      } else {
        $form.submit();
      }
    });
}

function getModal($btn) {
  const $modal = $btn.prev('.modal');

  if ($modal.length) {
    return $modal;
  }

  return $('#modal-confirm-danger');
}

export default function initConfirmDangerModal() {
  $(document).on('click', '.js-legacy-confirm-danger', (e) => {
    const $btn = $(e.target);
    const checkFieldName = $btn.data('checkFieldName');
    const checkFieldCompareValue = $btn.data('checkCompareValue');
    const checkFieldVal = parseInt($(`[name="${checkFieldName}"]`).val(), 10);

    if (!checkFieldName || checkFieldVal < checkFieldCompareValue) {
      e.preventDefault();
      const $form = $btn.closest('form');
      const $modal = getModal($btn);
      const text = $btn.data('confirmDangerMessage');
      openConfirmDangerModal($form, $modal, text);
    }
  });
}
