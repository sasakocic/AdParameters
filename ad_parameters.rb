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

  def initialize(filename = './file.xml')
    @filename = filename
    @creatives = parse_creatives
  end

  def execute
    placements = parse_placements
    placement_seq = build_placement_seq(placements)
    # encoded_data = PlacementSeq.encode(placement_seq)
    PlacementSeq.encode_json(placement_seq)
  end

  def placements_request(id, floor)
    placement_seq = build_placement_seq([PlacementStruct.new(id, floor.to_f)])
    PlacementSeq.encode_json(placement_seq)
  end

  def extract(element)
    return '' if element.empty?
    content = File.read(@filename).to_s.gsub(/[[:space:]]+/, ' ').strip
    extracted = content.scan(/<#{element}>(.*)<\/#{element}>/)
    return '' if extracted.empty?
    "<#{element}>#{extracted[0][0]}</#{element}>"
  end

  def convert(currency, amount)
    raise 'No exchange rate for currency ' + currency unless EXCHANGE_RATES.has_key?(currency)
    amount.to_f / EXCHANGE_RATES[currency]
  end

  def build_placement_seq(placements)
    placement_seq = PlacementSeq.new
    placements.each do |element|
      placement = build_placement(element.id, element.floor)
      placement_seq.placement << placement
    end
    placement_seq
  end

  def build_placement(id, floor)
    placement = Placement.new(id: id)
    @creatives.each do |creative|
      if creative.pricier_than(floor)
        placement.creative << Creative.new(id: creative.id, price: creative.price)
      end
    end
    placement
  end

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
