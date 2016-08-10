require 'erb'
require 'byebug'

class ShowExceptions
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue Exception => e
      ["500", {'Content-type' => 'text/html'}, [render_exception(e)]]
    end
  end

  private

  def render_exception(e)
    path = File.expand_path("./lib/templates/rescue.html.erb")
    error = e.backtrace.first.split(":")
    error_line_no = error[1].to_i
    error_path = File.expand_path(error[0])
    error_lines = File.readlines(error_path)
    source_code = error_lines[(error_line_no - 3)..(error_line_no + 2)]

    ERB.new(File.read(path)).result(binding)
  end
end
