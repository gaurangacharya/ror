class AddBacktraceToFareharborFailures < ActiveRecord::Migration[5.2]
  def change
    add_column :fareharbor_failures, :backtrace, :text
  end
end
