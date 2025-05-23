# frozen_string_literal: true

class Country < ApplicationRecord
  include Cachable
  include StaticData

  has_one :wfc_dues_redirect, as: :redirect_source

  # It is surprisingly difficult to retrieve a "clean" list of timezones.
  #   Recently, a Debian package update to the underlying `tzinfo` software in our container runtime
  #   caused error because it "sneaked" weird timezones into Ruby that our frontend couldn't render.
  # Our best effort here is to use `data_zone_identifiers`, which according to the documentation
  #   are "time zones that are defined by offsets and transitions". We then further filter by zones that
  #   contain a slash character (`/`) to make sure that quirks like "W-SU" or "Factory" are not included.
  #   (Yes, god only knows how the string literal "Factory" made its way into a curated ISO list of timezones.)
  # Signed GB 15-11-2024
  SUPPORTED_TIMEZONES = TZInfo::Timezone.all_data_zone_identifiers
                                        .filter { |tz| tz.include?('/') && !tz.match?(/\d+/) }
                                        .uniq
                                        .sort
                                        .freeze

  FICTIVE_COUNTRY_DATA_PATH = StaticData::DATA_FOLDER.join("#{self.data_file_handle}.fictive.json")
  MULTIPLE_COUNTRIES = self.parse_json_file(FICTIVE_COUNTRY_DATA_PATH).freeze

  FICTIVE_IDS = MULTIPLE_COUNTRIES.pluck(:id).freeze
  NAME_LOOKUP_ATTRIBUTE = :iso2

  include LocalizedSortable

  REAL_COUNTRY_DATA_PATH = StaticData::DATA_FOLDER.join("#{self.data_file_handle}.real.json")
  WCA_STATES_JSON = self.parse_json_file(REAL_COUNTRY_DATA_PATH, symbolize_names: false).freeze

  WCA_COUNTRIES = WCA_STATES_JSON["states_lists"].flat_map do |list|
    list["states"].map do |state|
      state_id = state["id"] || I18n.transliterate(state["name"]).tr("'", "_")
      { id: state_id, continent_id: state["continent_id"],
        iso2: state["iso2"], name: state["name"] }
    end
  end.freeze

  WCA_COUNTRY_ISO_CODES = WCA_COUNTRIES.pluck(:iso2).freeze
  WCA_COUNTRY_IDS = WCA_COUNTRIES.pluck(:id).freeze

  ALL_STATES_RAW = [
    WCA_COUNTRIES,
    MULTIPLE_COUNTRIES,
  ].flatten.freeze

  ALL_COUNTRY_IDS = ALL_STATES_RAW.pluck(:id).freeze

  def self.all_raw
    ALL_STATES_RAW
  end

  # As of writing this comment, the actual `Countries` data is controlled by WRC
  # and we only have control over the 'fictive' values. We parse the WRC file above and override
  # the `all_raw` getter to include the real countries, but they're not part of our static dataset in the stricter sense

  def self.dump_static
    MULTIPLE_COUNTRIES
  end

  def self.data_file_handle
    "#{self.name.pluralize.underscore}.fictive"
  end

  belongs_to :continent
  has_many :competitions
  has_one :band, foreign_key: :iso2, primary_key: :iso2, class_name: "CountryBand"

  def continent
    Continent.c_find(self.continent_id)
  end

  def self.find_by_iso2(iso2)
    c_values.find { |c| c.iso2 == iso2 }
  end

  def multiple_countries?
    MULTIPLE_COUNTRIES.any? { |c| c[:id] == self.id }
  end
end
