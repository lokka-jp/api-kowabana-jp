require 'sinatra'
require 'sinatra/json'
require 'yaml'
require 'json'
require 'google/api_client'

get '/current_week/sessions.json' do
  config = YAML.load_file('config.yml')

  client = Google::APIClient.new(
    application_name: config['app_name'],
    authorization: :oauth_2
  )
  client.authorization.scope = config['scope']
  client.authorization.client_id = config['client_id']
  client.authorization.client_secret = config['client_secret']
  client.authorization.access_token = config['access_token']
  client.authorization.refresh_token = config['refresh_token']

  analytics = client.discovered_api('analytics', 'v3')

  start_date = Time.now - 60 * 60 * 24 * 8
  end_date = Time.now - 60 * 60 * 24 * 1

  result = client.execute(
    api_method: analytics.data.ga.get,
    parameters: {
      'ids' => config['profile'],
      'start-date' => start_date.to_date.strftime('%Y-%m-%d'),
      'end-date' => end_date.to_date.strftime('%Y-%m-%d'),
      'metrics' => 'ga:pageviews,ga:visits'
    }
  )
  fail result.response.body.to_s if result.status != 200
  pageviews, visits = result.data.rows.flatten
  response = {
    sessions: visits.to_i
  }

  json response
end
