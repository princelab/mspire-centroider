module Mspire
  module Centroider
    class Peak
      SQROOT_2PI = Math.sqrt(2*Math::PI)

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
            before = @points[lm_i-1].last.to_f  # intensity
            after = @points[lm_i+1].last.to_f # intensity 
            sum = before + after
            # push onto the last peak all the peaks from right after the previous local min
            # to just before this local min
            new_peaks.last.push( *@points[(prev_lm_i+1)..(lm_i-1)] )
            # push onto the last peak its portion of the local min
            new_peaks.last << [ lm.first, lm.last * (before/sum) ]
            # create a new peak that contains its portion of the local min
            new_peaks << Peak.new( [ [lm.first, lm.last * (after/sum)] ] ) # an array of pts, in this case 1 pt
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

      def xpoints
        @points.map(&:first)
      end

      def ypoints
        @points.map(&:last)
      end

      def xpoints_ypoints
        x = [] ; y = []
        @points.each {|pair| x << pair.first ; y << pair.last }
        [x,y]
      end

      def regress(x,y,degree)
        x_data = x.map { |xi| (0..degree).map { |pow| (xi**pow).to_f } }

        mx = Matrix[*x_data]
        my = Matrix.column_vector(y)

        ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
      end

      # Calculate a centroid from this peak.
      # @return [Array] a centroid in the form of [mz, intensity]
      def centroid_from_single_peak
        (x, y) = xpoints_ypoints
        #log of a gaussian is a parabola, sortof
        y_log = y.map { |y_point| Math.log(y_point) }
        if x.length == 2
          #TODO: Fix this so it works for 2-point things.
          warn 'fix for 2 point things'
          [0, 0, 0]
        elsif x.length == 1
          [x[0], y[0], 0.0]
        else
          p x
          p y
          abort 'looking'
          (a, b, c) = regress(x, y_log, 2)

          # find the m/z on the parabola (will be the same)
          # derivative of ax**2 + bx + c is 2ax + b, so set to zero
          # 0 = 2ax + b -> -b = 2ax -> x = -b / 2a
          mz_center_point = -b / (2*a)

          h = Math.exp(a - (b**2 / (4 * c)))
          mu = -b / (2 * c)
          sigma = Math.sqrt(-1 / (2 * c))

          integral = h * sigma * SQROOT_2PI


          p [mz_center_point, integral]
          abort 'here'
          #sigma = (Math.sqrt(-1/(2*poly[0][0])))
          #mu = (poly[0][1] * sigma**2)
          #a = Math.exp(poly[0][2] + mu**2/(2 * sigma**2))
          #[mu, a, sigma ** 2]
          [mz_center_point, integral]
        end
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
end


=begin
should think about this kind of approach.  Is it faster? enough info? accurate enough?
http://wiki.scipy.org/Cookbook/FittingData
Fitting gaussian-shaped data does not require an optimization routine. Just calculating the moments of the distribution is enough, and this is much faster.
However this works only if the gaussian is not cut out too much, and if it is not too small.
切换行号显示
   1 from pylab import *
   2 
   3 gaussian = lambda x: 3*exp(-(30-x)**2/20.)
   4 
   5 data = gaussian(arange(100))
   6 
   7 plot(data)
   8 
   9 X = arange(data.size)
  10 x = sum(X*data)/sum(data)
  11 width = sqrt(abs(sum((X-x)**2*data)/sum(data)))
  12 
  13 max = data.max()
  14 
  15 fit = lambda t : max*exp(-(t-x)**2/(2*width**2))
  16 
  17 plot(fit(X))
  18 
  19 show()
=end


=begin
# could also consider something like this
https://github.com/SciRuby/rb-gsl/blob/master/examples/fit/gaussfit.rb

#!/usr/bin/env ruby
require("gsl")

# Create data
r = GSL::Rng.alloc("knuthran")
sigma = 1.5
x0 = 1.0
amp = 2.0
y0 = 3.0
N = 100
x = GSL::Vector.linspace(-4, 6, N)
y = y0 + amp*GSL::Ran::gaussian_pdf(x - x0, sigma) + 0.02*GSL::Ran::gaussian(r, 1.0, N)

coef, err, chi2, dof =  GSL::MultiFit::FdfSolver.fit(x, y, "gaussian")
sigma2 = Math::sqrt(coef[3])
x02 = coef[2]
amp2 = coef[1]*Math::sqrt(2*Math::PI)*sigma
y02 = coef[0]
y2 = y02 + amp2*GSL::Ran::gaussian_pdf(x - x02, sigma2)

GSL::graph(x, y, y2, "-C -g 3 -x -4 6")

printf("Expect:\n")
printf("sigma = #{sigma}, x0 = #{x0}, amp = #{amp}, y0 = #{y0}\n")
printf("Result:\n")
printf("sigma = %5.4e +/- %5.4e\n", sigma2, err[3])
printf("   x0 = %5.4e +/- %5.4e\n", x02, err[2])
printf("  amp = %5.4e +/- %5.4e\n", amp2, err[1])
printf("   y0 = %5.4e +/- %5.4e\n", y02, err[0])
=end
