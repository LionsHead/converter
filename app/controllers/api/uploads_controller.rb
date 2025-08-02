module Api
  class UploadsController < ApplicationController
    protect_from_forgery with: :null_session

  end
end
