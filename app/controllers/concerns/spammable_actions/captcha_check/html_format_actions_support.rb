# frozen_string_literal: true

# This module should *ONLY* be included if needed to support forms submits with HTML MIME type.
# In other words, forms handled by actions which use a `respond_to` of `format.html`.
#
# If the request is handled by actions via `format.json`, for example, for all Javascript based form
# submissions and Vue components which use Apollo and Axios, then the corresponding module
# which supports JSON format should be used instead.
module SpammableActions::CaptchaCheck::HtmlFormatActionsSupport
  extend ActiveSupport::Concern
  include SpammableActions::Attributes
  include SpammableActions::CaptchaCheck::Common

  included do
    before_action :convert_html_spam_params_to_headers, only: [:create, :update]
  end

  private

  def with_captcha_check_html_format(&block)
    captcha_render_lambda = -> { render :captcha_check }
    with_captcha_check_common(captcha_render_lambda: captcha_render_lambda, &block)
  end

  # Convert spam/CAPTCHA values from form field params to headers, because all spam-related services
  # expect these values to be passed as headers.
  #
  # The 'g-recaptcha-response' field name comes from `Recaptcha::ClientHelper#recaptcha_tags` in the
  # recaptcha gem. This is a field which is automatically included by calling the
  # `#recaptcha_tags` method within a HAML template's form.
  def convert_html_spam_params_to_headers
    request.headers['X-GitLab-Captcha-Response'] = params['g-recaptcha-response'] if params['g-recaptcha-response']
    request.headers['X-GitLab-Spam-Log-Id'] = params[:spam_log_id] if params[:spam_log_id]
  end
end
