require "mspire/centroider/peak"
require "mspire/centroider/point"

module Mspire
  module Centroider
    # takes an array of Centroider::Points
    # returns an array of Centroider::Peak objects
    # returns as a "peak" any series of points above 0 intensity.
    # zero intensity points are important to suggest when a peak is finished.
    #
    #  valid opts:
    # 
    #      :split => nil | :neighbors    Can split multipeaks if given a method
    #
    def self.find_peaks(points, opts={})
      peaks = []
      in_peak = false
      points.each_with_index do |point, index|
        previous_intensity = points[index - 1].intensity
        if point.intensity > 0
          if !in_peak
            in_peak = true
            peaks << Peak.new([point])
          else
            peaks.last << point
            # if on_upslope(previous_intensity, point.intensity)
            if previous_intensity < point.intensity
              #If we were previously on a downslope and we are now on an upslope
              # then the previous index is a local min
              prev_previous_intensity = points[index - 2].intensity
              # on_downslope(prev_previous_intensity, previous_intensity)
              if prev_previous_intensity > previous_intensity
                #We have found a local min
                peaks.last.local_minima << points[index - 1]
              end
            end
          end
        elsif in_peak
          in_peak = false
        end
      end
      if mthd = opts.delete(:split)
        splitted_peaks = []
        peaks.each do |peak|
          splitted_peaks.push *peak.split(mthd)
        end
        splitted_peaks
      else
        peaks
      end
    end
  end
end
