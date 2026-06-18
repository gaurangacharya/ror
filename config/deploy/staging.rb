set :stage, :staging
set :branch, :edge

set :deploy_to, "/home/rails/#{fetch(:stage)}"
set :user, 'rails'

role :app, %w{192.155.92.206}
role :web, %w{192.155.92.206}
role :db,  %w{192.155.92.206}

server '192.155.92.206',
  user: 'rails',
  roles: %w{web app}
