module ShopifyServices
  module Shopify
    class TestQueryService < ShopifyBaseService
      attr_accessor :app_installation_id

      QUERY = <<~GRAPHQL
          query {
          appByKey(apiKey: "#{ENV['SHOPIFY_API_KEY']}") {
            id
            installation{
                id
            }
          }
        }
      GRAPHQL

      QUERY2 = <<~QUERY
        mutation CreateAppDataMetafield($metafieldsSetInput: [MetafieldsSetInput!]!) {
          metafieldsSet(metafields: $metafieldsSetInput) {
            metafields {
              id
              namespace
              key
            }
            userErrors {
              field
              message
            }
          }
        }
      QUERY

      VARIABLES = {
        "metafieldsSetInput" => [
          {
            "namespace" => "UserData",
            "key" => "username",
            "type" => "single_line_text_field",
            "value" => "Manoj Was Here ",
            "ownerId" => "#{app_installation_id}"
          }
        ]
      }

      def initialize
        super()
      end

      def call
        begin
          # Query to get app installation id
          response1 = graphql_client.query(query: QUERY1)
          self.app_installation_id = response1.body['data']['appByKey']['installation']['id']

          # Query to create metafield using the obtained app_installation_id
          response2 = graphql_client.query(query: QUERY2, variables: VARIABLES)
          puts "Response: #{response2.inspect}"
        rescue StandardError => e
          puts "Error during GraphQL query: #{e.message}"
        end
      end
    end
  end
end
