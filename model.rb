class Shortenedurl
  include DataMapper::Resource

  property :id, Serial
  property :url, Text
  property :opcional, Text
  property :email, Text
  property :nickname, Text

  has n, :visits

end

class Visit


  include DataMapper::Resource
  property  :id, Serial
  property  :created_at,  Time
  property  :ip,          IPAddress
  property  :country,     String
  property  :city, 	String

  belongs_to  :shortenedurl

end
