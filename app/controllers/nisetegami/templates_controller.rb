require "nisetegami/application_controller"

module Nisetegami
  class TemplatesController < base_controller_class || ApplicationController
    before_filter Nisetegami.auth_filter if Nisetegami.auth_filter

    def index
      @templates = Template.recent
      params[:enabled] = params[:enabled] == 'true' ? true : false unless params[:enabled].blank?
      %w(enabled mailer mailer_action).each do |attr|
        @templates = @templates.where((attr == 'mailer_action' ? 'action' : attr) => params[attr]) unless params[attr].blank?
      end
      %w(name subject from reply_to cc bcc).each do |attr|
        @templates = @templates.where(["#{attr} LIKE ?", "%#{params[attr]}%"]) unless params[attr].blank?
      end
    end

    def actions
      render json: [''] + Nisetegami::Template.by_mailer(params[:mailer]).map(&:action)
    end

    def edit
      @template = Template.find(params[:id])
    end

    def update
      @template = Template.find(params[:id])
      if @template.update_attributes(params[:template])
        redirect_to templates_path, notice: t('nisetegami.templates.updated', template: @template.name)
      else
        render action: :edit
      end
    end

    def destroy
      templates = Template.where(id: params[:template_ids])
      template_names = templates.map(&:name).join(', ')
      templates.destroy_all
      redirect_to templates_path, notice: t('nisetegami.templates.destroyed', templates: template_names)
    end

    def test
      template = Template.find(params[:id])
      message = if params[:recipient] !~ Nisetegami.email_re
          {alert: t('nisetegami.templates.wrong_email')}
        elsif template.message(current_user.email, params[:template]).deliver
          {notice: t('nisetegami.templates.test_email_delivered')}
        else
          {alert: t('nisetegami.templates.test_email_not_delivered')}
        end
      redirect_to edit_template_path(template), message
    end

    protected

    def url_for(options = nil)
      super options
    rescue ActionController::RoutingError
      main_app.url_for(options)
    end

  end
end
