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


  belongs_to  :shortenedurl

  after :create, :set_country
  

  def set_country
    xml = RestClient.get "http://api.hostip.info/get_xml.php?ip=#{self.ip}"
    self.country = XmlSimple.xml_in(xml.to_s)
    self.save
  end
end
