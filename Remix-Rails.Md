### Pre-Requests
```ruby
node -v 
-> v20.9.0
```
```ruby
ruby -v
-> ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-linux]
```
```ruby
npm -v 
-> 10.2.4
```
```ruby
rails -v 
-> Rails 7.0.8
```
```ruby
Shopify App Gem 
gem "shopify_app", "~> 21.7"
```


### Create a Shopify + Remix + Rails App
```ruby
npm init @shopify/app@latest -- --template=ruby
```

#### Run Following Commands to Setting up your Rails app
Once the Shopify CLI clones the repo, you will be able to run commands on your app.
However, the CLI will not manage your Ruby dependencies automatically, so you will need to go through some steps to be able to run your app.
To make the process easier, the template provides a script to run the necessary steps:

1. Start off by switching to the `web` folder:
   ```shell
   cd web
   ```
1. Install the ruby dependencies:
   ```shell
   bundle install
   ```
1. Run the [Rails template](https://guides.rubyonrails.org/rails_application_templates.html) script.
   It will guide you through setting up your database and set up the necessary keys for encrypted credentials.
   ```shell
   bin/rails app:template LOCATION=./template.rb
   ```

And your Rails app is ready to run! You can now switch back to your app's root folder to continue:

```shell
cd ..
```
#### Edit and See Credientials
1. Edit Credientials 
   ```
   EDITOR="code --wait" bin/rails credentials:edit
   ```
1. See Credientials
   ```
   EDITOR="code --wait" bin/rails credentials:show
   ```

###  ClientId and Secret Setup
In Remix App , App will setup ClientId ans Secret Automatically when you start the App

To Reset the Configuration 

1.  run this command in terminal 
      ```
      npm run dev -- --reset
      ```
1. Select the Configuration
   ```
   ?  Create this project as a new app on Shopify?
   ✔  Yes, Create New app
   ✔  No, connect it to an existing app
   ```
   ```
   ?  Which existing app is this for?
   ✔  App Name
   ```
   ```
   ?  Configuration file name:
   ✔  configurations_file_name.toml
   ```
   ```
   ?  Which store would you like to use to view your project?
   ✔  Your Store Name
   ```
This Will create a `configuration_file_name.toml` in root folder
This File contains the configuration

1. Client Id
2. Application Url
3. Access Scope 
4. Webhooks 
5. Pos
6. Build 

#### Add Postgres as Database
Add `pg` Gem in Gemfile & Run `bundle`
```shell
gem "pg", "~> 1.5"
```
Go to `config/database.yml` & Add Following Configuration
```shell
default: &default
  adapter: postgresql
  encoding: unicode
  database: your_database_name
  pool: 5
  username: your_username
  password: your_password
  host: localhost

```
Make Sure You have Valid User and Password

#### Add Env in Rails 
Add this `dotenv-rails` gem in Gemfile & run `bundle`
```shell
gem 'dotenv-rails', groups: [:development, :test]
```
Add this Configuration
```shell
# config/application.rb
Bundler.require(*Rails.groups)

# Load dotenv only in development or test environment
if ['development', 'test'].include? ENV['RAILS_ENV']
  Dotenv::Railtie.load
end
```

## WebHook Failed Issue 
Add Following Line in ApplicationController
```ruby
# web/app/controllers/application_controller
class ApplicationController < ActionController::Base
  skip_forgery_protection
end

```
```ruby
# web/app/controllers/authenticatd_controller
class AuthenticatedController < ApplicationController
  include ShopifyApp::EnsureHasSession
end
```
`include ShopifyApp::EnsureHasSession` : the concern verfiy that each child controller of AuthenticatedController verfiy CSRF token before any action [Link](https://github.com/Shopify/shopify_app/blob/b0e4d4a3df8ee382e2ba035218212c344c428cfc/app/controllers/concerns/shopify_app/ensure_has_session.rb)

`include ShopifyApp::WebhookVerification` : this concern is included in Webhooks Controller and it bypass CSRF verfication in Webhooks [Link](https://github.com/Shopify/shopify_app/blob/b0e4d4a3df8ee382e2ba035218212c344c428cfc/lib/shopify_app/controller_concerns/webhook_verification.rb)

```ruby
# web/app/controllers/shopify_app/webhooks_controller
module ShopifyApp
   class WebhooksController < ActionController::Base
      include ShopifyApp::WebhookVerification
   end
end
```

## Add a new webhook [Doc](https://shopify.dev/docs/api/admin-rest/2023-10/resources/webhook)
1. products/update webhook
   ```ruby
   rails g shopify_app:add_webhook --topic WEBHOOK_TOPIC --path webhooks/WEBHOOK_TOPIC
   ```
   ```ruby
   # products/update webhook 
   rails g shopify_app:add_webhook --topic products/update --path webhooks/products_update
   ```
   The Above Command create following file and update  shopify_app.rb 
   ```ruby
   # web/app/jobs/products_update_job.rb
   class ProductsUpdateJob < ActiveJob::Base
     extend ShopifyAPI::Webhooks::Handler
     class << self
       def handle(topic:, shop:, body:)
         perform_later(topic: topic, shop_domain: shop, webhook: body)
       end
     end
   
     def perform(topic:, shop_domain:, webhook:)
       shop = Shop.find_by(shopify_domain: shop_domain)
   
       if shop.nil?
         logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
   
         raise ActiveRecord::RecordNotFound, "Shop Not Found"
       end
   
       shop.with_shopify_session do |session|
       end
     end
   end
   
   ```
   ```ruby
   # web/config/initializers/shopify_app.rb
     config.webhooks = [
      { topic: "products/update", path: "api/webhooks/products_update" },
       { topic: "app/uninstalled", address: "api/webhooks/app_uninstalled"},
      ]
   ```
2. bulk_operations_finish webhook
   ```ruby
   # bulk_operations/finish webhook 
   rails g shopify_app:add_webhook --topic bulk_operations/finish --path webhooks/bulk_operations_finish
   ```
   The Above Command create following file and update  shopify_app.rb 
   ```ruby
   # web/app/jobs/products_update_job.rb
   class BulkOperationsFinishJob < ActiveJob::Base
     extend ShopifyAPI::Webhooks::Handler
     # Query to execute bulk job 
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
         query_output = ShopifyAPI::Clients::Graphql::Admin.new(session:).query(
                           query: BULKQUERYOUTPUT,
                           variables: {id: id}
         
         # data url which contain data in json format                )
         p "Data Url: #{query_output.body['data']['node']['url']}"
       end
     end
    end
   ```
   ```ruby
   # web/config/initializers/shopify_app.rb
     config.webhooks = [
       { topic: "products/update", path: "api/webhooks/products_update" },
       { topic: "app/uninstalled", address: "api/webhooks/app_uninstalled"},
       { topic: "bulk_operations/finish", path: "api/webhooks/bulk_operations_finish" },

      ]
   ```
   Note :  Before using Orders Scopes
   1. Go to Application Settings
   2. go API Access 
   3. Click on Access Request 
   4. Take Necesssary Protected customer data access 

To Use Webhooks in Effective Way 
Follow these Instruction 

1. Make a controller with Index Action 
```shell
rails g controller api/v1/shopify/fetch_orders create
rails g controller api/v1/shopify/orders create destroy
```
2. in routes use resource routes 
```ruby
# web/config/routes.rb
namespace :api, defaults: { format: :json } do
    namespace :v1 do
      namespace :shopify do
        resources :order_fetch ,  only: [:create]
        resource :orders, only: [:create, :destroy]
      end
    end
  end
```
3. Make Service for Api Calls and Use them in Controller 
```ruby
# web/app/controllers/api/v1/shopify/order_fetch_controller.rb
class Api::V1::Shopify::OrderFetchController < AuthenticatedController
  def create
    response = ShopifyServices::Shopify::OrderFetchService.call()
    render json: {},status: :ok
  end
end
```
```ruby
#web/app/services/shopify_services/shopify/order_fetch_service.rb
module ShopifyServices 
  module Shopify
    class OrderFetchService < ShopifyBaseService
      def initialize()
        super()
      end
  
      # Write you Query and bussiness logic here
      def call
        graphql_clientquery(query: GRAPHQL_QUERY)
      end
    end 
  end
end
```
```ruby
# You can make a base service class
# web/app/services/shopify_services/shopify_base_service.rb
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
```   

## Add New Access Scope 
[Add Scopes](https://shopify.dev/docs/apps/tools/cli/configuration#access_scopes) in `.toml` file with coma(,) seperated strings
```ruby
[access_scopes]
scopes = "write_products,read_orders,write_orders"
```
push scope to partner configuration by 
```shell
npm run shopify app config push
```

## Add New theme Extension [Link](https://shopify.dev/docs/apps/online-store/theme-app-extensions/getting-started) 
1. create new theme Extension
   ```ruby
   npm run shopify app generate extension
   ```
   ```shell
   ?  Type of extension?
   ✔  Theme app extension
   ```
   ```shell
   ?  Name your extension:
   ✔  YOUR_EXTENSION_NAME
   ```
   `Your extension was created in extensions/YOUR_EXTENSION_NAME.`
1. start the server 
   ```shell
   npm run dev
   ```
3. To use this extention
    
    a. Go to https://admin.shopify.com/store/YOUR_SHOPIFY_DOMAIN
  
    b.   Sales Channel > Online Store > Customize 
  
    d. Click on `add section`  or `add block` 
  
    e. You can see `YOUR_EXTENSION_NAME` in `apps`  
## Installation guide 
1. Clone the Repository
   ```shell
   git clone https://github.com/ErManoj-Sharma/Remix-shopify-rails.git
   ```
2. change directory 
   ```shell
   cd Remix-shopify-rails/
   ```
3. Update Application name in `pacakage.json` and `pacakage-lock.json`
   ```javascript
   {
     "name": "MyAppName",
     "version": "1.0.1",
     "license": "UNLICENSED",
     :
     :
   }
   ```
4. run 
   ``` 
   npm install
   ```
5. Change directory 
   ```shell
   cd web/
   ```
6. Genereate a new Credientials file 
   ```shell
   EDITOR="code --wait" bin/rails credentials:edit
   ```
7. Update Database.yml file 
   ```shell
   # web/config/database.yml
   default: &default
     adapter: postgresql
     encoding: unicode
     database: MyDabaseName
     pool: 5
     username: POSTGRES_USERNAME # postgres
     password: POSTGRES_PASSWORD # postgres
     host: HOST # localhost
     port: PORT # 5432
   ```
8. Create Database and Migrate 
   ##### create database
   ```shell
   rails db:create
   ```
   ##### migrate database
   ```shell
   rails db:migrate
   ```
   ##### reset database
   ```shell
   rails db:reset
   ```
9. go back 
   ```shell
   cd ..
   ```
10. start server 
   ```shell
   npm run dev 
   ```