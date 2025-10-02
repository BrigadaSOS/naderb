#!/usr/bin/env ruby
# Script to promote the first user in the database to admin role
# Usage: rails runner script/make_first_user_admin.rb

user = User.find_by(email: "davafons@gmail.com")

if user.nil?
  puts "❌ No users found in the database"
  exit 1
end

puts "👤 Current user: #{user.username || user.email || "User #{user.id}"}"
puts "🔐 Current role: #{user.role}"

if user.admin?
  puts "✅ User is already an admin"
else
  user.update!(role: :admin)
  puts "🎉 Successfully promoted user to admin role"
  puts "✅ Admin check: #{user.admin?}"
end

puts "\n💡 User can now access the admin panel at /dashboard/admin"
