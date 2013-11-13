WIDTH=2048.0

class Float
  def to_rgb
    a = (self*(16777216-0.5)).floor.divmod 65536
    b = a[1].divmod 256
    throw "underflow: #{self}." if a[0]<0
    throw "overflow: #{self}." if a[0]>255
    [a[0], b[0], b[1]]
  end
end

if ARGV[0]=='asin'
  func = lambda{|x,y| 0.5+Math.asin(x)/Math::PI }
  name = "math_asin.png"
  HEIGHT=2.0
else
  func = lambda{|x,y| (Math.atan2(y,x)/Math::PI+1)/2 }
  name = "math_atan.png"
  HEIGHT=WIDTH
end

puts "Rendering #{name}, size=#{WIDTH}x#{HEIGHT} ..."
IO.popen("convert -depth 8 -size #{WIDTH}x#{HEIGHT} rgb:- #{name}", "r+"){|io|
  (0..(HEIGHT-1)).each{|v|
    (0..(WIDTH-1)).each{|u|
      x = 2*u/(WIDTH-1)-1
      y = 2*v/(HEIGHT-1)-1
      k = func.call(x, y)
      #print k.to_rgb.inspect + " "
      c = k.to_rgb
      io.print c.pack("C3")
    }
  }
}
