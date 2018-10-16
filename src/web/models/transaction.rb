class KCoinTransaction < Sequel::Model(:transactions)
  plugin :timestamps
  plugin :validation_helpers
  plugin :json_serializer

  def validate
    super
    validates_presence [:transaction_id, :message]
  end

end