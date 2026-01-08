namespace :deploy do
  desc "Deploy to Heroku production (push main branch and run migrations)"
  task :production do
    puts "🚀 Deploying to Heroku production..."

    # Push main branch to Heroku
    puts "\n📤 Pushing main branch to Heroku..."
    system("git push heroku main") || abort("Failed to push to Heroku")

    # Run migrations on Heroku
    puts "\n🔄 Running migrations on Heroku..."
    system("heroku run rails db:migrate") || abort("Failed to run migrations")

    puts "\n✅ Deployment complete!"
  end
end
