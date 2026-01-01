class Feed < ApplicationRecord
  validates :name, presence: true

  has_many :sources, dependent: :destroy
end

