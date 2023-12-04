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