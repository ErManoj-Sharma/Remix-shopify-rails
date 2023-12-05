module ShopifyServices 
  class ShopifyBaseService < ApplicationService
    attr_reader :graphql_client
  
    ShopifySession = ShopifyAPI::Context.active_session
  
    def initialize()
      super()
      @session = ShopifySession
    end
  
    def graphql_client
      ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
    end
  end
end