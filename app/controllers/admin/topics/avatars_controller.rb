# frozen_string_literal: true

class Admin::Topics::AvatarsController < Admin::ApplicationController
  feature_category :projects

  def destroy
    @topic = Projects::Topic.find(params[:topic_id])

    @topic.remove_avatar!
    @topic.save

    redirect_to edit_admin_topic_path(@topic), status: :found
  end
end
