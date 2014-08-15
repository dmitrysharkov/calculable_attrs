$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "calculable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "calculable"
  s.version     = Calculable::VERSION
  s.authors     = ["Dmitry Sharkov"]
  s.email       = ["dmitry.sharkov@gmail.com"]
  s.homepage    = "https://github.com/dmitrysharkov/calculable"
  s.summary     = "Simplifies work with dynamically calculable fields."
  s.description = <<-eos
    Imagine you an Account model which has many transactions.
    Calculable gem allows you to define Accoutn#blalace and SUM(transactions.amount) directrly in your Account model.
    And solves n+1 problem for you in an elegant way.
  eos
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.4"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
end
