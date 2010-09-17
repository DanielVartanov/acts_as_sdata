require 'active_support'
require 'action_controller'
require 'atom' # TODO: add ratom _dependency_

module SData
  class << self
    def sdata_name(klass)
      case klass
      when SData::Resource
        klass.sdata_name
      when Class
        klass.respond_to?(:sdata_name) ? klass.sdata_name : nil
      when String
        klass.demodulize
      end
    end
    
    def sdata_url_component(klass)
      SData.sdata_name(klass).camelize(:lower)
    end
    
    def sdata_collection_url_component(klass)
      SData.sdata_url_component(klass).pluralize
    end
    
    def config
      unless @config
        @config = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config','sdata.yml'))
        app_config_file = ENV['SDATA_CONFIG_FILE']
        app_config_file ||= File.join(RAILS_ROOT, 'sdata', 'config', 'sdata.yml') if defined?(RAILS_ROOT)
        @config = @config.deep_merge(YAML.load_file(app_config_file)) unless app_config_file.nil?
        @config = @config.with_indifferent_access
        @config[:contracts] ||= []
        @config[:defaultContract] ||= @config[:contracts].first
        @config[:defaultContract] ||= "crmErp"
        @config[:contract_namespace] ||= "SData::Contracts"        
      end
      @config
    end
    
    def config=(conf)
      @config = conf.with_indifferent_access
    end
    
    def sdata_contract_name(klassname)
      if (klassname =~ /#{@config[:contract_namespace]}::([^:]*)::/)
        $~[1].camelize(:lower)
      else
        raise "Cannot determine sdata_contract_name for #{klassname}"
      end
    end
    
    
    def contract_namespaces
      config[:contracts].map{|contract| "#{config[:contract_namespace]}::#{contract.camelize}"}
    end
    
    # this is pby expensive and will have to be optimized by using const_get directly
    # RADAR: this assumes resource names are unique across contracts. To change that must refactor sd_uuid to either
    # have a contract attr or pby better just store fully qualified name in sd_class
    def resource_class(klassname)
      contract_namespaces.each do |ns|
        begin
          return "#{ns}::#{klassname}".constantize
        rescue;end
      end
    end
    
    def store_path
      #TODO: remove dataset=nil and modify calls accordingly. dataset should not be implied at this level
      ['sdata', config[:application], config[:defaultContract]].compact.join('/')
    end

    def base_url
      config[:base_url].chomp('/')
    end
    
    def endpoint
      [base_url, store_path].join('/')
    end
    
    def reset!
      @config = nil
    end
    
    
  end
end