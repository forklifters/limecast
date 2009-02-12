class UsersController < ApplicationController
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge]

  # render new.html.erb
  def new
  end

  def index
    @users = User.all(:order => :login)
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    if self.current_user = @user = User.authenticate(params[:user][:login], params[:user][:password])
      respond_to do |format|
        format.html { redirect_back_or_default('/') }
        format.js { render :layout => false }
      end
      return
    end

    @user = User.new(params[:user].keep_keys([:email, :password, :login]))
    @user.state = 'passive'
    @user.register! if @user.valid?
    if @user.errors.empty?
      self.current_user = @user

      claim_all

      respond_to do |format|
        format.html do
          redirect_back_or_default('/')
        end
        format.js { render :layout => false }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.js { render :layout => false }
      end
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate!
    end
    redirect_back_or_default('/')
  end

  def suspend
    @user.suspend!
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend!
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end

  def forgot_password
    render
  end

  def reset_password
    @code = params[:code] or unauthorized
    @user = User.find_by_reset_password_code(@code) or unauthorized

    if request.post?
      if @user.update_attributes(params[:user])
        @user.reset_password_code = nil
        @user.reset_password_sent_at = nil
        @user.save

        self.current_user = @user
        redirect_to user_url(@user)
      end
    end
  end

  def send_password
    @user = User.find_by_email(params[:email]) unless params[:email].blank?

    if @user
      if @user.reset_password_sent_at and @user.reset_password_sent_at > 10.minutes.ago then
        flash[:notice] = "We have already sent you a note. Please check your email."
      else
        @user.generate_reset_password_code
        @user.save
        UserMailer.deliver_reset_password(@user)
        flash[:notice] = "Please check your email for a note from us."
      end
      redirect_to new_session_path
    else
      render :action => 'forgot_password'
    end
  end

  def show
    @user = User.find_by_login(params[:user])
  end

  def update
    @user = User.find_by_login(params[:user])
    @user == current_user || unauthorized

    if @user.update_attributes!(params[:user_attr].keep_keys([:email]))
      reconfirm_email(@user)
    end

    redirect_to user_url(:user => @user)
  end

  def info
    raise Unauthenticated unless current_user && current_user.admin?
    @user = User.find_by_login(params[:user])
    render :layout => false
  end

protected
  def find_user
    @user = User.find(params[:id])
  end

  def reconfirm_email(user)
    user.change_email!
    UserMailer.deliver_signup_notification(user)
  end

end
