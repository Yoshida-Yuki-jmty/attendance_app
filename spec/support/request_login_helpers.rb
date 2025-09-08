module RequestLoginHelpers
  def sign_in(user, password: "password")
    post session_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end
end

  def sign_out
    delete session_path
    follow_redirect! if response.redirect?
  end

RSpec.configure do |config|
  config.include RequestLoginHelpers, type: :request
end
