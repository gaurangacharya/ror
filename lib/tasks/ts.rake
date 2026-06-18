namespace :ts do
  desc 'Start the Sphinx daemon attached'
  task :start_attached => :environment do
    interface.daemon.start()
  end

  def interface
    @interface ||= ThinkingSphinx::RakeInterface.new(nodetach: true)
  end
end
