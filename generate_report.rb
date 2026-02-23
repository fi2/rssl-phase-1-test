require_relative "client"
require "json"

class ReportGenerator
  SAMPLE_ID = 101

  def initialize
    @client = Rssl::Client.new(
      client_id: "41ae877c-78ca-40e9-8218-89455e1c3520",
      client_secret: "fa5716e7-d6d6-4c76-843f-97a6a066768a"
    )
    @tests = []
    @pass_count = 0
    @fail_count = 0
  end

  def run
    test_fetch_access_token
    test_list_samples
    test_get_sample
    test_list_results
    test_create_single_result
    test_create_batch_results
    test_get_single_result
    test_update_result
    test_delete_result
    test_verify_deletion
    test_authentication_enforcement

    write_report
  end

  private

  def record_test(name:, method:, endpoint:, request_body: nil, response:, assertions:, passed:)
    status = passed ? "PASS" : "FAIL"
    passed ? @pass_count += 1 : @fail_count += 1
    @tests << {
      name: name, method: method, endpoint: endpoint,
      request_body: request_body, response: response,
      assertions: assertions, status: status
    }
  end

  # --- Tests ---

  def test_fetch_access_token
    response = @client.fetch_access_token
    token = @client.access_token

    assertions = [
      check("Token is a non-empty string", token.is_a?(String) && !token.empty?)
    ]

    record_test(
      name: "Authenticate — fetch access token",
      method: "POST",
      endpoint: "/oauth2/token",
      request_body: { grant_type: "client_credentials", client_id: "41ae877c-...", client_secret: "fa5716e7-..." },
      response: { access_token: "#{token[0..40]}...", token_type: "bearer" },
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  def test_list_samples
    response = @client.list_samples
    samples = response["samples"]

    assertions = [
      check("Response contains 'samples' key", response.key?("samples")),
      check("'samples' is an array", samples.is_a?(Array)),
      check("Array is not empty", !samples.empty?),
      check("Each sample has 'sample_number'", samples.all? { |s| s.key?("sample_number") }),
      check("Each sample has 'rssl_code'", samples.all? { |s| s.key?("rssl_code") }),
      check("Each sample has 'description'", samples.all? { |s| s.key?("description") })
    ]

    record_test(
      name: "List all samples",
      method: "GET",
      endpoint: "/raptor/v0/samples",
      response: response,
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  def test_get_sample
    response = @client.get_sample(SAMPLE_ID)

    assertions = [
      check("Response contains 'sample_number'", response.key?("sample_number")),
      check("sample_number matches requested id (#{SAMPLE_ID})", response["sample_number"] == SAMPLE_ID),
      check("Response contains 'rssl_code'", response.key?("rssl_code")),
      check("Response contains 'description'", response.key?("description"))
    ]

    record_test(
      name: "Get a single sample",
      method: "GET",
      endpoint: "/raptor/v0/samples/#{SAMPLE_ID}",
      response: response,
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  def test_list_results
    response = @client.list_results(SAMPLE_ID)
    results = response["results"]

    assertions = [
      check("Response contains 'results' key", response.key?("results")),
      check("'results' is an array", results.is_a?(Array))
    ]

    if results && !results.empty?
      assertions += [
        check("Each result has 'result_number'", results.all? { |r| r.key?("result_number") }),
        check("Each result has 'sample_number'", results.all? { |r| r.key?("sample_number") }),
        check("Each result has 'result_name'", results.all? { |r| r.key?("result_name") }),
        check("Each result has 'result_value'", results.all? { |r| r.key?("result_value") })
      ]
    end

    record_test(
      name: "List results for a sample",
      method: "GET",
      endpoint: "/raptor/v0/samples/#{SAMPLE_ID}/results",
      response: response,
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  def test_create_single_result
    body = { result_name: "Report Test Single", result_value: "99.9" }
    response = @client.create_result(SAMPLE_ID, result_name: body[:result_name], result_value: body[:result_value])

    results_after = @client.list_results(SAMPLE_ID)["results"]
    created = results_after.find { |r| r["result_name"] == "Report Test Single" }

    assertions = [
      check("API returns a hash (empty JSON object)", response.is_a?(Hash)),
      check("New result appears in results list", !created.nil?),
      check("Created result has correct name", created && created["result_name"] == "Report Test Single"),
      check("Created result has correct value", created && created["result_value"] == "99.9")
    ]

    @created_single_id = created["result_number"] if created

    record_test(
      name: "Create a single result",
      method: "POST",
      endpoint: "/raptor/v0/samples/#{SAMPLE_ID}/results",
      request_body: body,
      response: response,
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  def test_create_batch_results
    body = {
      results: [
        { result_name: "Report Batch A", result_value: "10.0" },
        { result_name: "Report Batch B", result_value: "20.0" }
      ]
    }

    response = @client.create_results(SAMPLE_ID, body[:results])

    results_after = @client.list_results(SAMPLE_ID)["results"]
    batch_a = results_after.find { |r| r["result_name"] == "Report Batch A" }
    batch_b = results_after.find { |r| r["result_name"] == "Report Batch B" }

    assertions = [
      check("API returns a hash (empty JSON object)", response.is_a?(Hash)),
      check("Batch result A appears in results list", !batch_a.nil?),
      check("Batch result B appears in results list", !batch_b.nil?),
      check("Batch result A has correct value", batch_a && batch_a["result_value"] == "10.0"),
      check("Batch result B has correct value", batch_b && batch_b["result_value"] == "20.0")
    ]

    @batch_ids = [batch_a&.dig("result_number"), batch_b&.dig("result_number")].compact

    record_test(
      name: "Create multiple results (batch)",
      method: "POST",
      endpoint: "/raptor/v0/samples/#{SAMPLE_ID}/results",
      request_body: body,
      response: response,
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  def test_get_single_result
    return skip_test("Get a single result", "No result_id available from prior create") unless @created_single_id

    response = @client.get_result(SAMPLE_ID, @created_single_id)

    assertions = [
      check("result_number matches requested id", response["result_number"] == @created_single_id),
      check("sample_number matches #{SAMPLE_ID}", response["sample_number"] == SAMPLE_ID),
      check("result_name is 'Report Test Single'", response["result_name"] == "Report Test Single"),
      check("result_value is '99.9'", response["result_value"] == "99.9")
    ]

    record_test(
      name: "Get a single result",
      method: "GET",
      endpoint: "/raptor/v0/samples/#{SAMPLE_ID}/results/#{@created_single_id}",
      response: response,
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  def test_update_result
    return skip_test("Update a result", "No result_id available from prior create") unless @created_single_id

    body = { result_value: "UPDATED-777" }
    response = @client.update_result(SAMPLE_ID, @created_single_id, result_value: body[:result_value])

    updated = @client.get_result(SAMPLE_ID, @created_single_id)

    assertions = [
      check("API returns a hash (empty JSON object)", response.is_a?(Hash)),
      check("result_value was updated to 'UPDATED-777'", updated["result_value"] == "UPDATED-777")
    ]

    record_test(
      name: "Update a result value",
      method: "PUT",
      endpoint: "/raptor/v0/samples/#{SAMPLE_ID}/results/#{@created_single_id}",
      request_body: body,
      response: response,
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  def test_delete_result
    return skip_test("Delete a result", "No result_id available from prior create") unless @created_single_id

    response = @client.delete_result(SAMPLE_ID, @created_single_id)

    assertions = [
      check("API returns a hash (empty JSON object)", response.is_a?(Hash))
    ]

    record_test(
      name: "Delete a result",
      method: "DELETE",
      endpoint: "/raptor/v0/samples/#{SAMPLE_ID}/results/#{@created_single_id}",
      response: response,
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  def test_verify_deletion
    return skip_test("Verify deletion", "No result_id available from prior create") unless @created_single_id

    results = @client.list_results(SAMPLE_ID)["results"]
    ids = results.map { |r| r["result_number"] }

    assertions = [
      check("Deleted result no longer appears in results list", !ids.include?(@created_single_id))
    ]

    record_test(
      name: "Verify deleted result is gone",
      method: "GET",
      endpoint: "/raptor/v0/samples/#{SAMPLE_ID}/results",
      response: { remaining_result_ids: ids },
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )

    # Clean up batch results
    @batch_ids.each { |id| @client.delete_result(SAMPLE_ID, id) } if @batch_ids
  end

  def test_authentication_enforcement
    unauthenticated = Rssl::Client.new(
      client_id: "41ae877c-78ca-40e9-8218-89455e1c3520",
      client_secret: "fa5716e7-d6d6-4c76-843f-97a6a066768a"
    )

    error_raised = false
    error_message = nil
    begin
      unauthenticated.list_samples
    rescue RuntimeError => e
      error_raised = true
      error_message = e.message
    end

    assertions = [
      check("RuntimeError is raised", error_raised),
      check("Error message mentions missing token", error_message&.include?("No access token"))
    ]

    record_test(
      name: "Unauthenticated request is rejected by client",
      method: "N/A",
      endpoint: "N/A (client-side guard)",
      response: { error: error_message },
      assertions: assertions,
      passed: assertions.all? { |a| a[:passed] }
    )
  end

  # --- Helpers ---

  def check(description, result)
    { description: description, passed: result }
  end

  def skip_test(name, reason)
    @fail_count += 1
    @tests << {
      name: name, method: "N/A", endpoint: "N/A",
      request_body: nil, response: nil,
      assertions: [{ description: "SKIPPED: #{reason}", passed: false }],
      status: "SKIP"
    }
  end

  def write_report
    total = @pass_count + @fail_count
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")

    lines = []
    lines << "# RSSL Subcontractor API — Test Report"
    lines << ""
    lines << "**Generated:** #{timestamp}"
    lines << "**Target:** `#{Rssl::Client::DEFAULT_BASE_URL}`"
    lines << "**API Version:** v0 (simulation)"
    lines << ""
    lines << "## Summary"
    lines << ""
    lines << "| Metric | Count |"
    lines << "|--------|-------|"
    lines << "| Total tests | #{total} |"
    lines << "| Passed | #{@pass_count} |"
    lines << "| Failed | #{@fail_count} |"
    lines << "| Pass rate | #{total > 0 ? (((@pass_count.to_f / total) * 100).round(1)) : 0}% |"
    lines << ""
    lines << "---"
    lines << ""

    @tests.each_with_index do |t, i|
      icon = t[:status] == "PASS" ? "PASS" : "FAIL"
      lines << "## #{i + 1}. #{t[:name]}"
      lines << ""
      lines << "| | |"
      lines << "|---|---|"
      lines << "| **Status** | `#{icon}` |"
      lines << "| **HTTP Method** | `#{t[:method]}` |"
      lines << "| **Endpoint** | `#{t[:endpoint]}` |"
      lines << ""

      if t[:request_body]
        lines << "**Request Body:**"
        lines << ""
        lines << "```json"
        lines << JSON.pretty_generate(t[:request_body])
        lines << "```"
        lines << ""
      end

      if t[:response]
        lines << "**API Response:**"
        lines << ""
        lines << "```json"
        lines << JSON.pretty_generate(t[:response])
        lines << "```"
        lines << ""
      end

      lines << "**Assertions:**"
      lines << ""
      t[:assertions].each do |a|
        mark = a[:passed] ? "[x]" : "[ ]"
        lines << "- #{mark} #{a[:description]}"
      end
      lines << ""
      lines << "---"
      lines << ""
    end

    report = lines.join("\n")
    File.write("test_report.md", report)
    puts "Report written to test_report.md"
    puts "#{@pass_count}/#{total} tests passed"
  end
end

ReportGenerator.new.run
