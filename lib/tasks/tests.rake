namespace :test do
  task :mongo do
    desc "Run tests using MongoDB back-end"
    ENV['DB'] = "mongo"
    Rake::Task[:test].invoke
  end

  task :redis do
    desc "Run tests using Redis back-end"
    ENV['DB'] = "redis"
    Rake::Task[:test].invoke
  end

end