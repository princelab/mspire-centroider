module Centroider
  class Point
    attr_accessor :mz, :intensity
    include Comparable

    def initialize(mz, intensity)
      @mz = mz
      @intensity = intensity
    end

    def <=>(other)
      return @mz <=> other.mz
    end

    def to_s
      "m/z: #{@mz} intensity: #{@intensity}"
    end
  end
end
