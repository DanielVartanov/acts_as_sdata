# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_example-app_session',
  :secret      => '1a7f775c42347f280b17b6956e626511fdb7f65035350b761f74288fa46716bde1de152b90afb7462e7bf8ec98c7f89c4dd2a98dd38b5c04091944e874596d56'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
