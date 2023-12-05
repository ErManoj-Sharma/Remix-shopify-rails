class BulkOperationsFinishJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler
  include ShopifyServices
  BULKQUERYOUTPUT = <<~QUERY
    query($id: ID!) {
      node(id: $id) {
        ... on BulkOperation {
          status
          url
          partialDataUrl
        }
      }
    }
    QUERY
  
  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic: topic, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)
    id = arguments.first[:webhook]['admin_graphql_api_id']

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")

      raise ActiveRecord::RecordNotFound, "Shop Not Found"
    end

    shop.with_shopify_session do |session|
      query_output = ShopifyServices::ShopifyBaseService.new.graphql_client.query(
                        query: BULKQUERYOUTPUT,
                        variables: {id: id}
                      )
      p "Data Url: #{query_output.body['data']['node']['url']}"
    end
  end
end
