require 'sass_inline_svg/version'
require 'sass'
require 'cgi'

module Sass::Script::Functions
  def inline_svg(path, repl = nil)
    assert_type(path, :String)
    svg = read_file(path.value.strip)
    if repl && repl.respond_to?('to_h')
      repl = repl.to_h
      svg = svg.to_s
      repl.each_pair { |k, v| svg.gsub!(k.value, v.value) if svg.include? k.value }
    end
    encode(svg)
  end

  alias_method :svg_inline, :inline_svg

  declare :inline_svg, [:path, :repl]
  declare :inline_svg, [:path]

  declare :svg_inline, [:path, :repl]
  declare :svg_inline, [:path]

  private

  def encode(svg)
    encoded = CGI::escape(svg).gsub("+", "%20")
    encoded_url = "url('data:image/svg+xml;charset=utf-8," + encoded + "')"
    Sass::Script::String.new(encoded_url)
  end

  def read_file(path)
    # Use Soprockets / Rails asset pipeline if in Rails context (and handle File not found):
    if defined?(Rails)
      asset = (Rails.application.assets || ::Sprockets::Railtie.build_environment(Rails.application)).find_asset(path).to_s
      raise "File not found or cannot be read (Sprockets): #{path}" if asset.nil?

      return asset.to_s
    end
    raise Sass::SyntaxError, "File not found or cannot be read (native): #{path}" unless File.readable?(path)

    File.open(path, 'rb') { |f| f.read }.strip
  end
end
