$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))
require "rubygems" #for ruby 1.8.7
require "bundler"
Bundler.require(:default)
require "lib/centroider"
require "ms/msrun/plms1"
include Centroider

def find_peaks(scan)
  peaks = []
  in_peak = false
  scan.each_with_index do |point, index|
    previous_intensity = scan[index - 1].intensity
    if point.intensity > 0
      if !in_peak
        in_peak = true
        peaks << Peak.new(point)
      else
        peaks.last << point
        if on_upslope(previous_intensity, point.intensity)
          #If we were previously on a downslope and we are now on an upslope
          # then the previous index is a local min
          prev_previous_intensity = scan[index - 2].intensity
          if on_downslope(prev_previous_intensity, previous_intensity)
            #We have found a local min
            peaks.last.local_minima << scan[index - 1]
          end
        end
      end
    elsif in_peak
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




Ms::Msrun.open("sample_files/test.mzXML") do |run|
  spectra_times = []
  spectra_nums = []
  spectra = []
  spectra_points = []
  run.each(:ms_level => 1) do |scan|
    #save each run's centroids into an Narray of m/zs and amplitude
    spectra_times << scan.time
    spectra_nums << scan.num
    points = []
    scan.spectrum.mzs.each_with_index { |mz, index| points << Point.new(mz, scan.spectrum.intensities[index]) }
    points.sort!
    spectra_points << points
    peaks = find_peaks points
    mzs = []
    intensities = []

    peaks.each do |peak|
      #@TODO: multipeak?
      centroid = peak.centroid
      if centroid[0].class == [].class
        centroid.each do |cent|
          mzs << cent[0]
          intensities << cent[1]
        end
      else
        mzs << centroid[0]
        intensities << centroid[1]
      end
    end

    #n_mzs = NArray[mzs]
    #n_intensities = NArray[intensities]
    spectra << [mzs, intensities]
    #centroids = Ms::spectra.new [n_mzs, n_intensities]
    #get the scan number and time, and put them into a new Plms1 to write out
    #out = Ms::Msrun::Plms1.new(scan.time, scan.num, [centroids])
    #out.write "out-#{scan.num}.plms1"
    r = Rserve::Simpler.new

    centroids_to_graph = spectra[0]
    points_to_graph = spectra_points[0]
    x = points_to_graph.collect { |point| point.mz }
    y = points_to_graph.collect { |point| point.intensity }

    res = r.converse(xr: x, yr: y) do
      "plot(x=xr, y=yr, type='p', col='red')"
    end
    #TODO: print out the lines of the centroids
    #centroids_to_graph.each do |cent|
      #r.converse(
    #end
    r.pause
  end
  out = Ms::Msrun::Plms1.new(spectra_times, spectra_nums, spectra)
  out.write "out.plms1"

end
