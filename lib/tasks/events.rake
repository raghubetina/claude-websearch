namespace :events do
  desc "TODO"
  task pull: :environment do

    pp "Searching for jazz events in Chicago this weekend...."

    ENDPOINT = "https://api.anthropic.com/v1/messages"

    require "json"
    require "http"                 # gem install http
    require "dotenv/load"

    API_KEY  = ENV.fetch("ANTHROPIC_API_KEY")
    ENDPOINT = "https://api.anthropic.com/v1/messages"

    payload = {
      model: "claude-3-7-sonnet-20250219",
      max_tokens: 64000,
      tool_choice: { type: "auto" },
      tools: [
        { 
          type: "web_search_20250305",
          name: "web_search"
        },

        {
          type:        "custom",
          name:        "answer_json",
          description: "Return the final structured answer.",
          input_schema: {
            type: "object",
            properties: {
              events: {
                type:  "array",
                items: {
                  type: "object",
                  properties: {
                    name:        { type: "string" },
                    venue:       { type: "string" },
                    address:     { type: "string" },
                    date:        { type: "string", format: "date" },          # YYYY-MM-DD
                    start_time:  { type: "string", pattern: "^\\d{2}:\\d{2}$" }, # HH:MM
                    price:       { type: "string" },
                    ticket_url:  { type: "string", format: "uri" },
                    description: { type: "string" }
                  },
                  required: %w[name venue date start_time],
                  additionalProperties: false
                }
              },
              source_urls: {
                type:  "array",
                items: { type: "string", format: "uri" }
              }
            },
            required: ["events"],
            additionalProperties: false
          }
        }
      ],
      messages: [
        {
          role:    "user",
          content: "What are the best small live jazz events happening in Chicago this weekend? "\
                  "Return the answer as JSON."
        }
      ]
    }

    response = HTTP
      .headers(
        "Content-Type" => "application/json",
        "x-api-key"    => API_KEY,
        "anthropic-version" => "2023-06-01"
      )
      .post(ENDPOINT, body: JSON.dump(payload))

    puts JSON.pretty_generate(JSON.parse(response.body))

    # Loop through the array of items, save each one to database
    # While doing that, look up the current existing records and ask the AI
    # whether it is a duplicate
  end

end
