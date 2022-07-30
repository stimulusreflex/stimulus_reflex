# frozen_string_literal: true

require_relative "../test_helper"

class StimulusReflex::HTML::DocumentTest < ActiveSupport::TestCase
  test "should handle nil" do
    document = StimulusReflex::HTML::Document.new(nil)

    assert_equal "<html><head></head><body></body></html>", document.to_html
    assert_equal "<html><head></head><body></body></html>", document.outer_html
    assert_equal "<html><head></head><body></body></html>", document.inner_html
  end

  test "should handle empty string" do
    document = StimulusReflex::HTML::Document.new("")

    assert_equal "<html><head></head><body></body></html>", document.to_html
    assert_equal "<html><head></head><body></body></html>", document.outer_html
    assert_equal "<html><head></head><body></body></html>", document.inner_html
  end

  test "should accept fragement and build whole document of HTML" do
    raw_html = <<-HTML
      <div id="container">
        <h1 id="title">Home#index</h1>
      </div>
    HTML

    document = StimulusReflex::HTML::Document.new(raw_html)

    inner_title = "Home#index"
    outer_title = "<h1 id=\"title\">Home#index</h1>"
    inner_container = outer_title
    outer_container = "<div id=\"container\"> #{inner_container} </div>"
    inner_body = outer_container
    outer_body = "<body>#{inner_body} </body>"
    whole_document = "<html><head></head>#{outer_body}</html>"

    # TODO: this should be have like outer_html
    assert_equal inner_body, document.match("body").to_html.squish
    assert_equal inner_container, document.match("#container").to_html.squish
    assert_equal inner_title, document.match("#title").to_html.squish

    assert_equal whole_document, document.to_html.squish
    assert_equal whole_document, document.inner_html.squish
    assert_equal whole_document, document.outer_html.squish

    assert_equal inner_body, document.match("body").inner_html.squish
    assert_equal outer_body, document.match("body").outer_html.squish

    assert_equal inner_container, document.match("#container").inner_html.squish
    assert_equal outer_container, document.match("#container").outer_html.squish

    assert_equal outer_title, document.match("#title").outer_html.squish
    assert_equal inner_title, document.match("#title").inner_html.squish
  end

  test "should extract body of a document" do
    raw_html = <<-HTML
      <body id="body">
        <h1>Home#index</h1>
        <p>Find me in app/views/home/index.html.erb</p>
      </body>
    HTML

    document = StimulusReflex::HTML::Document.new(raw_html)

    inner_body = "<h1>Home#index</h1> <p>Find me in app/views/home/index.html.erb</p>"
    outer_body = "<body id=\"body\"> #{inner_body} </body>"
    whole_document = "<html><head></head>#{outer_body}</html>"

    assert_equal whole_document, document.to_html.squish
    assert_equal whole_document, document.outer_html.squish
    assert_equal whole_document, document.inner_html.squish

    assert_equal outer_body, document.match("body").outer_html.squish
    assert_equal outer_body, document.match("#body").outer_html.squish

    assert_equal inner_body, document.match("#body").inner_html.squish
    assert_equal inner_body, document.match("body").inner_html.squish

    # TODO: this should behave like #outer_html
    assert_equal inner_body, document.match("body").to_html.squish
    assert_equal inner_body, document.match("#body").to_html.squish
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

    inner_body = "<h1>Home#index</h1> <p>Find me in app/views/home/index.html.erb</p>"
    outer_body = "<body id=\"body\"> #{inner_body} </body>"
    expected_html = "<!DOCTYPE html><html><head> <title>StimulusReflex Test</title> <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"> <meta name=\"csrf-param\" content=\"authenticity_token\"> <meta name=\"csrf-token\" content=\"token\"> <link rel=\"stylesheet\" href=\"/assets/application.css\" data-turbo-track=\"reload\"> <script src=\"/assets/application.js\" data-turbo-track=\"reload\" defer=\"defer\"></script> </head> #{outer_body}</html>"

    document = StimulusReflex::HTML::Document.new(raw_html)

    assert_equal expected_html, document.to_html.squish
    assert_equal expected_html, document.outer_html.squish
    assert_equal expected_html, document.inner_html.squish

    assert_equal outer_body, document.match("body").outer_html.squish
    assert_equal outer_body, document.match("#body").outer_html.squish

    assert_equal inner_body, document.match("body").inner_html.squish
    assert_equal inner_body, document.match("#body").inner_html.squish

    # TODO: change this to outer_body
    assert_equal inner_body, document.match("body").to_html.squish
    assert_equal inner_body, document.match("#body").to_html.squish
  end
end
