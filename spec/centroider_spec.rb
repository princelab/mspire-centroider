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
      break if @mzs.size == intensities.size
      mz += diff
    end
    @mzs.map! {|mz| mz.round(2) }
  end
end

