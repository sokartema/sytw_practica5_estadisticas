#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'uri'
require 'pp'
require 'omniauth-twitter'
require 'data_mapper'
require 'omniauth-oauth2'
require 'omniauth-google-oauth2'
require 'omniauth-facebook'
require 'xmlsimple'
require 'restclient'
require 'chartkick'
require_relative 'helpers'


set :environment, :development

set :protection , :except => :session_hijacking

helpers AppHelpers

use OmniAuth::Builder do
  config = YAML.load_file 'config/config.yml'
  provider :google_oauth2, config['gidentifier'], config['gsecret'],
  {
     :authorize_params => {
        :force_login => 'true'
      }
    }
	provider :twitter, config['tidentifier'], config['tsecret'],
  {
     :authorize_params => {
        :force_login => 'true'
      }
    }
  provider :facebook, config['fidentifier'], config['fsecret'],
    :scope => 'email, public_profile', :auth_type => 'reauthenticate'

end

configure :development do

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/my_shortened_urls.db" )
end

configure :production do
DataMapper.setup(:default,ENV['HEROKU_POSTGRESQL_RED_URL'])
end

DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true

require_relative 'model'

DataMapper.finalize

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!

use Rack::MethodOverride

Base = 36

enable :sessions
set :session_secret, '*&(^#234a)'


get '/' do

  @user = nil
  @webname = nil
  puts "inside get '/': #{params}"
  @list = Shortenedurl.all(:order => [ :id.asc ], :email => nil , :nickname => nil).shuffle.slice(0..2)
  @list2 = Shortenedurl.all(:order => [ :id.asc ], :email => nil , :nickname => nil, :url => session[:url])

  haml :index
end

post '/' do


  puts "inside post '/': #{params}"
  uri = URI::parse(params[:url])
  if uri.is_a? URI::HTTP or uri.is_a? URI::HTTPS then
    begin
      @short_url = Shortenedurl.first_or_create(:url => params[:url])
      session[:url] = params[:url]
    rescue Exception => e
      puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
      pp @short_url
      puts e.message
    end
  else
    logger.info "Error! <#{params[:url]}> is not a valid URL"
  end

  redirect '/'
end

get '/:shortened' do


  short_url = Shortenedurl.first(:id => params[:shortened].to_i(Base))


  ip = getremoteip(env)
  country = getremotecountry(ip)
  city= getremotecity(ip)
  time = Time.now

  begin

  visit = Visit.new(:created_at => time, :ip => ip, :city =>city, :country => country, :shortenedurl => short_url)
  visit.save

  rescue Exception => e

    puts e

  end

  redirect short_url.url, 301


end

get '/u/:shortened' do

  short_url = Shortenedurl.first(:opcional => params[:shortened])


  ip = getremoteip(env)
  country = getremotecountry(ip)
  city= getremotecity(ip)
  time = Time.now

  begin

  visit = Visit.new(:created_at => time, :ip => ip, :city =>city, :country => country, :shortenedurl => short_url)
  visit.save


  rescue Exception => e

    puts e

  end

  redirect short_url.url, 301

end

get '/auth/:name/callback' do
  config = YAML.load_file 'config/config.yml'
  case params[:name]
  when 'google_oauth2'
	  @auth = request.env['omniauth.auth']
	  session[:name] = @auth['info'].name
	  session[:email] = @auth['info'].email
	  redirect "/user/google"
  when 'twitter'
	  @auth = request.env['omniauth.auth']
	  session[:name] = @auth['info'].name
	  session[:nickname] = @auth['info'].nickname
      redirect "/user/twitter"
  when 'facebook'
    @auth = request.env['omniauth.auth']
    session[:name] = @auth['info'].name
    session[:email] = @auth['info'].email
    redirect "/user/facebook"
  else
  redirect "/"
  end

end

get '/user/:webname' do

  @error = session[:error1]
  session[:error1] = false

  if (session[:name] != nil)

  @webname = params[:webname]

  case(params[:webname])
  when "google"
	  @user = session[:name]
	  email = session[:email]
	  @list = Shortenedurl.all(:order => [ :id.asc ], :email => nil , :nickname => nil).shuffle.slice(0..2)
	  @list2 = Shortenedurl.all(:order => [:id.asc], :email => email , :email.not => nil, :limit => 20)
	  haml :google

  when "twitter"
		@user = session[:name]
	  	nickname = session[:nickname]
	  	@list = Shortenedurl.all(:order => [ :id.asc ], :email=>nil, :nickname => nil).shuffle.slice(0..2)
	  	@list2 = Shortenedurl.all(:order => [:id.asc], :nickname => nickname , :email=>nil, :nickname.not => nil, :limit => 20)

		haml :twitter
  when "facebook"

    @user = session[:name]
    email = session[:email]
    @list = Shortenedurl.all(:order => [ :id.asc ], :email => nil, :nickname => nil).shuffle.slice(0..2)
    @list2 = Shortenedurl.all(:order => [:id.asc], :email => email , :email.not => nil, :limit => 20)
    haml :facebook

  else
  	haml :index
  end

  else

  redirect '/'
  end


end

