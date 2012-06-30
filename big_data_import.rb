class BigDataImport < Sinatra::Base
  require 'sinatra/reloader' if development?
  require File.join(File.dirname(__FILE__), 'lib', 'db')

  configure do
    set :raise_errors, true
    set :sessions, true
  end
  configure :development do
    register Sinatra::Reloader
  end

  before do
    session[:authorized] ||= false
    redirect '/login' unless session[:authorized] || request.path_info.match(/\/login/)
  end

  get "/" do
    erb :index
  end

  post "/" do
    if params[:file] && (tmpfile = params[:file][:tempfile])
      Import.create(:filename => params[:file][:filename], :created_at => Time.now.utc)
      line_count = 0
      revenue = 0
      field_names = nil
      while line = tmpfile.gets
        line.chomp!
        if line_count == 0
          headers = line.split(/\t/)
          field_names = headers.map { |field| field.sub(/ /, '_').to_sym }
        else
          fields = line.split(/\t/)
          db_params = Hash[*field_names.zip(fields).flatten]
          purchase_history = PurchaseHistory.import_text_file_record(db_params)
          revenue += purchase_history.revenue
        end
        line_count += 1
      end
    else
      return erb :index
    end
    erb :success, :locals => { :line_count => line_count, :revenue => revenue }
  end

  # OpenID
  helpers do
    def openid_consumer
      filestore = OpenID::Store::Filesystem.new(File.join(File.dirname(__FILE__), 'tmp', 'openid'))
      @openid_consumer ||= OpenID::Consumer.new(session, filestore)
    end

    def root_url
      request.url.match(/(^.*\/{2}[^\/]*)/)[1]
    end
  end

  get '/login' do
    erb :login
  end

  post '/login/openid' do
    openid = params[:openid_identifier]
    begin
      oidreq = openid_consumer.begin(openid)
    rescue OpenID::DiscoveryFailure => why
      erb :login_feedback, :locals => { :feedback => "Sorry, we couldn't find your login: #{openid}." }
    else
      redirect oidreq.redirect_url(root_url, root_url + "/login/openid/complete")
    end
  end

  get '/login/openid/complete' do
    oidresp = openid_consumer.complete(params, request.url)
    openid = oidresp.display_identifier

    case oidresp.status
      when OpenID::Consumer::FAILURE
        erb :login_feedback, :locals => { :feedback => "Sorry, we could not authenticate you with this login: #{openid}." }
      when OpenID::Consumer::SETUP_NEEDED
        erb :login_feedback, :locals => { :feedback => "Immediate request failed - Setup Needed" }
      when OpenID::Consumer::CANCEL
        erb :login_feedback, :locals => { :feedback => "Login cancelled." }
      when OpenID::Consumer::SUCCESS
        session[:authorized] = true
        redirect '/'
    end
  end

  get '/logout' do
    session.clear
    [ 302, { 'Location' => '/' }, [] ]
  end

end
