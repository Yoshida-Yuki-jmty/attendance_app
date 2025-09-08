module AuthHelpers
  def sign_in(user, password: 'password')
    post session_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  def sign_out
    delete session_path
    follow_redirect! if response.redirect?
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
