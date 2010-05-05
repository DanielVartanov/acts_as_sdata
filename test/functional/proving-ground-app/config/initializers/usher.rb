# according to README should be:
#   Usher::Util::Rails.activate
# but above gives an error: acts_as_sdata/test/functional/proving-ground-app/vendor/plugins/usher/lib/usher/util/rails.rb:13: class definition in method body (SyntaxError)
# - so instead we load appropriate interface manually:

ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails23)"
