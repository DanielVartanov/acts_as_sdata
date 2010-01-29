class ItemsController < ApplicationController
  acts_as_sdata :model => Item,
              :feed => { :id => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
                          :author => 'acts as SData',
                          :path => '/items',
                          :title => 'Items' }

  def index
    render :xml => Item.all.to_xml
  end

  def create    
    item = Item.create!(params[:item])    
    render :xml => item.to_xml, :status => :created
  end

  def show    
    render :xml => Item.find(params[:id]).to_xml
  end
end
