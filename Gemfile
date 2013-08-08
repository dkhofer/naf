source 'https://rubygems.org'

gemspec

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end
gem 'jquery-ui-rails'
gem 'awesome_print'
gem 'will_paginate'
gem 'mem_info'

# For private repo testing on Travis
# gem 'af', '=0.9.9', path: 'vendor/private'
gem 'af', git: 'git@github.com:fiksu/af.git'

# These gems should be encapsulated in test group, but test fails.
# For now it will remain global.
gem 'shoulda-matchers', '2.0.0'
gem "timecop", '0.4.5'
