describe Hubspot::Contact do
  let(:example_company_hash) do
    VCR.use_cassette('company_example', record: :none) do
      HTTParty.get('https://api.hubapi.com/companies/v2/companies/21827084?hapikey=demo').parsed_response
    end
  end
  let(:company_with_contacts_hash) do
    VCR.use_cassette('company_with_contacts', record: :none) do
      HTTParty.get('https://api.hubapi.com/companies/v2/companies/115200636?hapikey=demo').parsed_response
    end
  end
  let(:oauth2_company_example) do
    VCR.use_cassette 'oauth2_company_example', record: :none do
      HTTParty.get(
        'https://api.hubapi.com/companies/v2/companies/215620614',
        headers: { 'Authorization' => 'Bearer CMSPmJ-hKxICEQEYs-gDILqTDSiRtwIyGQBC-5ITiVAKmgufwUzg_ck9xit5QFdHiu8' }
      )
    end
  end

  context 'API key authentication strategy' do
    before { Hubspot.configure(hapikey: 'demo') }

    describe '#initialize' do
      subject { Hubspot::Company.new(example_company_hash) }
      it { should be_an_instance_of Hubspot::Company }
      its(['name']) { should == 'HubSpot' }
      its(['domain']) { should == 'hubspot.com' }
      its(:vid) { should == 21_827_084 }
    end

    describe '.create!' do
      cassette 'company_create'
      let(:params) { {} }
      subject { Hubspot::Company.create!(name, params) }
      context 'with a new name' do
        let(:name) { "New Company #{Time.now.to_i}" }
        it { should be_an_instance_of Hubspot::Company }
        its(:name) { should match /New Company .*/ } # Due to VCR the email may not match exactly

        context 'and some params' do
          cassette 'company_create_with_params'
          let(:name) { "New Company with Params #{Time.now.to_i}" }
          let(:params) { { domain: "new-company-domain-#{Time.now.to_i}" } }
          its(['name']) { should match /New Company with Params/ }
          its(['domain']) { should match /new\-company\-domain/ }
        end
      end
    end

    describe '.find_by_id' do
      context 'given an uniq id' do
        cassette 'company_find_by_id'
        subject { Hubspot::Company.find_by_id(vid) }

        context 'when the company is found' do
          let(:vid) { 21_827_084 }
          it { should be_an_instance_of Hubspot::Company }
          its(:name) { should == 'HubSpot' }
        end

        context 'when the contact cannot be found' do
          it 'raises an error' do
            expect { Hubspot::Company.find_by_id(9_999_999) }.to raise_error(Hubspot::RequestError)
          end
        end
      end
    end

    describe '.find_by_domain' do
      context 'given a domain' do
        cassette 'company_find_by_domain'
        subject { Hubspot::Company.find_by_domain('hubspot.com') }

        context 'when a company is found' do
          it { should be_an_instance_of Array }
          it { should_not be_empty }
        end

        context 'when a company cannot be found' do
          subject { Hubspot::Company.find_by_domain('asdf1234baddomain.com') }
          it { should be_an_instance_of Array }
          it { should be_empty }
        end
      end
    end

    describe '.all' do
      context 'all companies' do
        cassette 'find_all_companies'

        it 'must get the companies list' do
          companies = Hubspot::Company.all

          expect(companies.size).to eql 20 # default page size

          first = companies.first
          last = companies.last

          expect(first).to be_a Hubspot::Company
          expect(first.vid).to eql 42_866_817
          expect(first['name']).to eql 'name'

          expect(last).to be_a Hubspot::Company
          expect(last.vid).to eql 42_861_017
          expect(last['name']).to eql 'Xge5rbdt2zm'
        end

        it 'must filter only 2 copmanies' do
          copmanies = Hubspot::Company.all(count: 2)
          expect(copmanies.size).to eql 2
        end
      end

      context 'recent companies' do
        cassette 'find_all_recent_companies'

        it 'must get the companies list' do
          companies = Hubspot::Company.all(recent: true)
          expect(companies.size).to eql 20

          first = companies.first
          last = companies.last
          expect(first).to be_a Hubspot::Company
          expect(first.vid).to eql 42_866_817

          expect(last).to be_a Hubspot::Company
          expect(last.vid).to eql 42_861_017
        end
      end
    end

    describe '#update!' do
      cassette 'company_update'
      let(:company) { Hubspot::Company.new(example_company_hash) }
      let(:params) { { name: 'Acme Cogs', domain: 'abccogs.com' } }
      subject { company.update!(params) }

      it { should be_an_instance_of Hubspot::Company }
      its(['name']) { should == 'Acme Cogs' }
      its(['domain']) { should == 'abccogs.com' }

      context 'when the request is not successful' do
        let(:company) { Hubspot::Company.new('vid' => 'invalid', 'properties' => {}) }
        it 'raises an error' do
          expect { subject }.to raise_error Hubspot::RequestError
        end
      end
    end

    describe '#destroy!' do
      cassette 'company_destroy'
      let(:company) { Hubspot::Company.create!("newcompany_y_#{Time.now.to_i}@hsgem.com") }
      subject { company.destroy! }
      it { should be_true }
      it 'should be destroyed' do
        subject
        company.destroyed?.should be_true
      end
      context 'when the request is not successful' do
        let(:company) { Hubspot::Company.new('vid' => 'invalid', 'properties' => {}) }
        it 'raises an error' do
          expect { subject }.to raise_error Hubspot::RequestError
          company.destroyed?.should be_false
        end
      end
    end

    describe '#add_contact' do
      cassette 'add_contact_to_company'
      let(:company) { Hubspot::Company.create!("company_#{Time.now.to_i}@example.com") }
      let(:contact) { Hubspot::Contact.create!("contact_#{Time.now.to_i}@example.com") }
      subject { Hubspot::Company.all(recent: true).last }
      context 'with Hubspot::Contact instance' do
        before { company.add_contact contact }
        its(['num_associated_contacts']) { should eql '1' }
      end

      context 'with vid' do
        before { company.add_contact contact.vid }
        its(['num_associated_contacts']) { should eql '1' }
      end
    end

    describe '#destroyed?' do
      let(:company) { Hubspot::Company.new(example_company_hash) }
      subject { company }
      its(:destroyed?) { should be_false }
    end

    describe '#contacts' do
      let(:company) { Hubspot::Company.new(company_with_contacts_hash) }
      subject do
        VCR.use_cassette('company_contacts') { company.contacts }
      end

      its(:size) { should eql 5 }
    end
  end

  context 'OAuth2 authentication strategy' do
    # oauth_access_token expires every 6 hours, so provide a token for each test that has matching fixtures
    describe '.create' do
      before do
        Hubspot.configure(
          use_oauth2: true,
          oauth2_access_token: 'CLC_oK2gKxICEQEYs-gDILqTDSiRtwIyGQBC-5IT1m0sMv7-biuemlnQWqVSxd0qzOQ' # This expires every 6 hours so subject to change
        )
      end

      let(:params) { {}}
      subject { Hubspot::Company.create!(name, params) }
      context 'with a new name' do
        cassette 'oauth2_company_create'
        let(:name) { "New Company #{Time.now.to_i}" }

        it 'successfully creates a new company' do
          expect(subject).to be_an_instance_of Hubspot::Company
          expect(subject.name).to match(/New Company .*/)
        end
      end

      context 'with params' do
        cassette 'oauth2_company_create_with_params'
        let(:name) { "New Company with Params #{Time.now.to_i}" }
        let(:params) { { domain: "new-company-domain-#{Time.now.to_i}" } }

        it 'successfully creates a new company' do
          expect(subject).to be_an_instance_of Hubspot::Company
          expect(subject.name).to match(/New Company .*/)
          expect(subject['domain']).to match(/new-company-domain/)
        end
      end
    end

    describe '.find_by_id' do
      before do
        Hubspot.configure(
          use_oauth2: true,
          oauth2_access_token: 'CLC_oK2gKxICEQEYs-gDILqTDSiRtwIyGQBC-5IT1m0sMv7-biuemlnQWqVSxd0qzOQ' # This expires every 6 hours so subject to change
        )
      end

      context 'given an unique id' do
        subject { Hubspot::Company.find_by_id(vid) }

        context 'when the company is found' do
          let(:vid) { 184_896_670 }

          it 'returns an instance of Hubspot::Company' do
            VCR.use_cassette 'oauth2_company_find_by_id', record: :new_episodes do
              expect(subject).to be_an_instance_of Hubspot::Company
              expect(subject.name).to eql 'Hubspot, Inc.'
            end
          end
        end

        context 'when the contact cannot be found' do
          it 'raises an error' do
            VCR.use_cassette 'oauth2_company_find_by_id', record: :new_episodes do
              expect { Hubspot::Company.find_by_id(9_999_999) }.to raise_error(Hubspot::RequestError)
            end
          end
        end
      end
    end

    describe '.find_by_domain' do
      before do
        Hubspot.configure(
          use_oauth2: true,
          oauth2_access_token: 'CLC_oK2gKxICEQEYs-gDILqTDSiRtwIyGQBC-5IT1m0sMv7-biuemlnQWqVSxd0qzOQ' # This expires every 6 hours so subject to change
        )
      end

      context 'given a domain' do
        subject { Hubspot::Company.find_by_domain(domain) }

        context 'when a company is found' do
          let(:domain) { 'hubspot.com' }

          it 'returns an array of Hubspot::Company objects' do
            VCR.use_cassette 'oauth2_company_find_by_domain', record: :new_episodes do
              expect(subject).to be_an_instance_of Array
              expect(subject).to_not be_empty
            end
          end
        end

        context 'when a company cannot be found' do
          let(:domain) { 'asdf1234baddomain.com' }

          it 'returns an empty array' do
            VCR.use_cassette 'oauth2_company_find_by_id', record: :new_episodes do
              expect(subject).to be_an_instance_of Array
              expect(subject).to be_empty
            end
          end
        end
      end
    end

    describe '.all' do
      before do
        Hubspot.configure(
          use_oauth2: true,
          oauth2_access_token: 'CLC_oK2gKxICEQEYs-gDILqTDSiRtwIyGQBC-5IT1m0sMv7-biuemlnQWqVSxd0qzOQ' # This expires every 6 hours so subject to change
        )
      end

      context 'all companies' do
        it 'must get the companies list' do
          VCR.use_cassette 'oauth2_find_all_companies', record: :new_episodes do
            companies = Hubspot::Company.all

            expect(companies.size).to eql 20 # default page size

            first = companies.first
            last = companies.last

            expect(first).to be_a Hubspot::Company
            expect(first.vid).to eql 274_136_281
            expect(first['name']).to eql 'New Company with Params 1486140423'

            expect(last).to be_a Hubspot::Company
            expect(last.vid).to eql 346_060_273
            expect(last['name']).to eql 'lebsack.io'
          end
        end

        it 'must filter only 2 copmanies' do
          VCR.use_cassette 'oauth2_find_all_companies', record: :new_episodes do
            copmanies = Hubspot::Company.all(count: 2)
            expect(copmanies.size).to eql 2
          end
        end
      end

      context 'recent companies' do
        it 'must get the companies list' do
          VCR.use_cassette 'oauth2_find_all_recent_companies', record: :new_episodes do
            companies = Hubspot::Company.all(recent: true)
            expect(companies.size).to eql 20

            first = companies.first
            last = companies.last
            expect(first).to be_a Hubspot::Company
            expect(first.vid).to eql 274_136_281

            expect(last).to be_a Hubspot::Company
            expect(last.vid).to eql 346_060_273
          end
        end
      end
    end

    describe '#update!' do
      cassette 'oauth2_company_update'
      before do
        Hubspot.configure(
          use_oauth2: true,
          oauth2_access_token: 'CMSPmJ-hKxICEQEYs-gDILqTDSiRtwIyGQBC-5ITiVAKmgufwUzg_ck9xit5QFdHiu8'
        )
      end

      let(:params) { { name: 'Acme Cogs', domain: 'abccogs.com' } }
      subject { company.update! params }

      context 'when the request is successful' do
        let(:company) { Hubspot::Company.new oauth2_company_example }

        it 'updates the company record and returns the updated Hubspot::Company instance' do
          expect(subject).to be_an_instance_of Hubspot::Company
          expect(subject['name']).to eql 'Acme Cogs'
          expect(subject['domain']).to eql 'abccogs.com'
        end
      end

      context 'when the request is not successful' do
        let(:company) { Hubspot::Company.new 'vid' => 'invalid', 'properties' => {} }
        it 'raises an error' do
          expect { subject }.to raise_error Hubspot::RequestError
        end
      end
    end
  end
end
