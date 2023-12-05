class Api::V1::Shopify::OrderFetchController < AuthenticatedController
  def create
    response = ShopifyServices::Shopify::OrderFetchService.call()
    render json: {},status: :ok
  end
end
