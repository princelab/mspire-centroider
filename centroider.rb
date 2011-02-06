=begin
Where to start out?
Read in the mzXML file
write it out
=end

require "bundler"
Bundler.require(:default, :development)
require "pp"

#useage centroider.rb [options] [in-file] [out-file]
Point = Struct.new("Point", :mz, :intensity)

class Point
  include Comparable
  def <=>(other)
    return nil unless other.respond_to?(<=>)

    return mz <=> other.mz
  end

  def to_s
    "m/z: #{mz} intensity: #{intensity}"
  end
end

Ms::Msrun.open("sample_files/Hek_cells_100904050914.mzXML") do |run|
  run.each(:ms_level => 1) do |scan|
    points = []
    scan.spectrum.mzs.each_with_index do |mz, index|
      points << Point.new(mz, scan.spectrum.intensities[index])
    end
    points.sort!
    peaks = find_peaks points
  end
end


def find_peaks(scan)
  peaks = []
  points.each_with_index do |point, index|
    if point.intensity > 0
      if !in_peak
        in_peak = true
        peaks << Peak.new(index)
      end
    else if in_peak
      peaks.last.end = index - 1
      in_peak = false
    end
  end
  peaks
end
