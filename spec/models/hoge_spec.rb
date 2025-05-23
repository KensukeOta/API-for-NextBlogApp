require 'rails_helper'

RSpec.describe Hoge, type: :model do
  describe "factory" do
    it "has a valid factory" do
      hoge = create(:hoge)
      expect(hoge).to be_valid
    end
  end
end
