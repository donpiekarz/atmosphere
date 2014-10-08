module Atmosphere
  module Api
    module V1
      class DevModePropertySetsController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :dev_mode_property_set,
          class: 'Atmosphere::DevModePropertySet'

        respond_to :json

        def index
          respond_with @dev_mode_property_sets.where(filter).order(:id)
        end

        def show
          respond_with @dev_mode_property_set
        end

        def update
          log_user_action "update dev mode property set #{@dev_mode_property_set.id} with following params #{dev_mode_property_set_params}"

          @dev_mode_property_set.update_attributes!(dev_mode_property_set_params)
          render json: @dev_mode_property_set, serializer:DevModePropertySetSerializer
          log_user_action "dev mode property set #{@dev_mode_property_set.id} updated #{@dev_mode_property_set.to_json}"
        end

        private

        def dev_mode_property_set_params
          allowed_params = [:name, :description, :shared, :scalable, :preference_cpu, :preference_memory, :preference_disk] + update_params_ext

          params.require(:dev_mode_property_set).permit(allowed_params)
        end

        def model_class
          Atmosphere::DevModePropertySet
        end

        include Atmosphere::Api::V1::DevModePropertySetsControllerExt
      end
    end
  end
end
