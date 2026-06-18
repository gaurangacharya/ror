class CommentCreatedJob < ApplicationJob

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(comment_id, community_id)
    comment = Comment.find(comment_id)
    community = Community.find(community_id)
    comment.send_notifications(community)
  end

end
