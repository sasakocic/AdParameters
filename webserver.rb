require 'sinatra'
require 'rack/handler/webrick'
require './ad_parameters'

get '/' do
  'Hello world!'
end

get '/placements/:id/floor/:floor_price' do |id, floor|
  ap = AdParameters.new
  ap.placements_request(id, floor)
end