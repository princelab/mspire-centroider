$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))
require "rubygems" #for ruby 1.8.7
require "bundler"
Bundler.require(:default)
require "lib/centroider"
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
            #peaks.last.local_minima << index - 1
            peaks.last.local_minima << scan[index - 1]
          end
        end
      end
    elsif in_peak
      #peaks.last.end = index - 1
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
    centroids_spectrum = Ms::Spectrum.new([NArray[], NArray[]])
    points = []
    scan.spectrum.mzs.each_with_index { |mz, index| points << Point.new(mz, scan.spectrum.intensities[index]) }
    points.sort!
    peaks = find_peaks(points)
    #peaks.each do |peak|
      #if peak.multipeak?
        ##some ugliness required to make the local_minima indicies match up with the x and y indicies
        #centroids_from_multipeak(scan.spectrum.mzs[peak.start..peak.end],
                                 #scan.spectrum.intensities[peak.start..peak.end],
                                 #peak.local_minima.collect { |min| min - peak.start } ).each {
          #|p|
        #centroids[0] << p[0];
        #centroids[1] << p[1];
        #centroids[2] << scan.time
        #}
      #else
        #res = centroid_from_single_peak(scan.spectrum.mzs[peak.start..peak.end],
                                        #scan.spectrum.intensities[peak.start..peak.end])
        #centroids[0] << res[0]
        #centroids[1] << res[1]
        #centroids[2] << scan.time
        #centroids << centroid_from_single_peak(scan.spectrum.mzs[peak.start..peak.end],
        #scan.spectrum.intensities[peak.start..peak.end]) + [run.time]
      #end
    #end
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
