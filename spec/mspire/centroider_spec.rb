require 'spec_helper'

require 'gnuplot'

require 'mspire/centroider'

def make_mzs(number, start=50, diff=0.01)

end

describe Mspire::Centroider do

  before do
    simple = [ 0, 3, 8, 9, 7, 2, 0 ]
    multi_large1 = [ 0, 3, 8, 2, 9, 7, 1, 3, 0 ]
    multi_large2 = [ 0, 10, 8, 2, 9, 7, 1, 3, 0 ]
    doublet = [ 0, 10, 8, 0 ]

    start_mz = 50
    @intensities = simple + multi_large1 + multi_large2 + doublet
    @mzs = []
    mz = start_mz
    diff = 0.01
    loop do
      @mzs << mz
      break if @mzs.size == @intensities.size
      mz += diff
    end
    @mzs.map! {|mz| mz.round(2) }
    @points = @mzs.zip(@intensities).to_a
  end

  it 'finds zero-baselined peaks based on a series of points' do
    # will find peaks, and some will be multipeak
    peaks = Mspire::Centroider.find_peaks(@points)
    peaks.size.should == 4
    peaks.map(&:multipeak?).should == [false, true, true, false]
  end

  it 'finds and splits up multipeaks' do
    peaks = Mspire::Centroider.find_peaks(@points, :split => :neighbors)
    peaks.size.should == 8
    #peaks[1,3].map(&:last)
    peaks.any?(&:multipeak?).should be_false
    peaks.any?(&:multipeak?).should be_false
  end

  it 'centroids spectra' do
    centroided_data = Mspire::Centroider.centroid([@mzs, @intensities])
    p centroided_data
    abort 'finished!'

    plot = false
    if plot
      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          plot.xlabel "m/z"
          plot.ylabel "intensity"
          plot.data << Gnuplot::DataSet.new([@mzs, @intensities]) do |ds|
            ds.title = "profile"
            ds.with = "linespoints"
          end
        end
      end
    end

  end
end
