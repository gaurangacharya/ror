# require 'whenever/capistrano'

# config valid only for current version of Capistrano
lock '3.10.1'

set :rvm_custom_path, '/usr/share/rvm'
set :rvm_ruby_version, '2.7.8'
set :application, 'ownoutdoors'
set :repo_url, 'git@git.ithouse.io:ownoutdoors/ownoutdoors.git'

set :linked_files, %W{config/database.yml config/config.yml config/#{fetch(:stage)}.sphinx.conf .env #{fetch(:stage)}.env}
set :linked_dirs, %w{log public/system public/assets db/sphinx tmp/cache tmp/pids tmp/binlog client/node_modules}

set :passenger_restart_with_touch, true
set :keep_releases, 2

# set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:stage) do
          execute :sudo, "#{fetch(:rvm_custom_path)}/bin/rvm #{fetch(:rvm_ruby_version)} do bundle exec foreman export systemd /etc/systemd/system " +
        "-f Procfile.#{fetch(:stage)} -a #{fetch(:application)}-#{fetch(:stage)} -u #{fetch(:user)} -l #{shared_path}/log -e ./#{fetch(:stage)}.foreman --root #{current_path}"
        end
      end
    end
  end

  desc 'Start the application services'
  task :start do
    on roles(:app) do
      execute :sudo, "/bin/systemctl start #{fetch(:application)}-#{fetch(:stage)}.target"
    end
  end

  desc 'Stop the application services'
  task :stop do
    on roles(:app) do
      execute :sudo, "/bin/systemctl stop #{fetch(:application)}-#{fetch(:stage)}.target"
    end
  end

  desc 'Restart the application services'
  task :restart do
    on roles(:app) do
      execute :sudo, "/bin/systemctl restart #{fetch(:application)}-#{fetch(:stage)}.target"
    end
  end
end

# full app restart
after  'deploy:finished', 'foreman:restart'

set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }
set :whenever_environment, ->{ fetch(:stage) }
# require "whenever/capistrano"
