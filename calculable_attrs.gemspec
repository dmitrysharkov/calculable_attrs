$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "calculable_attrs/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "calculable_attrs"
  s.version     = CalculableAttrs::VERSION
  s.authors     = ["Dmitry Sharkov"]
  s.email       = ["dmitry.sharkov@gmail.com"]
  s.homepage    = "https://github.com/dmitrysharkov/calculable_attrs"
  s.summary     = "Simplifies work with dynamically calculable fields."
  s.description = <<-eos
    Imagine you an Account model which has many transactions.
    calculable_attrs gem allows you to define Accoutn#blalace and SUM(transactions.amount) directrly in your Account model.
    And solves n+1 problem for you in an elegant way.
  eos
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.4"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency 'rspec-rails', "~> 3.0.0"
  s.add_development_dependency "factory_girl_rails", "~> 4.0"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "pry"
  s.add_development_dependency "awesome_print"
end
