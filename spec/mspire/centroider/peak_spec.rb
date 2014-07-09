require 'spec_helper'

require 'gnuplot'

require 'mspire/centroider/peak'

# returns [yvals, area under the curve]
# (of course, the b parameter passed in is the center value)
def gaussian(h, mu, sigma, d, xvals)
  yvals = xvals.map do |x|
    h*Math.exp(-(x-mu)**2 / 2*sigma**2 ) + d
  end
  [yvals, h * sigma * Math.sqrt(2*Math::PI)]
end

describe Mspire::Centroider::Peak do
  describe 'centroiding a single peak' do
    describe 'a peak with a single point' do
      subject { described_class.new( [[13.0, 75]] ) }
      it 'gives an m/z with no intensity' do
        expect(subject.centroid_from_single_peak).to eq [13.0, 0]
      end
    end

    describe 'a peak with two points' do
      subject { described_class.new( [[2,8], [4,10]] ) }
      it 'calculates weighted avg m/z and trapezoid for area' do
        expect(subject.centroid_from_single_peak).to eq [3.111111111111111, 18]
      end
    end

    describe 'a peak with three or more points' do
      describe 'fitting a perfect gaussian' do
        before do
          @xvals = (0.3..8.3).step(1.0).to_a
          a = 1 # amplitude
          b = 4 # x-centering
          c = 1 # variance
          d = 0 # y-shift
          (@yvals, @area) = gaussian(a,b,c,d, @xvals)
        end
        subject { described_class.new(@xvals.zip(@yvals).to_a) }
        it 'centroids the peak' do
          (mu, sigma, h) = subject.fit_gaussian(@xvals, @yvals)

          plotxvals = (0.3..8.3).step(0.2).to_a
          (fityvals, area) = gaussian(h, mu, sigma, 0, plotxvals)

          Gnuplot.open do |gp|
            Gnuplot::Plot.new(gp) do |plot|
              plot.data << Gnuplot::DataSet.new( [@xvals, @yvals] ) do |ds|
                ds.title = "orig"
                ds.with = "linespoints"
              end
              #plot.data << Gnuplot::DataSet.new( [[x],[y]] ) do |ds|
                #ds.title = "centroid"
                #ds.with = "impulse"
              #end
              plot.data << Gnuplot::DataSet.new( [plotxvals, fityvals] ) do |ds|
                ds.title = "fit vals"
                ds.with = "linespoints"
              end

            end
          end
          expect(area).to be_within(0.0000001).of(@area)
        end
      end

      #describe 'fitting an offset gaussian' do
      #subject {
      #xvals = (1.2..8.2).step(1).to_a
      #}

    end
  end
end

