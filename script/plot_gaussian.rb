#!/usr/bin/env ruby

require 'gnuplot'

SQRT_2PI = Math.sqrt(2*Math::PI)

# a*exp(- (x-b)**2 / 2c**2 ) + d

def gaussian(a, b, c, d, xvals)
  xvals.map do |x|
    a*Math.exp(-(x-b)**2 / 2*c**2 ) + d
  end
end

xvals = xrange=(0.2..8.2).step(1).to_a

a = 1
b = 4
c = 1
d = 0

yvals = gaussian(a,b,c,d, xvals)
area = a * c * SQRT_2PI

p xvals
p yvals

Gnuplot.open do |gp|
  Gnuplot::Plot.new(gp) do |plot|
    plot.title ('a'..'d').to_a.zip([a,b,c,d]).map {|pair| pair.join(": ")}.join(", ") + " area: #{area}"
    plot.data << Gnuplot::DataSet.new( [xvals, yvals] ) do |ds|
      ds.notitle
    end
  end
end
