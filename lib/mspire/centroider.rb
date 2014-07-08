
module Mspire
  module Centroider

    # minima will be nil unless there is one or more minima
    PeakBoundaryData = Struct.new(:start, :stop, :minima)

    # expects an array containing parallel arrays (m/z's and intensities).
    # Expects data to be baseline corrected (i.e., zero will separate zones of
    # intensity). Returns an array of the same form as passed in.
    def self.centroid(data, opts={})
      # most fitting algorithms will want data in two arrays, x and y.  Hence,
      # we should work with data in this arrangment.  Also, assuming monotonic
      # m/z values, we can get away with only looking at the intensities
      # while splitting up the peaks.
      peaks = self.find_peaks(data[0].zip(data[1]), opts)
      centroids = peaks.flat_map(&:centroid)
      xs = [] ; ys = []
      centroids.each {|pair| xs << pair.first ; ys << pair.last }
      [xs, ys]
    end

    # returns another peak_list (same class as is passed in)
    def self.centroid_peaklist(peaklist)
      peaklist.class.new( self.find_peaks(peaklist) )
    end

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
        previous_intensity = points[index - 1].last  # intensity
        if point.last > 0  # intensity
          if !in_peak
            in_peak = true
            peaks << Mspire::Centroider::Peak.new([point])
          else
            peaks.last << point
            # if on_upslope(previous_intensity, point.intensity)
            if previous_intensity < point.last  # intensity
              #If we were previously on a downslope and we are now on an upslope
              # then the previous index is a local min
              prev_previous_intensity = points[index - 2].last # intensity
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
