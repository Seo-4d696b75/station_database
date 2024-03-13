require 'securerandom'

class IDSet
  def initialize
    @id = Set.new
  end

  def add?(id)
    id.is_a?(String) && id.match(/[0-9a-f]{6}/) && @id.add?(id)
  end

  def get
    loop do
      id = SecureRandom.hex(3)
      return id if @id.add?(id)
    end
  end
end
