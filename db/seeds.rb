# frozen_string_literal: true

puts "Seeding NoraCapital admin user..."

admin = User.find_or_initialize_by(email: "admin@noracapital.com.ng")
admin.assign_attributes(
  first_name: "Admin",
  last_name: "NoraCapital",
  password: "password123",
  password_confirmation: "password123",
  role: :admin,
  confirmed_at: admin.confirmed_at || Time.current
)
admin.save!

puts "Admin ready: admin@noracapital.com.ng"
