# frozen_string_literal: true

class ApplicationController < ActionController::Base
    # Skip Csrf validation to prevent Webhooks Failure
    skip_forgery_protection
end
