=begin
Where to start out?
Read in the mzXML file
write it out
=end

require "bundler"
require "pp"
Bundler.require(:default, :development)

$two_point_curve = 0
PerfTools::CpuProfiler.start("profile") do
  #useage centroider.rb [options] [in-file] [out-file]
  Point = Struct.new("Point", :mz, :intensity)
  Peak = Struct.new("Peak", :start, :end)

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
      if point.intensity > 0
        if !in_peak
          in_peak = true
          peaks << Peak.new(index)
        end
      elsif in_peak
        peaks.last.end = index - 1
        in_peak = false
      end
    end
    peaks
  end

  def centroid_from_single_peak(x, y)
    y_log = y.collect { |y_point| Math.log(y_point) }
    if x.length == 2
      $two_point_curve = $two_point_curve + 1
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
        centroids << centroid_from_single_peak(scan.spectrum.mzs[peak.start..peak.end], scan.spectrum.intensities[peak.start..peak.end])
      end
    end
  end
  puts "two_point_curve is #{$two_point_curve}"
end
