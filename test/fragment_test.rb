# frozen_string_literal: true

require_relative "test_helper"

class StimulusReflex::FragmentTest < ActiveSupport::TestCase
  test "should extract part of HTML" do
    raw_html = <<-HTML
      <div id="body">
        <h1 id="title">Home#index</h1>
      </div>
    HTML

    fragment = StimulusReflex::Fragment.new(raw_html)

    assert_equal fragment.match("#title").to_html.squish, "Home#index"
  end

  test "should extract top-level element of fragement" do
    raw_html = <<-HTML
      <div id="container">
        <h1 id="title">Home#index</h1>
      </div>
    HTML

    fragment = StimulusReflex::Fragment.new(raw_html)

    assert_equal fragment.to_html.squish, raw_html.squish
    assert_equal fragment.match("#container").to_html.squish, '<h1 id="title">Home#index</h1>'
  end

  test "should extract body of a fragment" do
    raw_html = <<-HTML
      <body id="body">
        <h1>Home#index</h1>
        <p>Find me in app/views/home/index.html.erb</p>
      </body>
    HTML

    fragment = StimulusReflex::Fragment.new(raw_html)

    assert_equal fragment.to_html.squish, raw_html.squish
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

    fragment = StimulusReflex::Fragment.new(raw_html)

    assert_equal fragment.match("body").to_html.squish, raw_body.squish
    assert_equal fragment.match("#body").to_html.squish, raw_body.squish
    assert_equal fragment.to_html.squish, raw_html.squish
  end
end
