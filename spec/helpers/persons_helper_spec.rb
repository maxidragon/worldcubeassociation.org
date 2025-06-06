# frozen_string_literal: true

require "rails_helper"

RSpec.describe PersonsHelper do
  describe "#odd_rank_reason_if_needed" do
    describe "returns the odd message" do
      it "when country rank is missing" do
        rank_single = create(:ranks_single, country_rank: 0)
        rank_average = create(:ranks_average)
        expect(odd_rank_reason_needed?(rank_single, rank_average)).to be true
      end

      it "when continent rank is missing" do
        rank_single = create(:ranks_single)
        rank_average = create(:ranks_average, continent_rank: 0)
        expect(odd_rank_reason_needed?(rank_single, rank_average)).to be true
      end

      it "when country rank is greater than continent rank" do
        rank_single = create(:ranks_single, continent_rank: 10, country_rank: 1)
        rank_average = create(:ranks_single, continent_rank: 10, country_rank: 50)
        expect(odd_rank_reason_needed?(rank_single, rank_average)).to be true
      end
    end
  end
end
