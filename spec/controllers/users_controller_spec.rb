require File.dirname(__FILE__) + '/../spec_helper'

# Be sure to include AuthenticatedTestHelper in spec/spec_helper.rb instead
# Then, you can remove it from this and the units test.
include AuthenticatedTestHelper

describe UsersController do

  it 'allows signup' do
    lambda do
      create_user(:format => 'html')
      response.should be_redirect
    end.should change(User, :count).by(1)
  end

  it 'requires login on signup' do
    lambda do
      create_user({}, {:login => nil})
      assigns[:user].errors.on(:login).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end

  it 'requires password on signup' do
    lambda do
      create_user({}, {:password => nil})
      assigns[:user].errors.on(:password).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end

  it 'requires email on signup' do
    lambda do
      create_user({}, {:email => nil})
      assigns[:user].errors.on(:email).should_not be_nil
      response.should be_success
    end.should_not change(User, :count)
  end

  def create_user(options = {}, user_options = {})
    post :create, {:user => { :login => 'quire', :email => 'quire@example.com',
      :password => 'quire'}.merge(user_options)}.merge(options)
  end
end

describe UsersController, "handling POST /users" do
  describe "when the email is bad" do
    before do
      xhr :post, :create, {:user => {:login => 'quire', :password => 'blah'}, :format => 'js'}
    end

    it 'should not succeed' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["success"].should be_false
    end

    it 'should render the create.js.erb template' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      response.should render_template('users/create.js.erb')
    end

    it 'should report that the email address should be entered' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["html"].should =~ /type your email/
    end
  end

  describe "when the password is bad" do
    before do
      post :create, :user => {:login => 'quire'}, :format => 'js'
    end

    it 'should not succeed' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["success"].should be_false
    end

    it 'should report that the password should be entered' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["html"].should =~ /choose a password/
    end
  end

  describe "when the user name is bad" do
    before do
      post :create, :user => {:email => "quire@example.com", :password => 'goodpass'}, :format => 'js'
    end

    it 'should not succeed' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["success"].should be_false
    end

    it 'should report that the user name should be entered' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["html"].should =~ /Choose your new user name/
    end
  end

  describe "when the email is known, and the password is right" do
    before do
      @user = Factory.create(:user, :login => 'quire', :password => 'quire', :email => 'quire@example.com')
      post :create, :user => {:login => 'quire', :password => 'quire'}, :format => 'js'
    end

    it 'should succeed' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["success"].should be_true
    end

    it 'should return the user link' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["html"].should =~ /quire \(0\)/
    end
  end

  describe "when the email is known, but the password is wrong" do
    before do
      @user = Factory.create(:user, :login => 'quire', :email => 'quire@example.com')

      post :create, :user => {:login => 'quire',
                              :email => 'quire@example.com',
                              :password => 'bad'}, :format => 'js'
    end

    it 'should not succeed' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["success"].should be_false
    end

    it 'should report that the email matches, but password is wrong' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["html"].should =~ /Sorry/
    end
  end

  describe "when the user name has already been taken" do
    before do
      @user = Factory.create(:user)
      post :create, :user => {:login => @user.login, :password => "goodpass", :email => "quire@example.com"}, :format => 'js'
    end

    it 'should not succeed' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["success"].should be_false
    end

    it 'should report that the username has already been taken' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      response.body.should =~ /Sorry, this user name is taken/
    end
  end

  def decode(response)
    ActiveSupport::JSON.decode(response.body.gsub("'", ""))
  end

  describe "when the new user can be created" do
    before do
      post :create, :user => {:login => "quire", :password => "goodpass", :email => "quire@example.com"}, :format => 'js'
    end

    it 'should succeed' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["success"].should be_true
    end

    it 'should return the link_to_user' do
      pending "Rails 2.3 response.body doesn't seem to come through in JS tests"
      decode(response)["html"].should =~ /quire \(0\)/
    end
  end
end

