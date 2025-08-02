class ErrorSerializer
  include Alba::Resource

  root_key :errors

  def serialize(errors)
    errors
  end
end
