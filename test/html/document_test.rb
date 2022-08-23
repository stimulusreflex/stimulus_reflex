# frozen_string_literal: true

require_relative "../test_helper"

class StimulusReflex::HTML::PartTest < ActiveSupport::TestCase
  test "should handle nil" do
    document = StimulusReflex::HTML::Document.new(nil)

    assert_equal "<html><head></head><body></body></html>", document.to_html
    assert_equal "<html><head></head><body></body></html>", document.outer_html
    assert_equal "<head></head><body></body>", document.inner_html

    assert_equal "<html><head></head><body></body></html>", document.match("html").to_html
    assert_equal "<html><head></head><body></body></html>", document.match("html").outer_html
    assert_equal "<head></head><body></body>", document.match("html").inner_html

    assert_equal "<body></body>", document.match("body").to_html
    assert_equal "<body></body>", document.match("body").outer_html
    assert_equal "", document.match("body").inner_html

    assert_nil document.match("#selector").to_html
    assert_nil document.match("#selector").outer_html
    assert_nil document.match("#selector").inner_html
  end

  test "should handle empty string" do
    document = StimulusReflex::HTML::Document.new("")

    assert_equal "<html><head></head><body></body></html>", document.to_html
    assert_equal "<html><head></head><body></body></html>", document.outer_html
    assert_equal "<head></head><body></body>", document.inner_html

    assert_equal "<html><head></head><body></body></html>", document.match("html").to_html
    assert_equal "<html><head></head><body></body></html>", document.match("html").outer_html
    assert_equal "<head></head><body></body>", document.match("html").inner_html

    assert_equal "<body></body>", document.match("body").to_html
    assert_equal "<body></body>", document.match("body").outer_html
    assert_equal "", document.match("body").inner_html

    assert_nil document.match("#selector").to_html
    assert_nil document.match("#selector").outer_html
    assert_nil document.match("#selector").inner_html
  end

  test "should extract a document of the HTML" do
    raw_html = <<-HTML
      <div id="container">
        <h1 id="title">Home#index</h1>
      </div>
    HTML

    document = StimulusReflex::HTML::Document.new(raw_html)

    inner_title = "Home#index"
    outer_title = "<h1 id=\"title\">#{inner_title}</h1>"
    inner_container = outer_title
    outer_container = "<div id=\"container\"> #{inner_container} </div>"
    inner_body = outer_container
    outer_body = "<body>#{inner_body} </body>"
    inner_html = "<head></head>#{outer_body}"
    outer_html = "<html>#{inner_html}</html>"

    assert_equal outer_html, document.to_html.squish
    assert_equal outer_html, document.outer_html.squish
    assert_equal inner_html, document.inner_html.squish

    assert_equal outer_html, document.match("html").to_html.squish
    assert_equal outer_html, document.match("html").outer_html.squish
    assert_equal inner_html, document.match("html").inner_html.squish

    assert_equal outer_body, document.match("body").to_html.squish
    assert_equal outer_body, document.match("body").outer_html.squish
    assert_equal inner_body, document.match("body").inner_html.squish

    assert_equal outer_container, document.match("#container").to_html.squish
    assert_equal outer_container, document.match("#container").outer_html.squish
    assert_equal inner_container, document.match("#container").inner_html.squish

    assert_equal outer_title, document.match("#title").to_html.squish
    assert_equal outer_title, document.match("#title").outer_html.squish
    assert_equal inner_title, document.match("#title").inner_html.squish
  end

  test "should extract body of a document" do
    raw_body = <<-HTML
      <body id="body">
        <h1>Home#index</h1>
        <p>Find me in app/views/home/index.html.erb</p>
      </body>
    HTML

    document = StimulusReflex::HTML::Document.new(raw_body)

    inner_body = "<h1>Home#index</h1> <p>Find me in app/views/home/index.html.erb</p>"
    outer_body = "<body id=\"body\"> #{inner_body} </body>"
    inner_html = "<head></head>#{outer_body}"
    outer_html = "<html>#{inner_html}</html>"

    assert_equal outer_html, document.to_html.squish
    assert_equal outer_html, document.outer_html.squish
    assert_equal inner_html, document.inner_html.squish

    assert_equal outer_html, document.match("html").to_html.squish
    assert_equal outer_html, document.match("html").outer_html.squish
    assert_equal inner_html, document.match("html").inner_html.squish

    assert_equal outer_body, document.match("body").to_html.squish
    assert_equal outer_body, document.match("body").outer_html.squish
    assert_equal inner_body, document.match("body").inner_html.squish

    assert_equal outer_body, document.match("#body").to_html.squish
    assert_equal outer_body, document.match("#body").outer_html.squish
    assert_equal inner_body, document.match("#body").inner_html.squish
  end

  test "should extract whole HTML document" do
    raw_body = <<-BODY
      <body id="body">
        <h1>Home#index</h1>
        <p>Find me in app/views/home/index.html.erb</p>
      </body>
    BODY

    raw_html = <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>StimulusReflex Test</title>
          <meta name="viewport" content="width=device-width,initial-scale=1">
          <meta name="csrf-param" content="authenticity_token" />
          <meta name="csrf-token" content="token" />
          <link rel="stylesheet" href="/assets/application.css" data-turbo-track="reload" />
          <script src="/assets/application.js" data-turbo-track="reload" defer="defer"></script>
        </head>

        #{raw_body}
      </html>
    HTML

    document = StimulusReflex::HTML::Document.new(raw_html)

    inner_p = "Find me in app/views/home/index.html.erb"
    outer_p = "<p>#{inner_p}</p>"
    inner_body = "<h1>Home#index</h1> #{outer_p}"
    outer_body = "<body id=\"body\"> #{inner_body} </body>"
    inner_html = "<head> <title>StimulusReflex Test</title> <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"> <meta name=\"csrf-param\" content=\"authenticity_token\"> <meta name=\"csrf-token\" content=\"token\"> <link rel=\"stylesheet\" href=\"/assets/application.css\" data-turbo-track=\"reload\"> <script src=\"/assets/application.js\" data-turbo-track=\"reload\" defer=\"defer\"></script> </head> #{outer_body}"
    outer_html = "<html>#{inner_html}</html>"

    assert_equal outer_html, document.to_html.squish
    assert_equal outer_html, document.outer_html.squish
    assert_equal inner_html, document.inner_html.squish

    assert_equal outer_html, document.match("html").to_html.squish
    assert_equal outer_html, document.match("html").outer_html.squish
    assert_equal inner_html, document.match("html").inner_html.squish

    assert_equal outer_body, document.match("body").to_html.squish
    assert_equal outer_body, document.match("body").outer_html.squish
    assert_equal inner_body, document.match("body").inner_html.squish

    assert_equal outer_body, document.match("#body").to_html.squish
    assert_equal outer_body, document.match("#body").outer_html.squish
    assert_equal inner_body, document.match("#body").inner_html.squish

    assert_equal outer_p, document.match("p").to_html.squish
    assert_equal outer_p, document.match("p").outer_html.squish
    assert_equal inner_p, document.match("p").inner_html.squish
  end
end
