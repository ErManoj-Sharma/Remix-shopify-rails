class Api::V1::Shopify::TestQueryController < AuthenticatedController
    def create
      response = ShopifyServices::Shopify::TestQueryService.call()
      render json: {},status: :ok
    end
  end
  