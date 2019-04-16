# encoding: UTF-8
$:.push File.expand_path('../lib', __FILE__)
$:.push File.expand_path('../../lib', __dir__)

require 'open_project/service_packs/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'openproject-service_packs'
  s.version     =  OpenProject::ServicePacks::VERSION
  s.authors = 'An AUT University R&D project team'
  # s.email       = ''
  s.homepage = 'https://gits.fromlabs.com/openproject/service-pack'
  s.summary = 'Allow to track units of service packs when logging time on tasks'
  s.description = 'Service Pack plugin'
  s.license = 'GPL-3.0' # e.g. 'MIT' or 'GPLv3'

  s.files = Dir['{app,config,db,doc,lib}/**/*'] + %w[CHANGELOG.md README.md]

  s.require_ruby_version = '>= 2.5.0'
  s.add_dependency 'rails', '>= 5.1.6', '< 6.x'
end
