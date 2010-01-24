class ItemsController < ApplicationController
  def index
    render :xml => Item.all.to_xml
  end

  def sdata_collection
    index
  end

  def create    
    item = Item.create!(params[:item])    
    render :xml => item.to_xml, :status => :created
  end

  def show    
    render :xml => Item.find(params[:id]).to_xml
  end
end
