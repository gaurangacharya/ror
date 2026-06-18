class SignupGroupsController < ApplicationController
  def show
    @group = resource_scope.find(params[:id])
    @groups = resource_scope
  end

  private

  def resource_scope
    SignupGroup.active.sorted
  end
end
