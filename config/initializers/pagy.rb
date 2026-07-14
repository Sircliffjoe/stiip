begin
  require 'pagy/rails'
  Pagy::DEFAULT[:items] = 20
rescue LoadError
  # Pagy gem not installed, skipping configuration
end
