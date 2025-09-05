module PathPrefixHelper
  def login_path   = new_session_path   # GET /session/new
  def logout_path  = session_path       # DELETE /session
end
