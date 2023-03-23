# frozen_string_literal: true

require_relative "../test_helper"

class StimulusReflex::HTML::DocumentFragmentTest < ActiveSupport::TestCase
  test "should handle nil" do
    fragment = StimulusReflex::HTML::DocumentFragment.new(nil)

    assert_equal "", fragment.to_html
    assert_equal "", fragment.outer_html
    assert_equal "", fragment.inner_html

    assert_nil fragment.match("html").to_html
    assert_nil fragment.match("html").outer_html
    assert_nil fragment.match("html").inner_html

    assert_nil fragment.match("body").to_html
    assert_nil fragment.match("body").outer_html
    assert_nil fragment.match("body").inner_html
  end

  test "should handle empty string" do
    fragment = StimulusReflex::HTML::DocumentFragment.new("")

    assert_equal "", fragment.to_html
    assert_equal "", fragment.outer_html
    assert_equal "", fragment.inner_html

    assert_nil fragment.match("html").to_html
    assert_nil fragment.match("html").outer_html
    assert_nil fragment.match("html").inner_html

    assert_nil fragment.match("body").to_html
    assert_nil fragment.match("body").outer_html
    assert_nil fragment.match("body").inner_html
  end

  test "should extract a fragment of the HTML" do
    raw_html = <<-HTML
      <div id="container">
        <h1 id="title">Home#index</h1>
      </div>
    HTML

    fragment = StimulusReflex::HTML::DocumentFragment.new(raw_html)

    inner_title = "Home#index"
    outer_title = "<h1 id=\"title\">#{inner_title}</h1>"
    inner_container = outer_title
    outer_container = "<div id=\"container\"> #{inner_container} </div>"

    assert_equal raw_html.squish, fragment.to_html.squish
    assert_equal outer_title.squish, fragment.inner_html.squish
    assert_equal raw_html.squish, fragment.outer_html.squish

    refute fragment.match("body").present?
    assert_nil fragment.match("body").to_html

    assert_equal outer_container, fragment.match("#container").to_html.squish
    assert_equal outer_container, fragment.match("#container").outer_html.squish
    assert_equal inner_container, fragment.match("#container").inner_html.squish

    assert_equal outer_title, fragment.match("#title").to_html.squish
    assert_equal outer_title, fragment.match("#title").outer_html.squish
    assert_equal inner_title, fragment.match("#title").inner_html.squish
  end

  test "should extract body of a fragment" do
    raw_body = <<-HTML
      <body id="body">
        <h1>Home#index</h1>
        <p>Find me in app/views/home/index.html.erb</p>
      </body>
    HTML

    fragment = StimulusReflex::HTML::DocumentFragment.new(raw_body)

    inner_body = "<h1>Home#index</h1> <p>Find me in app/views/home/index.html.erb</p>"
    outer_body = "<body id=\"body\"> #{inner_body} </body>"

    assert_equal outer_body, fragment.to_html.squish
    assert_equal inner_body, fragment.inner_html.squish
    assert_equal outer_body, fragment.outer_html.squish

    assert_equal outer_body, fragment.match("body").to_html.squish
    assert_equal outer_body, fragment.match("body").outer_html.squish
    assert_equal inner_body, fragment.match("body").inner_html.squish

    assert_equal outer_body, fragment.match("#body").to_html.squish
    assert_equal outer_body, fragment.match("#body").outer_html.squish
    assert_equal inner_body, fragment.match("#body").inner_html.squish
  end

  test "should extract whole HTML fragment" do
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

    fragment = StimulusReflex::HTML::DocumentFragment.new(raw_html)

    inner_p = "Find me in app/views/home/index.html.erb"
    outer_p = "<p>#{inner_p}</p>"
    inner_body = "<h1>Home#index</h1> #{outer_p}"
    outer_body = "<body id=\"body\"> #{inner_body} </body>"
    inner_html = "<head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"> <title>StimulusReflex Test</title> <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"> <meta name=\"csrf-param\" content=\"authenticity_token\"> <meta name=\"csrf-token\" content=\"token\"> <link rel=\"stylesheet\" href=\"/assets/application.css\" data-turbo-track=\"reload\"> <script src=\"/assets/application.js\" data-turbo-track=\"reload\" defer></script> </head> #{outer_body}"
    outer_html = "<html> #{inner_html} </html>"

    assert_equal outer_html, fragment.to_html.squish
    assert_equal outer_html, fragment.outer_html.squish
    assert_equal inner_html, fragment.inner_html.squish

    assert_equal outer_html, fragment.match("html").to_html.squish
    assert_equal outer_html, fragment.match("html").outer_html.squish
    assert_equal inner_html, fragment.match("html").inner_html.squish

    assert_equal outer_body, fragment.match("body").to_html.squish
    assert_equal outer_body, fragment.match("body").outer_html.squish
    assert_equal inner_body, fragment.match("body").inner_html.squish

    assert_equal outer_body, fragment.match("#body").to_html.squish
    assert_equal outer_body, fragment.match("#body").outer_html.squish
    assert_equal inner_body, fragment.match("#body").inner_html.squish

    assert_equal outer_p, fragment.match("p").to_html.squish
    assert_equal outer_p, fragment.match("p").outer_html.squish
    assert_equal inner_p, fragment.match("p").inner_html.squish
  end

  test "should properly handle a tr without the parent table" do
    html = "<tr><td>1</td><td>2</td></tr>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal html, fragment.to_html.squish
  end

  test "should properly handle a td without the parent table or td" do
    html = "<td>1</td>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal html, fragment.to_html.squish
  end

  test "should properly parse <tr>" do
    html = '<tr data-foo="1" id="123" class="abc"><td>1</td><td>2</td></tr>'
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal '<tr data-foo="1" id="123" class="abc"><td>1</td><td>2</td></tr>', fragment.to_html.squish
    assert_equal '<tr data-foo="1" id="123" class="abc"><td>1</td><td>2</td></tr>', fragment.outer_html.squish
    assert_equal "<td>1</td><td>2</td>", fragment.inner_html.squish
  end

  test "should properly parse <td>" do
    html = "<td>1</td>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<td>1</td>", fragment.to_html.squish
    assert_equal "<td>1</td>", fragment.outer_html.squish
    assert_equal "1", fragment.inner_html.squish
  end

  test "should properly parse <th>" do
    html = "<th>1</th>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<th>1</th>", fragment.to_html.squish
    assert_equal "<th>1</th>", fragment.outer_html.squish
    assert_equal "1", fragment.inner_html.squish
  end

  test "should properly parse <thead>" do
    html = "<thead><tr><th>1</th><th>2</th></tr></thead>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<thead><tr><th>1</th><th>2</th></tr></thead>", fragment.to_html.squish
    assert_equal "<thead><tr><th>1</th><th>2</th></tr></thead>", fragment.outer_html.squish
    assert_equal "<tr><th>1</th><th>2</th></tr>", fragment.inner_html.squish
  end

  test "should properly parse <tbody>" do
    html = "<tbody><tr><th>1</th><th>2</th></tr></tbody>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<tbody><tr><th>1</th><th>2</th></tr></tbody>", fragment.to_html.squish
    assert_equal "<tbody><tr><th>1</th><th>2</th></tr></tbody>", fragment.outer_html.squish
    assert_equal "<tr><th>1</th><th>2</th></tr>", fragment.inner_html.squish
  end

  test "should properly parse <tfoot>" do
    html = "<tfoot><tr><th>1</th><th>2</th></tr></tfoot>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<tfoot><tr><th>1</th><th>2</th></tr></tfoot>", fragment.to_html.squish
    assert_equal "<tfoot><tr><th>1</th><th>2</th></tr></tfoot>", fragment.outer_html.squish
    assert_equal "<tr><th>1</th><th>2</th></tr>", fragment.inner_html.squish
  end

  test "should properly parse <ul>" do
    html = "<ul><li>1</li></ul>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<ul><li>1</li></ul>", fragment.to_html.squish
    assert_equal "<ul><li>1</li></ul>", fragment.outer_html.squish
    assert_equal "<li>1</li>", fragment.inner_html.squish
  end

  test "should properly parse <li>" do
    html = "<li>1</li>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<li>1</li>", fragment.to_html.squish
    assert_equal "<li>1</li>", fragment.outer_html.squish
    assert_equal "1", fragment.inner_html.squish
  end
end
