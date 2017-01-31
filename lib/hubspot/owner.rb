module Hubspot
  #
  # HubSpot Owners API
  #
  # {http://developers.hubspot.com/docs/methods/owners/get_owners}
  #
  # TODO: Create an Owner
  # TODO: Update an Owner
  # TODO: Delete an Owner
  class Owner
    GET_OWNERS_PATH   = '/owners/v2/owners'.freeze # GET
    CREATE_OWNER_PATH = '/owners/v2/owners'.freeze # POST
    UPDATE_OWNER_PATH = '/owners/v2/owners/:owner_id'.freeze # PUT
    DELETE_OWNER_PATH = '/owners/v2/owners/:owner_id'.freeze # DELETE

    attr_reader :properties, :owner_id, :email

    def initialize(property_hash)
      @properties = property_hash
      @owner_id   = @properties['ownerId']
      @email      = @properties['email']
    end

    def [](property)
      @properties[property]
    end

    class << self
      def all(include_inactive = false)
        path     = GET_OWNERS_PATH
        params   = { includeInactive: include_inactive }
        response = Hubspot::Connection.get_json(path, params)
        response.map { |r| new(r) }
      end

      def find_by_email(email, include_inactive = false)
        path     = GET_OWNERS_PATH
        params   = { email: email, includeInactive: include_inactive }
        response = Hubspot::Connection.get_json(path, params)
        response.blank? ? nil : new(response.first)
      end

      def find_by_emails(emails, include_inactive = false)
        emails.map { |email| find_by_email(email, include_inactive) }.reject(&:blank?)
      end
    end
  end
end