post  '/user/:webname' do

  count = 0

  if(params[:opcional] != '') then

  count = Shortenedurl.count(:opcional.not => nil , :conditions => [ 'opcional = ?', params[:opcional] ])

  end

  if(count == 0) then

  uri = URI::parse(params[:url])

  if uri.is_a? URI::HTTP or uri.is_a? URI::HTTPS then

      case(params[:webname])
      when "google"

        begin
          @short_url = Shortenedurl.first_or_create(:url => params[:url] , :email => session[:email] , :opcional => params[:opcional])
        rescue Exception => e
          puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
          pp @short_url
          puts e.message
        end

      redirect '/user/google'

      when "twitter"

        begin
          @short_url = Shortenedurl.first_or_create(:url => params[:url] , :nickname => session[:nickname] , :opcional => params[:opcional])
        rescue Exception => e
          puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
          pp @short_url
          puts e.message
        end

        redirect '/user/twitter'

      when "facebook"

          begin
            @short_url = Shortenedurl.first_or_create(:url => params[:url] , :email => session[:email] , :opcional => params[:opcional])
          rescue Exception => e
            puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
            pp @short_url
            puts e.message
          end

        redirect '/user/facebook'

      else

      redirect '/'
      end

    else
      logger.info "Error! <#{params[:url]}> is not a valid URL"
    end

  else

    session[:error1] = true
    case(params[:webname])
    when "google"
      redirect '/user/google'
    when "twitter"
      redirect '/user/twitter'
    when "facebook"
      redirect '/user/facebook'
    end

  end

end

get '/user/:webname/logout' do

  session.clear

  redirect '/'

end

#Estadisticas

get '/estadisticas/global' do

  @hashcountry = Hash.new
  @hashdate = Hash.new
  @hashcity = Hash.new


  visit = Visit.all()
  visit.each{|visit|
  @count = Visit.count()

    if(@hashcountry[visit.country].nil?)
      @hashcountry[visit.country] = 1
    else
      @hashcountry[visit.country] += 1
    end

    if(@hashcity[visit.city].nil?)
      @hashcity[visit.city] = 1
    else
      @hashcity[visit.city] += 1
    end

    if(@hashdate["#{visit.created_at.day} - #{visit.created_at.month} - #{visit.created_at.year}"].nil?)
        @hashdate["#{visit.created_at.day} - #{visit.created_at.month} - #{visit.created_at.year}"] = 1
      else
        @hashdate["#{visit.created_at.day} - #{visit.created_at.month} - #{visit.created_at.year}"] += 1
    end
                      }

  haml :globalstats

end

get '/estadisticas/:u' do

  @hashcountry = Hash.new
  @hashdate = Hash.new
  @hashcity = Hash.new

  short_url = Shortenedurl.first(:id => params[:u].to_i(Base))

  @url = short_url

  visit = Visit.all(:shortenedurl => short_url)

  @count = Visit.count(:shortenedurl => short_url)

  visit.each{|visit|
    if(@hashcountry[visit.country].nil?)
      @hashcountry[visit.country] = 1
    else
      @hashcountry[visit.country] += 1
    end
     if(@hashcity[visit.city].nil?)
      @hashcity[visit.city] = 1
    else
      @hashcity[visit.city] += 1
    end

    if(@hashdate["#{visit.created_at.day} - #{visit.created_at.month} - #{visit.created_at.year}"].nil?)
        @hashdate["#{visit.created_at.day} - #{visit.created_at.month} - #{visit.created_at.year}"] = 1
      else
        @hashdate["#{visit.created_at.day} - #{visit.created_at.month} - #{visit.created_at.year}"] += 1
    end

  }

  haml :stats

end



delete '/delete/:webname/:url' do

  case (params[:webname])
    when 'google'
      begin
      @id = Shortenedurl.first(:email => session[:email], :opcional => params[:url])
      @id.destroy if !@id.nil?
      rescue Exception => e
        puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
        pp @short_url
        puts e.message
      end
      redirect '/user/google'
    when 'twitter'
      begin
      @id = Shortenedurl.first(:nickname => session[:nickname], :opcional => params[:url])
      @id.destroy if !@id.nil?
      rescue Exception => e
        puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
        pp @short_url
        puts e.message
      end
      redirect '/user/twitter'
    when 'facebook'
      begin
      @id = Shortenedurl.first(:email => session[:email], :opcional => params[:url])
      @id.destroy if !@id.nil?
      rescue Exception => e
        puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
        pp @short_url
        puts e.message
      end
      redirect '/user/facebook'

    when 'googleid'
        begin
        @id = Shortenedurl.first(:email => session[:email], :id => params[:url].to_i(Base))
        @id.destroy if !@id.nil?
        rescue Exception => e
          puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
          pp @short_url
          puts e.message
        end
        redirect '/user/google'
      when 'twitterid'
        begin
        @id = Shortenedurl.first(:nickname => session[:nickname], :id => params[:url].to_i(Base))
        @id.destroy if !@id.nil?
        rescue Exception => e
          puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
          pp @short_url
          puts e.message
        end
        redirect '/user/twitter'
      when 'facebookid'
        begin
        @id = Shortenedurl.first(:email => session[:email], :id => params[:url].to_i(Base))
        @id.destroy if !@id.nil?
        rescue Exception => e
          puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
          pp @short_url
          puts e.message
        end
        redirect '/user/facebook'
    else

      redirect '/'
  end


end

error do haml :index end
