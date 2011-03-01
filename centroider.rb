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
  run.each(:ms_level => 1) do |scan|
    #save each run's centroids into an Narray of m/zs and amplitude
    points = []
    scan.spectrum.mzs.each_with_index { |mz, index| points << Point.new(mz, scan.spectrum.intensities[index]) }
    points.sort!
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
    centroids = [mzs, intensities]
    puts centroids.inspect
    #centroids = Ms::Spectrum.new [n_mzs, n_intensities]
    #get the scan number and time, and put them into a new Plms1 to write out
    out = Ms::Msrun::Plms1.new(scan.time, scan.num, [centroids])
    out.write "out-#{scan.num}.plms1"
    #TODO: write out centroids to a file
  end
  #r = Rserve::Simpler.new
  ##X is the range of all x values
  #x_min = centroids[0].min
  #x_max = centroids[0].max
  #r.command "x <- seq(#{x_min}, #{x_max}, length.out=10000)"
  #y_min = centroids[1].min
  #y_max = centroids[1].max
  #r.command "y <- seq(#{y_min}, #{y_max}, length.out=10000)"
  #r.command "z <- #{centroids}"

  #r.converse do
  #"persp(x, y, z, theta=45, phi=25, shade=.3)"
  #end
end
