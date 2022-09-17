require './ad_parameters'

describe AdParameters do
  let(:ap) { AdParameters.new }

  describe "#extract" do
    it "extracts content inside given tag" do
      expect(ap.extract '').to eq ''
      expect(ap.extract 'tag').to eq ''
      expect(ap.extract 'Creatives').to match /Creatives/
    end
  end

  describe "#convert" do
    it "converts currency and amount to EUR" do
      expect(ap.convert 'USD', 1).to eq 0.8849557522123894
      expect{ ap.convert '', 0 }.to raise_error /No exchange rate for currency/
      expect(ap.convert 'USD', 0).to eq 0
    end
  end

  describe "#build_placement" do
    it "builds placement object" do
      id = 'plc-1'
      expect(ap.build_placement(id, 1).id).to eq id
    end
  end

  describe "#build_placement_seq" do
    it "builds placement_seq object" do
      expect(ap.build_placement_seq([])).to be_instance_of FYBER::Userconfiguration::PlacementSeq
    end
  end

  describe "#parse_creatives" do
    it "parses creatives and returns array" do
      expect(ap.parse_creatives).to be_instance_of Array
    end
  end

  describe "#parse_placements" do
    it "parses placements and returns array" do
      expect(ap.parse_placements).to be_instance_of Array
    end
  end

  describe "#execute" do
    it "executes parsing and returns JSON" do
      expect(ap.execute).to match /placement/
    end
  end
end