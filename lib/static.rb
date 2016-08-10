require 'rack/mime'
require 'byebug'

class Static
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.path.include?("public/")
      reader = FileReader.new(req)
      reader.build_response
    else
      @app.call(env)
    end
  end
end

class FileReader
  def initialize(req)
    @req = req
  end

  def build_response
    file_name = file_name(@req)
    file_extension = "." + file_name.split(".").last
    content_type = { 'Content-type' => '#{Rack::Mime.mime_type(file_extension)}' }
    content = get_file(file_name)

    [@code, content_type, content]
  end

  def get_file(file_name)
    begin
      @code = '200'
      File.readlines(file_name)
    rescue
      @code = '404'
      ["File not found"]
    end
  end

  def file_name(req)
    File.expand_path(("../.." + req.path), __FILE__)
  end
end