describe UsersController, "handling POST /user/:user" do
  describe "when user is the current user" do

    before(:each) do
      @user = Factory.create(:user)
      login(@user)

      post :update, :user_slug => @user.login, :user => {:email => "newemail@example.com"}
    end

    it "should find the user requested" do
      assigns(:user).id.should == @user.id
    end

    it "should update the user" do
      assigns(:user).reload.email.should == "newemail@example.com"
    end

    it "should set the user to pending" do
      assigns(:user).state.should == "pending"
      assigns(:user).activation_code.should_not be_nil
    end

    it "should redirect to the user page" do
      response.should redirect_to(user_url(:user_slug => @user))
    end
  end

  describe "when user is not authorized" do

    before(:each) do
      @user = Factory.create(:user)
      User.should_receive(:find_by_login).and_return(@user)
      @user.should_receive(:==).and_return(false)
      login(@user)
    end

    it "should raise Forbidden and be redirected to home" do
#      lambda {
        post :update, :user_slug => @user.login, :user => {:email => "newemail@example.com"}
        response.should redirect_to('/')
#      }.should raise_error(Forbidden)
    end
  end

  describe "when user enters malicious params" do

    before(:each) do
      @user = Factory.create(:user)
      login(@user)

      post :update, :user_slug => @user.login, :user => {:score => "584"}
    end

    it "should redirect to the podcasts list" do
      assigns(:user).score.should == 0
    end
  end
end

describe UsersController, "handling GET /user" do
  before(:each) do
    @user = Factory.create(:user)
    get :index
  end

  it 'should have a list of users' do
    assigns(:users).should == [@user]
  end
end

describe UsersController, "handling GET /claim" do
  before(:each) do
    get :claim
  end

  it 'should succeed' do
    response.should be_success
  end
  
  it 'should render the /claim template' do
    response.should render_template('users/claim')
  end
end

describe UsersController, "handling POST /claim" do
  before(:each) do
    @user = Factory.create(:passive_user)
  end

  def do_post(email)
    post :claim, :email => email
  end

  it 'should succeed if passive email is found' do
    do_post(@user.email)
    response.should redirect_to(new_session_path)
    flash[:notice].should == "Got it. Check your email for a link to set your password."
  end
  
  it 'should fail if passive email is not found' do
    do_post('jabberwocky@me.com')
    response.should render_template('claim')
    flash[:notice].should == "We could not find that email."
  end
  
  it 'should fail if passive email is found but claimed twice in 10 minutes' do
    do_post(@user.email) and do_post(@user.email)
    flash[:notice].should == "We have already sent you a note. Please check your email."
  end

  it 'should send an email if passive email is found' do
    lambda { do_post(@user.email) }.should change { ActionMailer::Base.deliveries.size }.by(1)
    ActionMailer::Base.deliveries.last.subject.should == "Claim your podcasts on LimeCast"
  end

  it 'should set user\'s reset_password_code if passive email is found' do
    lambda { do_post(@user.email) }.should change { @user.reload.reset_password_code }
    @user.reload.reset_password_sent_at.change(:sec => 0).should == Time.now.change(:sec => 0)
  end

  it "should not send email if passive email is not found" do
    lambda { do_post('jabberwocky@me.com') }.should_not change { ActionMailer::Base.deliveries.size }
    @user.reload.reset_password_sent_at.should be_nil
  end
end

describe UsersController, "handling GET /claim/:code" do
  before(:each) do
    @user = Factory.create(:passive_user)
    @user.generate_reset_password_code
    @user.save
  end

  def do_get(code)
    get :set_password, :code => code
  end
  
  it 'should not succeed with incorrect code' do
    do_get('jabberwocky')
    response.should be_redirect
  end
  
  it 'should succeed' do
    do_get(@user.reset_password_code)
    response.should be_success
  end
end

describe UsersController, "handling POST /claim/:code" do
  before(:each) do
    @user = Factory.create(:passive_user)
    @user.generate_reset_password_code
    @user.save
  end
  
  def do_post(code)
    post :set_password, :code => code, :user => {:password => '1234abcd'}
  end
  
  it 'should not succeed with incorrect code' do
    lambda { do_post('jabberwocky') }.should_not change { @user.crypted_password }
    response.should be_redirect
  end
  
  it 'should succceed with correct code' do
    do_post(@user.reset_password_code)
    response.should redirect_to(user_url(@user))
  end
  
  it 'should update the user\'s email' do
    lambda { do_post(@user.reset_password_code) }.should change { @user.reload.crypted_password }
  end
  
  
end