module PaypalService::Jobs
  class RetryAndCleanTokens < ApplicationJob

    def perform(clean_time_limit)
      payments_api.retry_and_clean_tokens(clean_time_limit)
    end


    private

    def payments_api
      PaypalService::API::Api.payments
    end
  end
end
