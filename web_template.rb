app_name = Pathname.new(`pwd`).basename.to_s.strip

template_repo_url = 'https://raw.githubusercontent.com/rawhide/rails-template/master'

if use_git = yes?('Do you want to git init?[y/n]') ? true : false
  git_repository_url = ask('Please enter the Git repository URL')
end

if use_errbit = yes?('Do you want to use errbit?[y/n]') ? true : false
  errbit_host = ask('Please enter the Errbit hostname')
  errbit_api_key = ask('Please enter the Errbit api key')
end

use_seed_fu = yes?('Do you want to use seed-fu gem?[y/n]') ? true : false
use_kaminari = yes?('Do you want to use kaminari gem?[y/n]') ? true : false
use_draper = yes?('Do you want to use draper gem?[y/n]') ? true : false
use_devise = yes?('Do you want to use devise gem?[y/n]') ? true : false
use_ransack = yes?('Do you want to use ransack gem?[y/n]') ? true : false
use_capistrano = yes?('Do you want to use capistrano gem?[y/n]') ? true : false

japanese_timezone = yes?('Do you have a timezone to Japan?[y/n]') ? true : false

run 'cp config/database.yml config/database.yml.example'
run 'cp config/secrets.yml config/secrets.yml.example'

get "#{template_repo_url}/config/database.yml.sqlite3.example", 'config/database.yml.sqlite3.example'

Bundler.with_clean_env do
  run 'bundle install -j16'
end

run 'bundle exec spring binstub --all'

# Initialize Git
# ==================================================

create_file '.gitignore', <<-EOS
# Ignore bundler config.
/.bundle

