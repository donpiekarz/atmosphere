class Admin::ApplianceTypesController < ApplicationController

  before_filter :set_appliance_types#, only: [:index, :show, :new, :create, :destroy]
  load_and_authorize_resource :appliance_type

  # GET /admin/appliance_types
  def index
  end

  # GET /admin/appliance_types/1
  def show
  end

  # GET /admin/appliance_types/new
  def new
  end

  # POST /admin/appliance_types
  def create
    if @appliance_type.save appliance_type_params
      redirect_to [:admin, @appliance_type], notice: 'Appliance Type was successfully created.'
    else
      render action: 'new'
    end
  end

  # GET /admin/appliance_types/1/edit
  def edit
  end

  # PATCH/PUT /admin/appliance_types/1
  def update
    if @appliance_type.update appliance_type_params
      redirect_to [:admin, @appliance_type], notice: 'Appliance Type was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /admin/appliance_types/1
  def destroy
    if @appliance_type.destroy
      redirect_to [:admin, :appliance_types], notice: 'ApplianceType was successfully destroyed.'
    else
      flash[:alert] = @appliance_type.errors.full_messages.join('</br>')
      render action: 'show'
    end
  end


  private

    def set_appliance_types
      @appliance_types = ApplianceType.all.def_order
    end

    # Only allow a trusted parameter "white list" through.
    def appliance_type_params
      params.require(:appliance_type).permit(
        :name, :description, :visibility, :shared, :scalable, :user_id,
        :preference_memory, :preference_disk,  :preference_cpu)
    end
end