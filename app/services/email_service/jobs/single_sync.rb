module EmailService::Jobs
  class SingleSync < ApplicationJob

    Synchronize = EmailService::SES::Synchronize

    include DelayedSentryNotification

    def perform(community_id, id)
      Synchronize.run_single_synchronization!(
        community_id: community_id,
        id: id,
        ses_client: ses_client)
    end


    private

    def ses_client
      EmailService::API::Api.ses_client
    end
  end
end
