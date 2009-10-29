class PresidentsController < ApplicationController
  acts_as_sdata :model => President,
                :feed => { :id => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
                           :author => 'Sage',
                           :path => '/presidents',
                           :title => 'List of US presidents' }

  def sdata_collection
    presidents = build_sdata_feed
    presidents.entries += sdata_scope.map(&:to_atom)

    render :xml => presidents, :content_type => "application/atom+xml; type=feed"
  end

  def sdata_instance
    president = President.find_by_sdata_instance_id(params[:instance_id])

    render :xml => president.to_atom, :content_type => "application/atom+xml; type=entry"
  end
end