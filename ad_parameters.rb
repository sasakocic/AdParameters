require 'rubygems'
require 'bundler/setup'
require 'google/protobuf'

# require your gems as usual
require 'nokogiri'
require './userconfiguration'

class AdParameters
  include FYBER::Userconfiguration
  PlacementStruct = Struct.new(:id, :floor)
  CreativeStruct = Struct.new(:id, :price) do
    def pricier_than(floor)
      price > floor
    end
  end
  EXCHANGE_RATES = {
    'EUR' => 1,
    'USD' => 1.13,
    'TYR' => 3.31,
    'SEK' => 10.76177,
  }

  def initialize(filename)
    @filename = filename
  end

  def execute
    creatives = parse_creatives
    placements = parse_placements
    placement_seq = PlacementSeq.new
    placements.each do |element|
      placement = Placement.new(id: element.id)
      creatives.each do |creative|
        if creative.pricier_than(element.floor)
          placement.creative << Creative.new(id: creative.id, price: creative.price)
        end
      end
      placement_seq.placement << placement
    end
    # encoded_data = PlacementSeq.encode(placement_seq)
    puts PlacementSeq.encode_json(placement_seq)
  end

  def extract(element)
    content = File.read(@filename).to_s.gsub(/[[:space:]]+/, ' ').strip
    extracted = content.scan(/<#{element}>(.*)<\/#{element}>/)
    "<#{element}>#{extracted[0][0]}</#{element}>"
  end

  def convert(currency, amount)
    raise 'No exchange rate for currency ' + currency unless EXCHANGE_RATES.has_key?(currency)
    amount.to_f / EXCHANGE_RATES[currency]
  end

  private

  def parse_placements
    placements = extract('Placements')
    parsed_info = Nokogiri::XML(placements)
    placement = parsed_info.xpath("//Placement")
    result = []
    placement.each do |element|
      result.push PlacementStruct.new(element['id'], convert(element.attr('currency'), element.attr('floor')))
    end
    result
  end

  def parse_creatives
    creatives = extract('Creatives')
    parsed_info = Nokogiri::XML(creatives)
    creative = parsed_info.xpath("//Creative")
    result = []
    creative.each do |element|
      result.push CreativeStruct.new(element['id'], convert(element.attr('currency'), element.attr('price')))
    end
    result
  end
end
