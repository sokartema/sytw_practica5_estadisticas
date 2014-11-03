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

end
