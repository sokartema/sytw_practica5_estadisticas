module AppHelpers

  def getremoteip(env)

    puts "request.url = #{request.url}"
    puts "request.ip = #{request.ip}"
    if addr = env['HTTP_X_FORWARDED_FOR']
    puts "env['HTTP_X_FORWARDED_FOR'] = #{addr}"
    addr.split(',').first.strip

    else

    puts "env['REMOTE_ADDR'] = #{env['REMOTE_ADDR']}"
    env['REMOTE_ADDR']

    end

  end

  def getremotecountry(ip)

    xml = RestClient.get "http://ip-api.com/xml/#{ip}"
    country = XmlSimple.xml_in(xml.to_s)
    begin
    if (country['country'][0].empty?)
      "Desconocido"
    else
      country['country'][0]
    end
    rescue
    "Desconocido"
    end

  end

  def getremotecity(ip)
    xml = RestClient.get "http://ip-api.com/xml/#{ip}"
    city = XmlSimple.xml_in(xml.to_s)
    begin
      if (city['city'][0].empty?)
        "Desconocido"
      else
        city['city'][0]
      end
    rescue
      "Desconocido"
    end
  end

end
