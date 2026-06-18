module Paperclip
  class ToImage < Processor
    def initialize(file, options = {}, attachment = nil)
      super
      @format              = options[:format] || 'png'
      @current_format      = File.extname(@file.path)
      @basename            = File.basename(@file.path, @current_format)
      @whiny               = options.fetch(:whiny, true)
    end

    def make
      src = @file
      filename = [@basename, @format ? ".#{@format}" : ""].join
      dst = TempfileFactory.new.generate(filename)

      begin
        success = convert(':src :dst',
              src: File.expand_path(src.path),
              dst: File.expand_path(dst.path))
      rescue Cocaine::ExitStatusError => e
        raise Paperclip::Error, "There was an error processing the image from PDF for #{@basename} #{e.inspect}!" if @whiny
      rescue Cocaine::CommandNotFoundError => e
        raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `convert` command. Please install ImageMagick.")
      end

      dst
    end
  end
end
