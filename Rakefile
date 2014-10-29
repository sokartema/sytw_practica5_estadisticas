desc "run test"
task :default => :test
desc "run test"
task :test do
  sh "ruby test/test.rb"
end

desc "run selenium login test"
task :selenium do
  sh "ruby test/test_s.rb"
end

desc "run the http server"
task :init do
  sh "ruby app.rb"
end

desc "run the server via rackup"
task :rackup do
  sh "rackup"
end

# substitute XXX for the name of your app
desc "create heroku app"
task :create, :appname do |t,args|
  name = args[:appname] || 'XXX';
  sh "heroku create #{name}"
end

desc "deploy  heroku app"
task :deploy  do
  sh "git push heroku master"
end

desc "ps"
task :deploy  do
  sh "heroku ps"
end

desc "logs"
task :logs  do
  sh "heroku logs"
end

desc "destroy deployment in heroku"
task :logs, :appname  do
  name = args[:appname] || 'XXX';
  sh "heroku apps:destroy #{name}"
end
