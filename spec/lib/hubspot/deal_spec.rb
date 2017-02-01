describe Hubspot::Deal do
  let(:example_deal_hash) do
    VCR.use_cassette('deal_example') do
      HTTParty.get('https://api.hubapi.com/deals/v1/deal/3?hapikey=demo&portalId=62515').parsed_response
    end
  end

  before { Hubspot.configure(hapikey: 'demo') }

  describe '#initialize' do
    subject { Hubspot::Deal.new(example_deal_hash) }
    it  { should be_an_instance_of Hubspot::Deal }
    its (:portal_id) { should == 62_515 }
    its (:deal_id) { should == 3 }
  end

  describe '.create!' do
    cassette 'deal_create'
    subject { Hubspot::Deal.create!(62_515, [8_954_037], [27_136], {}) }
    its(:deal_id)     { should_not be_nil }
    its(:portal_id)   { should eql 62_515 }
    its(:company_ids) { should eql [8_954_037] }
    its(:vids)        { should eql [27_136] }
  end

  describe '.find' do
    cassette 'deal_find'
    let(:deal) { Hubspot::Deal.create!(62_515, [8_954_037], [27_136], amount: 30) }

    it 'must find by the deal id' do
      find_deal = Hubspot::Deal.find(deal.deal_id)
      find_deal.deal_id.should eql deal.deal_id
      find_deal.properties['amount'].should eql '30'
    end
  end

  describe '.recent' do
    cassette 'find_all_recent_updated_deals'

    it 'must get the recents updated deals' do
      deals = Hubspot::Deal.recent

      first = deals.first
      last = deals.last

      expect(first).to be_a Hubspot::Deal
      expect(first.properties['amount']).to eql '0'
      expect(first.properties['dealname']).to eql '1420787916-gou2rzdgjzx2@u2rzdgjzx2.com'
      expect(first.properties['dealstage']).to eql 'closedwon'

      expect(last).to be_a Hubspot::Deal
      expect(last.properties['amount']).to eql '250'
      expect(last.properties['dealname']).to eql '1420511993-U9862RD9XR@U9862RD9XR.com'
      expect(last.properties['dealstage']).to eql 'closedwon'
    end

    it 'must filter only 2 deals' do
      deals = Hubspot::Deal.recent(count: 2)
      expect(deals.size).to eql 2
    end

    it 'it must offset the deals' do
      deal = Hubspot::Deal.recent(count: 1, offset: 1).first
      expect(deal.properties['dealname']).to eql '1420704406-goy6v83a97nr@y6v83a97nr.com' # the third deal
    end
  end

  describe '.all' do
    cassette 'find_all_deals'

    it 'must get all the deals' do
      deals = Hubspot::Deal.all

      first = deals.first
      last = deals.last

      expect(first).to be_a Hubspot::Deal
      expect(first.properties['dealname']).to eql 'Company'
      expect(first.properties['dealstage']).to eql 'qualifiedtobuy'
      expect(first.properties['amount']).to eql '40'

      expect(last).to be_a Hubspot::Deal
      expect(last.properties['dealname']).to eql 'Cool Deal'
      expect(last.properties['dealstage']).to be_nil
      expect(last.properties['amount']).to eql '60000'
    end

    it 'is limited to 100 records by default' do
      deals = Hubspot::Deal.all

      expect(deals.size).to eql 100
    end
  end

  describe 'find_associated' do
    context 'company associated deals' do
      it 'raises an error unless mandatory params are supplied' do
        expect { Hubspot::Deal.find_associated }.to raise_error Hubspot::InvalidParams
      end

      it 'must get all deals associated to a company' do
        VCR.use_cassette 'find_company_associated_deals' do
          deals = Hubspot::Deal.find_associated(objectType: 'company', objectId: '352000220')

          first = deals.first

          expect(first).to be_a Hubspot::Deal
          expect(first.properties['dealname']).to eql "Tim's Newer Deal"
          expect(first.properties['dealstage']).to eql 'appointmentscheduled'
          expect(first.properties['amount']).to eql '60000'
        end
      end
    end

    context 'contact associated deals' do
      it 'raises an error unless mandatory params are supplied' do
        expect { Hubspot::Deal.find_associated }.to raise_error Hubspot::InvalidParams
      end

      it 'must get all deals associated to a contact' do
        VCR.use_cassette 'find_contact_associated_deals' do
          deals = Hubspot::Deal.find_associated(objectType: 'contact', objectId: '3020024')

          first = deals.first
          last = deals.last

          expect(first).to be_a Hubspot::Deal
          expect(first.properties['dealname']).to eql 'vtestTOJustDelete-national'
          expect(first.properties['dealstage']).to eql 'appointmentscheduled'
          expect(first.properties['amount']).to be_nil

          expect(last).to be_a Hubspot::Deal
          expect(last.properties['dealname']).to eql 'vtestLast-national'
          expect(last.properties['dealstage']).to eql 'appointmentscheduled'
          expect(last.properties['amount']).to be_nil
        end
      end
    end
  end

  describe '#destroy!' do
    cassette 'destroy_deal'

    let(:deal) { Hubspot::Deal.create!(62_515, [8_954_037], [27_136], amount: 30) }

    it 'should remove from hubspot' do
      pending
      expect(Hubspot::Deal.find(deal.deal_id)).to_not be_nil

      expect(deal.destroy!).to be_true
      expect(deal.destroyed?).to be_true

      expect(Hubspot::Deal.find(deal.deal_id)).to be_nil
    end
  end

  describe '#[]' do
    subject { Hubspot::Deal.new(example_deal_hash) }

    it 'should get a property' do
      subject.properties.each do |property, value|
        expect(subject[property]).to eql value
      end
    end
  end
end
