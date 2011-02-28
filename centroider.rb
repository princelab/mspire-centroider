require "rubygems" #for ruby 1.8.7
require "bundler"
Bundler.require(:default)

Point = Struct.new("Point", :mz, :intensity)
class Peak
  attr_accessor :local_minima, :start, :end
  def initialize(start)
    @local_minima = []
    @start = start
  end

  def multipeak?
    @local_minima.length > 0
  end
end

class Point
  include Comparable
  def <=>(other)
    return mz <=> other.mz
  end

  def to_s
    "m/z: #{mz} intensity: #{intensity}"
  end
end

def find_peaks(scan)
  peaks = []
  in_peak = false
  scan.each_with_index do |point, index|
    previous_intensity = scan[index - 1].intensity
    if point.intensity > 0
      if !in_peak
        in_peak = true
        peaks << Peak.new(index)
      else
        if on_upslope(previous_intensity, point.intensity)
          #If we were previously on a downslope and we are now on an upslope
          # then the previous index is a local min
          prev_previous_intensity = scan[index - 2].intensity
          if on_downslope(prev_previous_intensity, previous_intensity)
            #We have found a local min
            peaks.last.local_minima << index - 1
          end
        end
      end
    elsif in_peak
      peaks.last.end = index - 1
      in_peak = false
    end
  end
  peaks
end

def on_downslope(previous_intensity, current_intensity)
  previous_intensity > current_intensity
end

def on_upslope(previous_intensity, current_intensity)
  previous_intensity < current_intensity
end

# Calculate a centroid from an array of x and y values
# representing a single peak.
#
# @param [Array] x an array of x values for the peak
# @param [Array] y an array of y values for the peak
# @return [Array] a centroid in the form of [x, y, variance]
def centroid_from_single_peak(x, y)
  #ap x
  #ap y
  #log of a gaussian is a parabola, sortof
  y_log = y.collect { |y_point| Math.log(y_point) }
  if x.length == 2
    #TODO: Fix this so it works for 2-point things.
    res = [0, 0, 0]
  elsif x.length == 1
    res = [x[0], y[0], 0.0]
  else
    poly = GSL::Poly.fit(GSL::Vector.alloc(x), GSL::Vector.alloc(y_log), 2)
    sigma = (Math.sqrt(-1/(2*poly[0][0])))
    mu = (poly[0][1] * sigma**2)
    a = Math.exp(poly[0][2] + mu**2/(2 * sigma**2))
    #TODO: for some reason we are getting weird complex numbers here with veeeeerrry small precision
    #Just return the real part if they are complex
    res = [mu, a, sigma].collect { |a|
      if a.respond_to?(:real)
        a.real
      else
        a
      end
    }
    res[2] = res[2] ** 2
    res
  end
  res
end

# Calculate centroids for multiple convolved peaks.
#
# @param [Array] x an array of x values for the multipeak
# @param [Array] y an array of y values for the multipeak
# @param [Array] local_minima an array of local minima in the multipeak for identifying the individual peaks
# @param [Hash] options a hash of options that will control behavior of the
#     peak picking algorithm
# @return [Array] an array of centroid peaks
def centroids_from_multipeak(x, y, local_minima, options={})
  #naive implementation - find each top 3 points of each max and pass it to centroid_from_single_peak
  centroids = []
  local_minima.each_with_index do |min, index|
    #if we are at the first peak, we need to take everything from the begining to the first peak
    if index == 0
      max_x = max_index(x[0..min])
    elsif index == local_minima.length - 1 #we are at the end, and go from the mimima to the end
      max_x = max_index x[min..-1]
    else # we are in the middle, so the peak is from the previous local_minima to the current one
      max_x = max_index x[local_minima[index - 1]..min]
    end
    #TODO: handle case where there are only two points in the peak
    x_vals = x[max_x - 1..max_x + 1]
    #TODO: will be nil if it is out of range
    y_vals = y[max_x - 1..max_x + 1]
    centroids << centroid_from_single_peak(x_vals, y_vals)
  end
  centroids
end

# Calculate the index of the maximum value of the array
# @param [Array] arr an array of values
# @return [Integer] the index in arr of the largest element in arr
def max_index(arr)
  index = arr.index(arr.max)
  raise ArgumentException, "Could not find max index" if index.nil?
  index
end

Ms::Msrun.open("sample_files/test.mzXML") do |run|
  centroids = Array.new(3)
  centroids[0] = []
  centroids[1] = []
  centroids[2] = []
  run.each(:ms_level => 1) do |scan|
    #save each run's centroids into an Narray of m/zs and amplitude
    centroids_spec = MS::Spectrum.new([NArray[], NArray[]])
    points = []
    scan.spectrum.mzs.each_with_index { |mz, index| points << Point.new(mz, scan.spectrum.intensities[index]) }
    points.sort!
    peaks = find_peaks(points)
    peaks.each do |peak|
      if peak.multipeak?
        #some ugliness required to make the local_minima indicies match up with the x and y indicies
        centroids_from_multipeak(scan.spectrum.mzs[peak.start..peak.end],
                                 scan.spectrum.intensities[peak.start..peak.end],
                                 peak.local_minima.collect { |min| min - peak.start } ).each {
          |p|
          centroids[0] << p[0];
          centroids[1] << p[1];
          centroids[2] << scan.time
        }
      else
        res = centroid_from_single_peak(scan.spectrum.mzs[peak.start..peak.end],
                                               scan.spectrum.intensities[peak.start..peak.end])
        centroids[0] << res[0]
        centroids[1] << res[1]
        centroids[2] << scan.time
        #centroids << centroid_from_single_peak(scan.spectrum.mzs[peak.start..peak.end],
                                               #scan.spectrum.intensities[peak.start..peak.end]) + [run.time]
      end
    end
  end
  r = Rserve::Simpler.new
  #X is the range of all x values
  x_min = centroids[0].min
  x_max = centroids[0].max
  r.command "x <- seq(#{x_min}, #{x_max}, length.out=10000)"
  y_min = centroids[1].min
  y_max = centroids[1].max
  r.command "y <- seq(#{y_min}, #{y_max}, length.out=10000)"
  r.command "z <- #{centroids}"

  #r.converse do
    #"persp(x, y, z, theta=45, phi=25, shade=.3)"
  #end
end
