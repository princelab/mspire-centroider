=begin
Where to start out?
Read in the mzXML file
write it out
=end

require "bundler"
Bundler.require(:default, :development)

$multipeaks = 0
PerfTools::CpuProfiler.start("profile") do
  #useage centroider.rb [options] [in-file] [out-file]
  Point = Struct.new("Point", :mz, :intensity)
  #Peak = Struct.new("Peak", :start, :end, :local_minima)
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

  def centroid_from_single_peak(x, y)
    y_log = y.collect { |y_point| Math.log(y_point) }
    if x.length == 2
      res = {
        :sigma2 => 0
      }
    elsif x.length == 1
      res = {
        :sigma2 => 0.0,
        :mu => x[0],
        :a => y[0]
      }
    else
      poly = GSL::Poly.fit(GSL::Vector.alloc(x), GSL::Vector.alloc(y_log), 2)
      sigma = (Math.sqrt(-1/(2*poly[0][0])))
      mu = (poly[0][1] * sigma**2)
      a = Math.exp(poly[0][2] + mu**2/(2 * sigma**2))
      res = {
        :sigma2 => sigma ** 2,
        :mu => mu,
        :a => a
      }
    end
    res
  end

  Ms::Msrun.open("sample_files/test.mzXML") do |run|
    centroids = []
    run.each(:ms_level => 1) do |scan|
      points = []
      scan.spectrum.mzs.each_with_index { |mz, index| points << Point.new(mz, scan.spectrum.intensities[index]) }
      points.sort!
      peaks = find_peaks(points)
      peaks.each do |peak|
        $multipeaks = $multipeaks + 1 if peak.multipeak?
        centroids << centroid_from_single_peak(scan.spectrum.mzs[peak.start..peak.end], scan.spectrum.intensities[peak.start..peak.end])
      end
    end
    puts "number of centroids: #{centroids.length}"
    puts "multipeaks: #{$multipeaks}"
  end
end
