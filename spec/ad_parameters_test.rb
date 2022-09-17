require 'rubygems'
require 'bundler/setup'

# require your gems as usual
require 'nokogiri'
require 'rspec'

require './spec/spec_helper'
require './ad_parameters'


describe AdParameters do
  describe "#extract" do
    it "works" do
      ap = AdParameters.new('./file.xml')
      expect ap.extract('').to eq ''
      expect ap.extract('Creatives').to eq ''
    end
  end
end