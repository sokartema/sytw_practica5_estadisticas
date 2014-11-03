class Shortenedurl
  include DataMapper::Resource

  property :id, Serial
  property :url, Text
  property :opcional, Text
  property :email, Text
  property :nickname, Text
  property :n_visits, Integer, :default => 0


  has n, :visits

end

class Visit
  include DataMapper::Resource
  property  :id, Serial
  property  :created_at,  Time
  property  :ip,          IPAddress
  property  :country,     String

  after :create, :init

  def init

    puts "Inside init"

    self.created_at = Time.now

    self.save

  end


  belongs_to  :shortenedurl

end
