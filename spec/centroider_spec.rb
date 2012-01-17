require 'spec_helper'

require 'centroider'

describe Centroider do
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
    @points = @mzs.zip(@intensities).map {|pair| Centroider::Point.new *pair }
  end

  it 'finds peaks based on a series of points' do
    # will find peaks, and some will be multipeak
    peaks = Centroider.find_peaks(@points)
    peaks.size.should == 4
    peaks.map(&:multipeak?).should == [false, true, true, false]
    peaks = Centroider.find_peaks(@points, :split => :neighbors)
    peaks.size.should == 8
    peaks.any?(&:multipeak?).should be_false
    peaks.any?(&:multipeak?).should be_false
  end

end

