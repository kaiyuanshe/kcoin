class CosconPoll2018 < Sequel::Model(:coscon_poll_2018)
  plugin :timestamps
  plugin :validation_helpers

  def validate
    super
    validates_presence [:email]
    validates_format RegexPattern::Email, :email, {:allow_nil => false}
  end

  def self.import(email)
    if CosconPoll2018.first(email: email).nil?
      CosconPoll2018.insert(
        email: email,
        kcoin_issued: false,
        created_at: Time.now
      )
    end
  end
end