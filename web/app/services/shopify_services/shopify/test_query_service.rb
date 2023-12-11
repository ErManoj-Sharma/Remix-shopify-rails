module ShopifyServices
    module Shopify
      class TestQueryService < ShopifyBaseService
        QUERY = <<~QUERY
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
              "ownerId" => "gid://shopify/AppInstallation/660646986007"
            }
          ]
        }
  
        def initialize
          super()
        end
  
        def call
          puts "Inside Call"
          begin
            response = graphql_client.query(query: QUERY, variables: VARIABLES)
            puts "Response: #{response.inspect}"
          rescue StandardError => e
            puts "Error during GraphQL query: #{e.message}"
          end
        end
      end
    end
  end
  
  
# gid://shopify/AppInstallation/660646986007

