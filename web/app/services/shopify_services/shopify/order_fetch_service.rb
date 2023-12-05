module ShopifyServices 
  module Shopify
    class OrderFetchService < ShopifyBaseService
      QUERY = <<~QUERY
      mutation {
                bulkOperationRunQuery(
                 query: """
                  {
                    orders {
                      edges {
                        node {
                          id
                          name
                        }
                      }
                    }
                  }
                  """
                ) {
                  bulkOperation {
                    id
                    status
                  }
                  userErrors {
                    field
                    message
                  }
                }
              }
          QUERY
  
    def initialize()
      super()
    end
  
    def call
      graphql_client.query(query: QUERY)
    end
      
    end 
  end
end
