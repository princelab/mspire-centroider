require 'optparse'
require 'mspire/mzml'

module Mspire
  module Centroider
    module Commandline
      def self.run(progname, argv)

        parser = OptionParser.new do |op|
          op.banner = "usage: #{File.basename(__FILE__)} <file>.mzML ..."
          op.separator "centroids the spectra and writes <file>.centroid.mzML"
        end
        parser.parse!(argv)

        if argv.size == 0
          puts parser
          return
        end

        argv.each do |file|
          base = file.chomp(File.extname(file))
          outfile = base + ".centroid.mzML"

          Mspire::Mzml.open(mzml_file) do |mzml|

            # MS:1000584 -> an mzML file
            mzml.file_description.source_files << Mspire::Mzml::SourceFile[mzml_file].describe!('MS:1000584')
            mspire = Mspire::Mzml::Software.new
            mzml.software_list.push(mspire).uniq_by(&:id)
            normalize_processing = Mspire::Mzml::DataProcessing.new("peak_picking") do |dp|
              # 'MS:1001484' -> intensity normalization 
              dp.processing_methods << Mspire::Mzml::ProcessingMethod.new(mspire).describe!('MS:1000035')
            end

            mzml.data_processing_list << normalize_processing

            spectra = mzml.map do |spectrum|
              if param = spectrum.param_by_accession('MS:1000128') # profile
                spectrum.cv_params.delete(param)
                spectrum.centroid!
                spectrum.describe!('MS:1000127') # centroid 
              end
            end
            mzml.run.spectrum_list = Mspire::Mzml::SpectrumList.new(normalize_processing, spectra)
            mzml.write(outfile)
          end
        end
      end
    end
  end
end
