# LtiProvider

LtiProvider is a mountable engine for handling the LTI launch and exposing LTI
parameters in your rails app.

## Installation

Add the gem to your `Gemfile` with the following line, and then `bundle install`

```
gem 'lti_provider_engine', :require => 'lti_provider'
```

Then, mount the engine to your app by adding this line to your `routes.rb` file

```
mount LtiProvider::Engine => "/"
```

Next, include the engine in your `ApplicationController`

```
class ApplicationController < ActionController::Base
  include LtiProvider::LtiApplication
  
  ...
end
```

After that, create `lti.yml` and `lti_xml.yml` files in your `config/` folder that looks something
like this:

**lti.yml**

```
default: &default
  key: your_key
  secret: your_secret
  require_canvas: true

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
```

You'll need the values of `key` and `secret` when you configure your lti app on
the tool consumer side.

**lti_xml.yml**

```
default: &default
  tool_title: 'Dummy App'
  tool_description: 'A very handy dummy application for testing LtiProvider engine integration.'
  tool_id: 'dummy'
  privacy_level: 'public'
  account_navigation:
    text: 'Dummy'
    visibility: 'admins'
  course_navigation:
    text: 'Dummy'
    visibility: 'admins'

development:
  <<: *default

test:
  <<: *default

production:
  <<: *default
```

These values are used in the `/configure.xml` endpoint.

Finally, run migrations:

```
bundle install
bundle exec rake railties:install:migrations
bundle exec rake db:migrate
```

This will create the `lti_provider_launches` table which stores parameters
temporarily through a cookie test redirect.  It is transient data.  It can be
accessed from your main application as LtiProvider::Launch

## Usage

The engine exposes a few urls from the mount point:

  * `/cookie_test`
  * `/consume_launch`
  * `/launch`
  * `/configure.xml`

Mostly, you don't have to worry about these, they are used to route through the
lti launch.  However, `/configure.xml` can be useful in configuring the app on
the tool consumer side.  Right now it is hardcoded to 'Course Navigation' and
'Account navigation' apps.

The engine sets up a global `before_filter`, requiring your app to be launched
through lti.  It handles receiving the request, verifying it, and exposing
certain config variables sent with the launch parameters. Specifically, it
exposes the following methods to your controllers:

  * `canvas_url`
  * `user_id`
  * `current_course_id`
  * `tool_consumer_instance_guid`
  * `current_account_id`
  * `course_launch?`
  * `account_launch?`

## Configuring the Tool Consumer

You will need `key` and `secret` from your `lti.yml` file, and you can find
configuration xml (or at least a starting point) at
`<engine-mount-point>/configure.xml`

## Example

You can see and interact with an example of an app using this engine by looking
at `spec/dummy`.  This is a full rails app which integrates the gem and has
a simple index page that says 'Hello LTI' if the app is launched through LTI.

## About LTI

Interested in learning more about LTI? Here are some links to get you started:

  * [Introduction to LTI](http://www.imsglobal.org/toolsinteroperability2.cfm)
  * [1.1.1 Implementation Guide](http://www.imsglobal.org/LTI/v1p1p1/ltiIMGv1p1p1.html)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
