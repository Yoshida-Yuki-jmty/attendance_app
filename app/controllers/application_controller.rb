class ApplicationController < ActionController::Base
  include SessionAuth
  include BusinessDateable
end
