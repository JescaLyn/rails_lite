require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'
require 'active_support/inflector'
require 'byebug'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, params = {})
    @req = req
    @res = res
    @params = req.params.merge(params)
  end

  def self.protect_from_forgery
    @@protect = true
  end

  def form_authenticity_token
    @auth_token ||= SecureRandom.urlsafe_base64(32)
    @res.set_cookie("authenticity_token", { path: "/", value: @auth_token })
    @auth_token
  end

  def check_authenticity_token
    cookie = @req.cookies["authenticity_token"] || nil
    raise "Invalid authenticity token" unless cookie && cookie == params["authenticity_token"]
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Cannot redirect and/or render twice" if @already_built_response
    @res.status = 302
    @res['Location'] = url
    session.store_session(@res)
    flash.store_flash(@res)
    @already_built_response = true
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Cannot render twice" if already_built_response?
    @res['Content-Type'] = content_type
    @res.write(content)
    session.store_session(@res)
    flash.store_flash(@res)
    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller = "#{self.class}".underscore
    path = File.expand_path("../../views/#{controller}/#{template_name}.html.erb", __FILE__)
    render_content(ERB.new(File.read(path)).result(binding), "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    if @@protect && @req.request_method != "GET"
      check_authenticity_token
    else
      form_authenticity_token
    end
    render (name) unless @already_built_response
  end

  def flash
    @flash ||= Flash.new(@req)
  end
end
