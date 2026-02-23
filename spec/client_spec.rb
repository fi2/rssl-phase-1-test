require_relative "../client"

RSpec.describe Rssl::Client, order: :defined do
  let(:client) do
    Rssl::Client.new(
      client_id: "41ae877c-78ca-40e9-8218-89455e1c3520",
      client_secret: "fa5716e7-d6d6-4c76-843f-97a6a066768a"
    )
  end

  before(:all) do
    @client = Rssl::Client.new(
      client_id: "41ae877c-78ca-40e9-8218-89455e1c3520",
      client_secret: "fa5716e7-d6d6-4c76-843f-97a6a066768a"
    )
    @client.fetch_access_token
  end

  describe "#fetch_access_token" do
    it "authenticates and returns a token string" do
      token = client.fetch_access_token

      expect(token).to be_a(String)
      expect(token).not_to be_empty
      expect(client.access_token).to eq(token)
    end
  end

  describe "#list_samples" do
    it "returns a hash containing an array of samples" do
      result = @client.list_samples

      expect(result).to have_key("samples")
      expect(result["samples"]).to be_an(Array)
      expect(result["samples"]).not_to be_empty

      sample = result["samples"].first
      expect(sample).to have_key("sample_number")
      expect(sample).to have_key("rssl_code")
      expect(sample).to have_key("description")
    end
  end

  describe "#get_sample" do
    it "returns a single sample record" do
      result = @client.get_sample(101)

      expect(result["sample_number"]).to eq(101)
      expect(result).to have_key("rssl_code")
      expect(result).to have_key("description")
    end
  end

  describe "#list_results" do
    it "returns a hash containing an array of results for a sample" do
      result = @client.list_results(101)

      expect(result).to have_key("results")
      expect(result["results"]).to be_an(Array)
    end
  end

  describe "result CRUD lifecycle" do
    it "creates a single result, reads it, updates it, and deletes it" do
      # CREATE
      create_response = @client.create_result(101, result_name: "RSpec Integration Test")
      expect(create_response).to be_a(Hash)

      # Find the newly created result by listing all results
      results = @client.list_results(101)
      created = results["results"].find { |r| r["result_name"] == "RSpec Integration Test" }
      expect(created).not_to be_nil
      result_id = created["result_number"]

      # GET single result
      fetched = @client.get_result(101, result_id)
      expect(fetched["result_number"]).to eq(result_id)
      expect(fetched["result_name"]).to eq("RSpec Integration Test")

      # UPDATE
      update_response = @client.update_result(101, result_id, result_value: "42.0")
      expect(update_response).to be_a(Hash)

      # Verify the update took effect
      updated = @client.get_result(101, result_id)
      expect(updated["result_value"]).to eq("42.0")

      # DELETE
      delete_response = @client.delete_result(101, result_id)
      expect(delete_response).to be_a(Hash)

      # Verify deletion — the result should no longer appear in the list
      remaining = @client.list_results(101)
      ids = remaining["results"].map { |r| r["result_number"] }
      expect(ids).not_to include(result_id)
    end
  end

  describe "#create_results (batch)" do
    it "creates multiple results in a single request and cleans them up" do
      batch = [
        { result_name: "RSpec Batch 1", result_value: "10.0" },
        { result_name: "RSpec Batch 2", result_value: "20.0" }
      ]

      response = @client.create_results(101, batch)
      expect(response).to be_a(Hash)

      results = @client.list_results(101)
      created = results["results"].select { |r| r["result_name"].start_with?("RSpec Batch") }
      expect(created.length).to eq(2)

      # Clean up
      created.each do |r|
        @client.delete_result(101, r["result_number"])
      end
    end
  end

  describe "authentication enforcement" do
    it "raises when calling an API method without fetching a token first" do
      unauthenticated = Rssl::Client.new(
        client_id: "41ae877c-78ca-40e9-8218-89455e1c3520",
        client_secret: "fa5716e7-d6d6-4c76-843f-97a6a066768a"
      )

      expect { unauthenticated.list_samples }.to raise_error(RuntimeError, /No access token/)
    end
  end
end
