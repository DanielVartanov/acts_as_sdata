module SData
  module ControllerMixin
    module SDataFeed

    protected

      def resource_url
        sdata_options[:model].sdata_resource_kind_url(params[:dataset])
      end

      def build_feed_links_for(feed)
        feed.links << Atom::Link.new(
          :rel => 'self',
          :href => (resource_url + "?#{request.query_parameters.to_param}".chomp('?')),
          :type => 'application/atom+xml; type=feed',
          :title => 'Refresh')
        if (records_to_return > 0) && (@total_results > records_to_return)
          feed.links << Atom::Link.new(
            :rel => 'first',
            :href => (resource_url + "?#{request.query_parameters.merge(:startIndex => '1').to_param}"),
            :type => 'application/atom+xml; type=feed',
            :title => 'First Page')
          feed.links << Atom::Link.new(
            :rel => 'last',
            :href => (resource_url + "?#{request.query_parameters.merge(:startIndex => [1,(@last=(((@total_results-zero_based_start_index - 1) / records_to_return * records_to_return) + zero_based_start_index + 1))].max).to_param}"),
            :type => 'application/atom+xml; type=feed',
            :title => 'Last Page')
          if (one_based_start_index+records_to_return) <= @total_results
            feed.links << Atom::Link.new(
              :rel => 'next',
              :href => (resource_url + "?#{request.query_parameters.merge(:startIndex => [1,[@last, (one_based_start_index+records_to_return)].min].max.to_s).to_param}"),
              :type => 'application/atom+xml; type=feed',
              :title => 'Next Page')
          end
          if (one_based_start_index > 1)
            feed.links << Atom::Link.new(
              :rel => 'previous',
              :href => (resource_url + "?#{request.query_parameters.merge(:startIndex => [1,[@last, (one_based_start_index-records_to_return)].min].max.to_s).to_param}"),
              :type => 'application/atom+xml; type=feed',
              :title => 'Previous Page')
          end
        end
      end

      def build_sdata_feed(opts={})
        opts = sdata_options.deep_merge(opts)
        Atom::Feed.new do |f|
          f.title = opts[:feed][:title]
          f.updated = Time.now
          f.authors << Atom::Person.new(:name => opts[:feed][:author])
          f.id = resource_url
          f.categories << Atom::Category.new(:scheme => 'http://schemas.sage.com/sdata/categories',
                                             :term   => self.category_term,
                                             :label  => self.category_term.underscore.humanize.titleize)
        end
      end

      def records_to_return
        default_items_per_page = sdata_options[:feed][:default_items_per_page] || 10
        maximum_items_per_page = sdata_options[:feed][:maximum_items_per_page] || 100
        #check whether the count param is castable into integer
        return default_items_per_page if params[:count].blank? or (params[:count].to_i.to_s != params[:count])
        items_per_page = [params[:count].to_i, maximum_items_per_page].min
        items_per_page = default_items_per_page if (items_per_page < 0)
        items_per_page
      end

      def one_based_start_index
        [(params[:startIndex].to_i), 1].max
      end

      def zero_based_start_index
        [(one_based_start_index - 1), 0].max
      end

      def populate_open_search_for(feed)
        feed[SData.config[:schemas]['opensearch'], 'totalResults'] << @total_results
        feed[SData.config[:schemas]['opensearch'], 'startIndex'] << one_based_start_index
        feed[SData.config[:schemas]['opensearch'], 'itemsPerPage'] << records_to_return
      end

      def category_term
        self.sdata_options[:model].name.demodulize.camelize(:lower).pluralize
      end
    end
  end
end