module Centroider
  class Peak
    attr_accessor :local_minima, :points
    def initialize(point)
      @local_minima = []
      @points = [point]
    end

    def multipeak?
      @local_minima.length > 0
    end

    def <<(data)
      @points << data
    end

    # Return the centroid as an array of [mz, intensity]
    #
    # @return [Array] the centroid in the form of [mz, intensity]
    def centroid
      multipeak? ? centroids_from_multipeak : centroid_from_single_peak
    end


    # Calculate a centroid from this peak.
    #
    # @return [Array] a centroid in the form of [mz, intensity]
    def centroid_from_single_peak(x=self.x, y=self.y)
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

  def y
    @points.collect do |point|
      point.intensity
    end
  end

  def x
    @points.collect do |point|
      point.mz
    end
  end

  #TODO: should Peak centroid itself?
end
