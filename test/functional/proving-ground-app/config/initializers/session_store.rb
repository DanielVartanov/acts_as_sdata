# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_proving-ground-app_session',
  :secret      => '4fff73151fca1e120b5c32a01215a88d335a52c3a1732e299fb386aefcda58ab19744978508f656cd447637873a4608cee7885929e151731720cd8cfb3ccd180'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
