class Atmosphere::Admin::PortMappingTemplatesController < Atmosphere::Admin::ApplicationController

  # NOTE: all actions below do Ajax/JSON

  load_and_authorize_resource :appliance_type,
    class: 'Atmosphere::ApplianceType'

  load_and_authorize_resource :port_mapping_template,
    through: :appliance_type,
    class: 'Atmosphere::PortMappingTemplate'

  before_filter :initialize_manager, only: [:create, :update, :destroy]
  layout false


  # GET /admin/appliance_types/1/port_mapping_templates
  def index
    render partial: 'index'
  end

  # GET /admin/appliance_types/1/port_mapping_templates/new
  def new
    render partial: 'edit'
  end

  # POST /admin/appliance_types/1/port_mapping_templates
  def create
    @manager.save!
    render_index
  end

  # GET /admin/appliance_types/1/port_mapping_templates/1/edit
  def edit
    render partial: 'edit'
  end

  # PATCH/PUT /admin/appliance_types/1/port_mapping_templates/1
  def update
    @manager.update!(port_mapping_template_params)
    render_index
  end

  # DELETE /admin/appliance_types/1/port_mapping_templates/1
  def destroy
    @manager.destroy
    render_index
  end


  private

  # Only allow a trusted parameter "white list" through.
  def port_mapping_template_params
    params.require(:port_mapping_template).permit(
      :service_name, :target_port, :transport_protocol, :application_protocol, :appliance_type_id)
  end

  # Set a simple flash-like message for the user and show the PMTs index
  def render_index
    if @port_mapping_template.errors.blank?
      @notice = "Port Mapping was successfully #{request[:action]}ed.".gsub('ee','e') # ;)
    else
      @alert = @port_mapping_template.errors.full_messages.join('</br>')
    end
    render partial: 'index'
  end

  def initialize_manager
    @manager = Atmosphere::AffectedApplianceAwareManager.new(@port_mapping_template, Atmosphere::AppliancesAffectedByPmt)
  end
end