# Ignore all logfiles and tempfiles.
/log/*
!/log/.keep
/tmp
/*.log

# Ignore other unneeded files.
*~
*.dump
*.swp

.DS_Store
.project
.pryrc
.rbenv-gemsets
.rspec
.sass-cache

/config/database.yml
/config/secrets.yml
/coverage/
/db/*.sqlite3
/nbproject/
/vendor/bundle
EOS

if use_git
  git :init
  git add: '.'
  git commit: '-m "First commit"'
  git remote: "add origin #{git_repository_url}" if git_repository_url
  git flow: ' init -d'
end

# Gems
# ==================================================

remove_file 'Gemfile'
create_file 'Gemfile', "source 'https://rubygems.org'\n"

gem 'rails', '4.2.5'
gem 'mysql2', '~> 0.3.20'
gem 'airbrake'
gem 'settingslogic'
gem 'enumerize'
gem 'seed-fu', '~> 2.3' if use_seed_fu
gem 'draper', '~> 1.3' if use_draper
gem 'devise' if use_devise
gem 'kaminari' if use_kaminari
gem 'ransack' if use_ransack

# assets
gem 'coffee-rails', '~> 4.1.0'
gem 'uglifier', '>= 1.3.0'

gem 'bootstrap-sass', '~> 3.3.6'
gem 'sass-rails', '>= 3.2'

# jquery
gem 'jquery-rails'

gem_group :development do
  gem 'annotate'
  gem 'bullet'
  gem 'quiet_assets'
  gem 'rack-mini-profiler'
  gem 'rails-erd'
  gem 'thin'

  gem 'hirb'
  gem 'hirb-unicode'

  gem 'better_errors'
  gem 'binding_of_caller'

  if use_capistrano
    gem 'capistrano'
    gem 'capistrano-rails'
    gem 'capistrano-rbenv', github: 'capistrano/rbenv'
    gem 'capistrano-bundler'
  end

  # static code analysis
  gem 'brakeman'
  gem 'metric_fu'
  gem 'rails_best_practices'
  gem 'rubocop', require: false
  gem 'rubocop-checkstyle_formatter', require: false
end

gem_group :test do
  gem 'database_cleaner'
  gem 'fuubar'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'timecop'
end

gem_group :development, :test do
  gem 'awesome_print'
  gem 'byebug'
  gem 'factory_girl_rails'
  gem 'spring'
  gem 'sqlite3'
  gem 'web-console', '~> 2.0'

  # debug
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'pry-stack_explorer'
end

gem_group :production, :staging, :sandbox do
  gem 'therubyracer', platforms: :ruby
end

gem 'yard', group: :doc

Bundler.with_clean_env do
  run 'bundle update -j16'
end

# Create Database
# ==================================================

rake 'db:create'

# Add app rake
# ==================================================

rakefile('app.rake') do
<<-EOS
namespace :app do
  desc 'Initialize Database'
  task init: 'db:load_config' do
    %w(db:create db:migrate db:seed).each do |t|
      Rake::Task[t].invoke
    end
  end

  desc 'Reset Database'
  task reset: 'db:load_config' do
    %w(db:migrate:reset db:seed).each do |t|
      Rake::Task[t].invoke
    end
  end
end
EOS
end

# Timezone settings
# ==================================================

if japanese_timezone
  inject_into_file 'config/application.rb', after: "# config.time_zone = 'Central Time (US & Canada)'" do <<-EOS.chomp

    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local
  EOS
  end
else
  inject_into_file 'config/application.rb', after: "# config.time_zone = 'Central Time (US & Canada)'" do <<-EOS.chomp

    config.time_zone = 'UTC'
    config.active_record.default_timezone = :utc
  EOS
  end
end

# Locale settings
# ==================================================

inject_into_file 'config/application.rb', after: "# config.i18n.default_locale = :de" do <<-EOS.chomp

    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    I18n.enforce_available_locales = true
    config.i18n.available_locales = [:ja]
    config.i18n.default_locale = :ja
  EOS
end

run 'mkdir -p config/locales/defaults/'
run 'mkdir -p config/locales/models/defaults/'
run 'mkdir -p config/locales/views/defaults/'
run 'mv config/locales/en.yml config/locales/defaults/en.yml'
run 'touch config/locales/defaults/.keep'
run 'touch config/locales/models/defaults/.keep'
run 'touch config/locales/views/defaults/.keep'

# Download I18n ja file
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/defaults/'
get "#{template_repo_url}/config/locales/views/defaults/ja.yml", 'config/locales/views/defaults/ja.yml'

# Generator settings
# ==================================================

inject_into_file 'config/application.rb', after: 'config.active_record.raise_in_transactional_callbacks = true' do <<-EOS.chomp


    config.generators do |g|
      g.assets false
      g.helper false

      g.test_framework :rspec, fixtures: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.view_specs false
      g.helper_specs false
      g.decorator   false
    end
EOS
end

# Bullet gem settings
# ==================================================

inject_into_file 'config/environments/development.rb', after: '# config.action_view.raise_on_missing_translations = true' do <<-EOS.chomp


  # bullet settings
  config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = false
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
  end
EOS
end

# Environment settings
# ==================================================

get "#{template_repo_url}/config/environments/sandbox.rb", 'config/environments/sandbox.rb'
get "#{template_repo_url}/config/environments/staging.rb", 'config/environments/staging.rb'

# Install rspec
# ==================================================

generate 'rspec:install'

gsub_file 'spec/spec_helper.rb', /^=begin\n/, ''
gsub_file 'spec/spec_helper.rb', /^=end\n/, ''
uncomment_lines 'spec/rails_helper.rb', Regexp.escape("Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }")

append_file '.rspec' do <<-EOS
--format Fuubar
EOS
end

get "#{template_repo_url}/spec/support/database_cleaner.rb", 'spec/support/database_cleaner.rb'
get "#{template_repo_url}/spec/support/factory_girl.rb", 'spec/support/factory_girl.rb'

# Settingslogic settings
# ==================================================

get "#{template_repo_url}/config/initializers/settings.rb", 'config/initializers/settings.rb'
get "#{template_repo_url}/config/application.yml", 'config/application.yml'

# enumerize settings
# ==================================================

get "#{template_repo_url}/config/locales/enumerize.ja.yml", 'config/locales/enumerize.ja.yml'

# kaminari settings
# ==================================================

if use_kaminari
  generate 'kaminari:config'
end

# Devise settings
# ==================================================

if use_devise
  generate 'devise:install'
  get "#{template_repo_url}/config/locales/devise.ja.yml", 'config/locales/devise.ja.yml'
  get "#{template_repo_url}/spec/support/devise.rb", 'spec/support/devise.rb'
end

# seed-fu settings
# ==================================================

append_file 'db/seeds.rb' do <<-EOS

SeedFu.seed
EOS
end

# Capistrano settings
# ==================================================

run 'cap install STAGES=production,staging,sandbox'

uncomment_lines 'Capfile', Regexp.escape("require 'capistrano/rbenv'")
uncomment_lines 'Capfile', Regexp.escape("require 'capistrano/bundler'")
uncomment_lines 'Capfile', Regexp.escape("require 'capistrano/rails/assets'")
uncomment_lines 'Capfile', Regexp.escape("require 'capistrano/rails/migrations'")

remove_file 'config/deploy.rb'
get "#{template_repo_url}/config/deploy.rb", 'config/deploy.rb'

gsub_file 'config/deploy.rb', "set :application, ''", "set :application, '#{app_name}'"
gsub_file 'config/deploy.rb', "set :repo_url, ''", "set :repo_url, '#{git_repository_url}'" if git_repository_url

# Errbit settings
# ==================================================

if use_errbit
initializer 'errbit.rb' do
<<-EOS
Airbrake.configure do |config|
  config.api_key = '#{errbit_api_key}'
  config.host    = '#{errbit_host}'
  config.port    = 80
  config.secure  = config.port == 443
end
EOS
end
end

# Assets
# ==================================================

remove_file 'app/assets/javascripts/application.js'
remove_file 'app/assets/stylesheets/application.css'

get "#{template_repo_url}/app/assets/javascripts/application.js", 'app/assets/javascripts/application.js'
get "#{template_repo_url}/app/assets/stylesheets/application.scss", 'app/assets/stylesheets/application.scss'
get "#{template_repo_url}/app/assets/stylesheets/_bootstrap-custom.scss", 'app/assets/stylesheets/_bootstrap-custom.scss'
get "#{template_repo_url}/app/assets/stylesheets/_variables-custom.scss", 'app/assets/stylesheets/_variables-custom.scss'

# Layout
# ==================================================

remove_file 'app/views/layouts/application.html.erb'
get "#{template_repo_url}/app/views/layouts/application.html.erb", 'app/views/layouts/application.html.erb'

# Error handling
# ==================================================

get "#{template_repo_url}/app/controllers/concerns/error_handlers.rb", 'app/controllers/concerns/error_handlers.rb'
get "#{template_repo_url}/app/controllers/errors_controller.rb", 'app/controllers/errors_controller.rb'

if use_errbit
inject_into_file 'app/controllers/concerns/error_handlers.rb', after: 'logger.info "Rendering #{code} with exception: #{exception.message}" if exception' do <<-EOS.chomp

      Airbrake.notify(exception) if exception
EOS
end
end

inject_into_file 'app/controllers/application_controller.rb', after: 'protect_from_forgery with: :exception' do <<-EOS.chomp


  include ErrorHandlers
EOS
end

inject_into_file 'config/routes.rb', after: 'Rails.application.routes.draw do' do <<-EOS.chomp

  get '*anything' => 'errors#routing_error'
EOS
end

get "#{template_repo_url}/app/views/errors/error_404.html.erb", 'app/views/errors/error_404.html.erb'
get "#{template_repo_url}/app/views/errors/error_422.html.erb", 'app/views/errors/error_422.html.erb'
get "#{template_repo_url}/app/views/errors/error_500.html.erb", 'app/views/errors/error_500.html.erb'

initializer 'exceptions_app.rb' do
<<-EOS
Rails.configuration.exceptions_app = ->(env) { ErrorsController.action(:render_error).call(env) }
EOS
end

if use_git
  git add: '.'
end

puts "SUCCESS!"
