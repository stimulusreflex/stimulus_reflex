# frozen_string_literal: true

require_relative "../test_helper"

class StimulusReflex::HTML::FragmentTest < ActiveSupport::TestCase
  test "should handle nil" do
    fragment = StimulusReflex::HTML::Fragment.new(nil)

    assert_equal "", fragment.to_html
    assert_equal "", fragment.outer_html
    assert_equal "", fragment.inner_html
  end

  test "should handle empty string" do
    fragment = StimulusReflex::HTML::Fragment.new("")

    assert_equal "", fragment.to_html
    assert_equal "", fragment.outer_html
    assert_equal "", fragment.inner_html
  end

  test "should extract a fragment of the HTML" do
    raw_html = <<-HTML
      <div id="container">
        <h1 id="title">Home#index</h1>
      </div>
    HTML

    fragment = StimulusReflex::HTML::Fragment.new(raw_html)

    inner_title = "Home#index"
    outer_title = "<h1 id=\"title\">#{inner_title}</h1>"

    assert_equal raw_html.squish, fragment.to_html.squish
    assert_equal raw_html.squish, fragment.inner_html.squish
    assert_equal raw_html.squish, fragment.outer_html.squish

    refute fragment.match("body").present?
    assert_nil fragment.match("body").to_html

    assert_equal raw_html.squish, fragment.match("#container").to_html.squish
    assert_equal outer_title, fragment.match("#title").to_html.squish
  end

  test "should extract body of a fragment" do
    raw_body = <<-HTML
      <body id="body">
        <h1>Home#index</h1>
        <p>Find me in app/views/home/index.html.erb</p>
      </body>
    HTML

    fragment = StimulusReflex::HTML::Fragment.new(raw_body)

    inner_body = "<h1>Home#index</h1> <p>Find me in app/views/home/index.html.erb</p>"
    outer_body = "<body> #{inner_body} </body>"

    assert_equal outer_body, fragment.to_html.squish
    assert_equal outer_body, fragment.inner_html.squish
    assert_equal outer_body, fragment.outer_html.squish

    assert_equal outer_body, fragment.match("body").to_html.squish
    assert_equal outer_body, fragment.match("body").outer_html.squish
    assert_equal inner_body, fragment.match("body").inner_html.squish

    # Nokogiri fragment's ignore the body, head and html tag if passed into them. That's why this is expected to be nil
    # if the body, head or HTML tags matter you should use `StimulusReflex::HTML::Document` instead
    refute fragment.match("#body").present?
    assert_nil fragment.match("#body").outer_html
    assert_nil fragment.match("#body").to_html
    assert_nil fragment.match("#body").inner_html
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

    fragment = StimulusReflex::HTML::Fragment.new(raw_html)

    # Nokogiri fragments strip out the body, head and html tag and just stuff every other tag into the body the as well, even if they don't belong there
    # This is super unexpected, but that's the way Nokogiri fragements work
    inner_body = "<title>StimulusReflex Test</title> <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"> <meta name=\"csrf-param\" content=\"authenticity_token\"> <meta name=\"csrf-token\" content=\"token\"> <link rel=\"stylesheet\" href=\"/assets/application.css\" data-turbo-track=\"reload\"> <script src=\"/assets/application.js\" data-turbo-track=\"reload\" defer></script> <h1>Home#index</h1> <p>Find me in app/views/home/index.html.erb</p>"
    outer_body = "<body> #{inner_body} </body>"

    assert_equal outer_body, fragment.to_html.squish
    assert_equal outer_body, fragment.outer_html.squish
    assert_equal outer_body, fragment.inner_html.squish

    assert_equal outer_body, fragment.match("body").to_html.squish
    assert_equal outer_body, fragment.match("body").outer_html.squish
    assert_equal inner_body, fragment.match("body").inner_html.squish

    refute fragment.match("#body").present?
    assert_nil fragment.match("#body").to_html
  end
end
