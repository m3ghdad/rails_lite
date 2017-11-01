require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, route_params = {})
    @req, @res = req, res
    @params = route_params.merge(req.params)

  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise 'cannot render twice' if already_built_response?
    @res['Location'] = url
    @res.status = 302
    @session.store_session(@res)

    @already_built_response = true

    # ssuing a redirect consists of two parts,
    # setting the 'Location' field of the response header to the redirect
    # url and setting the response status code to 302.
    # Do not use #redirect; set each piece of the response individually.
    # Check the Rack::Response docs for how to set response header fields and statuses. Again,
    # set @already_built_response to avoid a double render.
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    #it checks that content is not rendered twice
    raise 'cannot render twice' if already_built_response?
    #sets response object's body
    @res.write(content)
    #sets responnse object's content_type
    @res['Content-Type'] = content_type
    @session.store_session(@res)

    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    # @res.File.read
    path = File.dirname(__FILE__)
    template_path = File.join(path, "..", "views", self.class.name.underscore, "#{template_name}.html.erb")

    read_template = File.read(template_path)

    render_content(ERB.new(read_template).result(binding),'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end


  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
    nil
  end
end
