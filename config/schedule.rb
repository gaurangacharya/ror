every 1.day, at: '2:00 am' do
  runner "Person::SyncChargebee.run"
end

every 1.day, at: '1:00 am' do
  rake "fareharbor:import_listings_active_companies"
end

every 1.day, at: '2:00 am' do
  rake "fareharbor:import_companies_usd"
end

every 1.day, at: '2:10 am' do
  rake "fareharbor:import_companies_eur"
end

every 1.day, at: '2:20 am' do
  rake "fareharbor:import_companies_gbp"
end
