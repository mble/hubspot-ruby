describe Hubspot::DealPipeline do
  before { Hubspot.configure(hapikey: 'demo') }

  let(:example_pipeline_hash) do
    VCR.use_cassette('deal_pipeline_example', record: :none) do
      HTTParty.get('https://api.hubapi.com/deals/v1/pipelines/default?hapikey=demo').parsed_response
    end
  end

  describe '#initialize' do
    subject { Hubspot::DealPipeline.new(example_pipeline_hash) }

    it 'contains the right information about the pipeline' do
      expect(subject).to be_an_instance_of Hubspot::DealPipeline
      expect(subject.active).to be_true
      expect(subject.display_order).to eql 0
      expect(subject.label).to eql 'Sales pipeline'
      expect(subject.pipeline_id).to eql 'default'
      expect(subject.stages.count).to eql 7
    end
  end

  describe '.find' do
    cassette 'deal_pipeline_find'

    context 'given a pipeline with the id exists' do
      subject { Hubspot::DealPipeline.find 'default' }

      it 'then fetches the pipeline' do
        expect(subject).to be_an_instance_of Hubspot::DealPipeline
        expect(subject.active).to be_true
        expect(subject.display_order).to eql 0
        expect(subject.label).to eql 'Sales pipeline'
        expect(subject.pipeline_id).to eql 'default'
        expect(subject.stages.count).to eql 7
      end
    end

    context 'given a pipeline with the id does not exist' do
      subject { Hubspot::DealPipeline.find 'empty' }

      it 'then it raises an error' do
        expect { subject }.to raise_error Hubspot::RequestError
      end
    end
  end

  describe '.all' do
    cassette 'deal_pipeline_all'

    context 'given fetching all pipelines' do
      subject { Hubspot::DealPipeline.all }
      let(:first_deal) { subject.first }
      let(:last_deal) { subject.last }

      it 'then gets all Deal Pipelines' do
        expect(subject).to be_an_instance_of Array
        expect(subject).not_to be_empty
        expect(subject.size).to eql 2
      end

      it 'then correctly wraps data in Hubspot::DealPipeline objects' do
        expect(first_deal.pipeline_id).to eql 'default'
        expect(first_deal.label).to eql 'Sales pipeline'

        expect(last_deal.pipeline_id).to eql 'aad88bb2-75f7-4cd1-a12b-c25278133c58'
        expect(last_deal.label).to eql 'New Custom Business Pipeline'
      end
    end
  end
end
