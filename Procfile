search:      bundle exec rake ts:rebuild
web:         bundle exec passenger start -p 3000 --max-pool-size 6 --min-instances 2 --pool-idle-time 300
worker:      bundle exec sidekiq -q default -q paperclip -q mailers -q transactions