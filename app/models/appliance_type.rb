# == Schema Information
#
# Table name: appliance_types
#
#  id                :integer          not null, primary key
#  name              :string(255)      not null
#  description       :text
#  shared            :boolean          default(FALSE), not null
#  scalable          :boolean          default(FALSE), not null
#  visibility        :string(255)      default("under_development"), not null
#  preference_cpu    :float
#  preference_memory :integer
#  preference_disk   :integer
#  security_proxy_id :integer
#  user_id           :integer
#  created_at        :datetime
#  updated_at        :datetime
#

class ApplianceType < ActiveRecord::Base
  extend Enumerize

  belongs_to :security_proxy
  belongs_to :author, class_name: 'User', foreign_key: 'user_id'

  validates_presence_of :name, :visibility
  validates_uniqueness_of :name

  enumerize :visibility, in: [:under_development, :unpublished, :published]

  validates :visibility, inclusion: %w(unpublished published)
  validates :shared, inclusion: [true, false]
  validates :scalable, inclusion: [true, false]

  validates :preference_memory, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :preference_disk, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :preference_cpu, numericality: { greater_than_or_equal_to: 0.0, allow_nil: true }

  has_many :appliances, dependent: :destroy
  has_many :port_mapping_templates, dependent: :destroy
  has_many :appliance_configuration_templates, dependent: :destroy
  has_many :virtual_machine_templates, dependent: :destroy


  def destroy(force = false)
    if !force and has_dependencies?
      errors.add :base, "ApplianceType #{name} cannot be destroyed due to existing dependencies."
      return false
    end
    super()  # Parentheses required NOT to pass 'force' as an argument (not needed in Base.destroy)
  end

  def has_dependencies?
    virtual_machine_templates.present? or appliances.present?
  end

end
