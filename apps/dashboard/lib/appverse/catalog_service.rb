# frozen_string_literal: true

module Appverse
  # Fetches and caches the Appverse software catalog from openondemand.connectci.org.
  # The upstream API is a Drupal JSON:API. We query the appverse_software content type,
  # which represents software titles (e.g. "Jupyter", "RStudio") as distinct from
  # individual app implementations.
  class CatalogService
    BASE_URL    = 'https://openondemand.connectci.org/jsonapi'
    CACHE_KEY   = 'appverse/catalog_v1'
    CACHE_TTL   = 1.hour
    PAGE_LIMIT  = 50

    SOFTWARE_FIELDS = 'title,body,field_appverse_software_website,field_appverse_topics'

    AppRecord = Struct.new(
      :id,
      :title,
      :description_html,
      :description_text,
      :website_url,
      keyword_init: true
    )

    # Returns a cached array of AppRecord structs. Falls back to [] on any error
    # so the home page never hard-crashes due to a network issue.
    def self.all
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { new.fetch_all }
    rescue StandardError => e
      Rails.logger.warn("Appverse::CatalogService failed: #{e.class}: #{e.message}")
      []
    end

    def fetch_all
      records = []
      offset  = 0

      loop do
        page = fetch_page(offset)
        break if page[:data].empty?

        records += parse_records(page[:data])
        break unless page.dig(:links, :next)

        offset += PAGE_LIMIT
      end

      records.sort_by(&:title)
    end

    private

    def fetch_page(offset)
      response = RestClient.get(
        "#{BASE_URL}/node/appverse_software",
        params: {
          'fields[node--appverse_software]' => SOFTWARE_FIELDS,
          'page[limit]'                     => PAGE_LIMIT,
          'page[offset]'                    => offset
        },
        accept: :json
      )
      JSON.parse(response.body, symbolize_names: true)
    rescue RestClient::Exception, JSON::ParserError, SocketError => e
      Rails.logger.warn("Appverse API page fetch failed (offset=#{offset}): #{e.message}")
      { data: [], links: {} }
    end

    def parse_records(data)
      data.map do |item|
        attrs       = item[:attributes] || {}
        body        = attrs[:body] || {}
        website     = attrs[:field_appverse_software_website] || {}
        html_desc   = body[:processed].to_s
        plain_desc  = ActionController::Base.helpers.strip_tags(html_desc)

        AppRecord.new(
          id:               item[:id],
          title:            attrs[:title].to_s,
          description_html: html_desc,
          description_text: plain_desc,
          website_url:      website[:uri].to_s
        )
      end
    end
  end
end
