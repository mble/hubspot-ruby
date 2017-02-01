describe Hubspot::Topic do
  before do
    Hubspot.configure(hapikey: 'demo')
  end

  describe '.list' do
    cassette 'topics_list'
    let(:topics) { Hubspot::Topic.list }

    it 'should have a list of topics' do
      topics.count.should be(3)
    end
  end

  describe '.find_by_topic_id' do
    cassette 'topics_list'

    it 'should find a specific topic' do
      topic = Hubspot::Topic.find_by_topic_id(349_001_328)
      topic['id'].should eq(349_001_328)
    end
  end
end
