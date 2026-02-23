require "faraday"
require "json"

module Rssl
  class Client
    DEFAULT_BASE_URL = "http://staging.api.rssl.com"
    API_PREFIX = "/raptor/v0"

    attr_reader :access_token

    def initialize(client_id:, client_secret:, base_url: DEFAULT_BASE_URL, timeout: 30)
      @client_id = client_id
      @client_secret = client_secret
      @base_url = base_url
      @timeout = timeout
      @access_token = nil
    end

    # Authenticates with the RSSL OAuth2 endpoint and stores the token
    # for use in subsequent API calls.
    def fetch_access_token
      data = request_json(:post, "/oauth2/token", body: {
        grant_type: "client_credentials",
        client_id: @client_id,
        client_secret: @client_secret
      }, authenticated: false)

      token = data["access_token"]
      raise "RSSL token response missing access_token: #{data.inspect}" if token.nil? || token.empty?

      @access_token = token
    end

    # GET /samples
    def list_samples
      request_json(:get, "#{API_PREFIX}/samples")
    end

    # GET /samples/{id}
    def get_sample(sample_id)
      request_json(:get, "#{API_PREFIX}/samples/#{sample_id}")
    end

    # GET /samples/{id}/results
    def list_results(sample_id)
      request_json(:get, "#{API_PREFIX}/samples/#{sample_id}/results")
    end

    # POST /samples/{id}/results — single result
    def create_result(sample_id, result_name:, result_value: "")
      request_json(:post, "#{API_PREFIX}/samples/#{sample_id}/results", body: {
        result_name: result_name,
        result_value: result_value
      })
    end

    # POST /samples/{id}/results — batch of results
    def create_results(sample_id, results)
      request_json(:post, "#{API_PREFIX}/samples/#{sample_id}/results", body: {
        results: results
      })
    end

    # GET /samples/{id}/results/{id}
    def get_result(sample_id, result_id)
      request_json(:get, "#{API_PREFIX}/samples/#{sample_id}/results/#{result_id}")
    end

    # PUT /samples/{id}/results/{id} — only result_value can be changed
    def update_result(sample_id, result_id, result_value:)
      request_json(:put, "#{API_PREFIX}/samples/#{sample_id}/results/#{result_id}", body: {
        result_value: result_value
      })
    end

    # DELETE /samples/{id}/results/{id}
    def delete_result(sample_id, result_id)
      request_json(:delete, "#{API_PREFIX}/samples/#{sample_id}/results/#{result_id}")
    end

    private

    def conn
      @conn ||= Faraday.new(url: @base_url) do |f|
        f.request :json
        f.response :raise_error
        f.options.timeout = @timeout
        f.options.open_timeout = @timeout
        f.adapter Faraday.default_adapter
      end
    end

    def authorization_headers
      raise "No access token. Call fetch_access_token first." unless @access_token

      { "Authorization" => "Bearer #{@access_token}" }
    end

    def request_json(method, path, body: nil, authenticated: true)
      response = conn.public_send(method, path) do |req|
        req.headers.merge!(authorization_headers) if authenticated
        req.body = body if body
      end

      JSON.parse(response.body.to_s)
    rescue JSON::ParserError => e
      raise "Failed to parse RSSL JSON response: #{e.message}"
    end
  end
end
