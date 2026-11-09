class UserParameters < SimpleDelegator
  def initialize(params, key = :user)
    params =
      # casa_org_id, type and password are never taken from the request: callers set them server-side
      # with with_organization / with_type / with_password, so a form can't move a user to another org,
      # change their role, or set their password.
      params.require(key).permit(
        :email,
        :display_name,
        :phone_number,
        :date_of_birth,
        :active,
        :receive_reimbursement_email,
        :monthly_learning_hours_report,
        address_attributes: [:id, :content, :line_1, :line_2, :city, :state, :zip]
      )

    super(params)
  end

  def with_organization(organization)
    params[:casa_org_id] = organization.id
    self
  end

  def with_password(password)
    params[:password] = password
    self
  end

  def with_type(type)
    params[:type] = type
    self
  end

  def without_type
    params.delete(:type)
    self
  end

  def without_active
    params.delete(:active)
    self
  end

  def with_only(*)
    params.slice!(*)
    self
  end

  def without(*keys)
    keys = keys.map(&:to_s)
    params.reject! { |key| keys.include?(key) }
    self
  end

  private

  def params
    __getobj__
  end
end
