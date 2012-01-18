begin
  require 'gsl'
  $HAVE_GSL = true
rescue LoadError
  $HAVE_GSL = false
end


module Centroider
  class Peak
    include Enumerable
    attr_accessor :local_minima, :points

    def initialize(points=[])
      @local_minima = []
      @points = points
    end

    alias_method :each, :points

    def multipeak?
      @local_minima.length > 0
    end

    def <<(data)
      @points << data
    end

    def push(*data)
      @points.push(*data)
    end

    # returns an array of peaks so that each peak contains no local minima.
    # If the peak has no local minima, it is returned [as the single element
    #  in the array], rather than duplicated.
    #
    #      :share_with_neighbor   share the minima based on the intensity of 
    #                             neighboring points.
    def split(methd=:share_with_neighbor)
      if self.multipeak?
        new_peaks = [Peak.new]
        lm_indices = @local_minima.map {|lm| @points.index(lm) }
        prev_lm_i = -1 
        lm_indices.each do |lm_i|
          lm = @points[lm_i]
          before = @points[lm_i-1].intensity.to_f
          after = @points[lm_i+1].intensity.to_f
          sum = before + after
          # push onto the last peak all the peaks from right after the previous local min
          # to just before this local min
          new_peaks.last.push( *@points[(prev_lm_i+1)..(lm_i-1)] )
          # push onto the last peak its portion of the local min
          new_peaks.last << Point.new( lm.mz, lm.intensity * (before/sum) )
          # create a new peak that contains its portion of the local min
          new_peaks << Peak.new( [Point.new(lm.mz, lm.intensity * (after/sum))] )
          prev_lm_i = lm_i
        end
        new_peaks.last.push( *@points[(prev_lm_i+1)...@points.size] )
        new_peaks
      else
        [self]
      end
    end

    # Return the centroid as an array of [mz, intensity]
    #
    # @return [Array] the centroid in the form of [mz, intensity]
    def centroid
      multipeak? ? centroids_from_multipeak : centroid_from_single_peak
    end

    def y
      @points.map(&:intensity)
    end

    def x
      @points.map(&:mz)
    end

    # Calculate a centroid from this peak.
    # @return [Array] a centroid in the form of [mz, intensity]
    def centroid_from_single_peak(x=self.x, y=self.y)
      abort 'require gsl gem to create centroids' unless $HAVE_GSL
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
        #@NOTE: for some reason we are getting weird complex numbers here with veeeeerrry small precision
        #Just return the real part if they are complex
        res = [mu, a, sigma].collect do |a|
          a.respond_to?(:real) ? a.real : a
          if a.respond_to?(:real)
            a.real
          else
            a
          end
        end
        res[2] = res[2] ** 2
        res
      end
      res
    end


    # Calculate centroids for multiple convolved peaks.
    #
    # @param [Hash] options a hash of options that will control behavior of the
    #     peak picking algorithm
    # @return [Array] an array of centroid peaks in the form of [[mz, intensity] . . .]
    def centroids_from_multipeak(options={})
      warn "I'M NOT SURE THIS WORKS PROPERLY...."
      #naive implementation - find each top 3 points of each max and pass it to centroid_from_single_peak
      centroids = []
      @local_minima.each_with_index do |min, index|
        #if we are at the first peak, we need to take everything from the begining to the first peak
        if index == 0
          max_x = max_index(x[0..x.index(min.mz)])
        elsif index == @local_minima.length - 1 #we are at the end, and go from the mimima to the end
          max_x = max_index x[x.index(min.mz)..-1]
        else # we are in the middle, so the peak is from the previous local_minima to the current one
          max_x = max_index x[x.index(@local_minima[index - 1].mz)..x.index(min.mz)]
        end
        #@TODO: handle case where there are only two points in the peak
        x_vals = x[max_x - 1..max_x + 1]
        #@TODO: will be nil if it is out of range
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
  end


  #TODO: should Peak centroid itself?
end
