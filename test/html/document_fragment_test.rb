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

  test "should handle string" do
    fragment = StimulusReflex::HTML::DocumentFragment.new("Some String")

    assert_equal "Some String", fragment.to_html
    assert_equal "Some String", fragment.outer_html
    assert_equal "Some String", fragment.inner_html

    assert_nil fragment.match("html").to_html
    assert_nil fragment.match("html").outer_html
    assert_nil fragment.match("html").inner_html

    assert_nil fragment.match("body").to_html
    assert_nil fragment.match("body").outer_html
    assert_nil fragment.match("body").inner_html
  end

  test "should handle number" do
    fragment = StimulusReflex::HTML::DocumentFragment.new(123)

    assert_equal "123", fragment.to_html
    assert_equal "123", fragment.outer_html
    assert_equal "123", fragment.inner_html

    assert_nil fragment.match("html").to_html
    assert_nil fragment.match("html").outer_html
    assert_nil fragment.match("html").inner_html

    assert_nil fragment.match("body").to_html
    assert_nil fragment.match("body").outer_html
    assert_nil fragment.match("body").inner_html
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
    html = %(<tr data-foo="1" id="123" class="abc"><td>1</td><td>2</td></tr>)
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<tr data-foo="1" id="123" class="abc"><td>1</td><td>2</td></tr>), fragment.to_html.squish
    assert_equal %(<tr data-foo="1" id="123" class="abc"><td>1</td><td>2</td></tr>), fragment.outer_html.squish
    assert_equal %(<td>1</td><td>2</td>), fragment.inner_html.squish
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

  test "should properly parse <table>" do
    html = "<table></table>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<table></table>", fragment.to_html.squish
    assert_equal "<table></table>", fragment.outer_html.squish
  end

  test "should properly parse <table> with <caption>" do
    html = "<table><caption>Caption</caption></table>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<table><caption>Caption</caption></table>", fragment.to_html.squish
    assert_equal "<table><caption>Caption</caption></table>", fragment.outer_html.squish
  end

  test "should properly parse <table> with <thead> and <tbody>" do
    html = "<table><thead></thead><tbody></tbody></table>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<table><thead></thead><tbody></tbody></table>", fragment.to_html.squish
    assert_equal "<table><thead></thead><tbody></tbody></table>", fragment.outer_html.squish
  end

  test "should properly parse <table> with <thead> and <tbody> and <tr>s" do
    html = "<table><thead><tr><th>1</th></tr></thead><tbody><tr><td>1</td></tr></tbody></table>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<table><thead><tr><th>1</th></tr></thead><tbody><tr><td>1</td></tr></tbody></table>", fragment.to_html.squish
    assert_equal "<table><thead><tr><th>1</th></tr></thead><tbody><tr><td>1</td></tr></tbody></table>", fragment.outer_html.squish
  end

  test "should properly parse <thead> and <tbody> with <tr>" do
    html = "<thead><tr><th>1</th></tr></thead><tbody><tr><td>1</td></tr></tbody>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<thead><tr><th>1</th></tr></thead><tbody><tr><td>1</td></tr></tbody>", fragment.to_html.squish
    assert_equal "<thead><tr><th>1</th></tr></thead><tbody><tr><td>1</td></tr></tbody>", fragment.outer_html.squish
  end

  test "should properly parse <table> with <th>" do
    html = "<table><tr><th>1</th><th>2</th></tr></table>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<table><tbody><tr><th>1</th><th>2</th></tr></tbody></table>", fragment.to_html.squish
    assert_equal "<table><tbody><tr><th>1</th><th>2</th></tr></tbody></table>", fragment.outer_html.squish
  end

  test "should properly parse <table> with <tr>" do
    html = "<table><tr><td>1</td><td>2</td></tr></table>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<table><tbody><tr><td>1</td><td>2</td></tr></tbody></table>", fragment.to_html.squish
    assert_equal "<table><tbody><tr><td>1</td><td>2</td></tr></tbody></table>", fragment.outer_html.squish
  end

  test "should properly parse <thead>" do
    html = "<thead><tr><th>1</th><th>2</th></tr></thead>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<thead><tr><th>1</th><th>2</th></tr></thead>", fragment.to_html.squish
    assert_equal "<thead><tr><th>1</th><th>2</th></tr></thead>", fragment.outer_html.squish
  end

  test "should properly parse <tbody>" do
    html = "<tbody><tr><th>1</th><th>2</th></tr></tbody>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<tbody><tr><th>1</th><th>2</th></tr></tbody>", fragment.to_html.squish
    assert_equal "<tbody><tr><th>1</th><th>2</th></tr></tbody>", fragment.outer_html.squish
  end

  test "should properly parse <tfoot>" do
    html = "<tfoot><tr><th>1</th><th>2</th></tr></tfoot>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<tfoot><tr><th>1</th><th>2</th></tr></tfoot>", fragment.to_html.squish
    assert_equal "<tfoot><tr><th>1</th><th>2</th></tr></tfoot>", fragment.outer_html.squish
  end

  test "should properly parse <caption>" do
    html = "<caption>Caption</caption>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<caption>Caption</caption>", fragment.to_html.squish
    assert_equal "<caption>Caption</caption>", fragment.outer_html.squish
  end

  test "should properly parse <colgroup> and <col>" do
    html = %(
      <colgroup>
        <col />
        <col span="1" class="one">
        <col span="2" class="two" />
      </colgroup>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<colgroup> <col> <col span="1" class="one"> <col span="2" class="two"> </colgroup>), fragment.to_html.squish
    assert_equal %(<colgroup> <col> <col span="1" class="one"> <col span="2" class="two"> </colgroup>), fragment.outer_html.squish
  end

  test "should properly parse <col>" do
    html = %(
      <col span="1" class="one">
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<col span="1" class="one">), fragment.to_html.squish
    assert_equal %(<col span="1" class="one">), fragment.outer_html.squish
  end

  test "should properly parse <ul>" do
    html = "<ul><li>1</li></ul>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<ul><li>1</li></ul>", fragment.to_html.squish
    assert_equal "<ul><li>1</li></ul>", fragment.outer_html.squish
  end

  test "should properly parse <li>" do
    html = "<li>1</li>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<li>1</li>", fragment.to_html.squish
    assert_equal "<li>1</li>", fragment.outer_html.squish
  end

  test "should properly parse two siblings input" do
    html = %(
      <div>
        <div id="label-container">
          <label>
            <input type="file" accept="image/*">
            <input type="hidden" value="">
          </label>
        </div>
        <div id="after-label"></div>
      </div>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<div> <div id="label-container"> <label> <input type="file" accept="image/*"> <input type="hidden" value=""> </label> </div> <div id="after-label"></div> </div>), fragment.to_html.squish
    assert_equal %(<div> <div id="label-container"> <label> <input type="file" accept="image/*"> <input type="hidden" value=""> </label> </div> <div id="after-label"></div> </div>), fragment.outer_html.squish
  end

  test "should properly parse <span> after non-closed <input>" do
    html = %(
      <div>
        <label>X</label>
        <div>
          <input type="text">
          <span>After Input</span>
        </div>
      </div>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<div> <label>X</label> <div> <input type="text"> <span>After Input</span> </div> </div>), fragment.to_html.squish
    assert_equal %(<div> <label>X</label> <div> <input type="text"> <span>After Input</span> </div> </div>), fragment.outer_html.squish
  end

  test "non-closing <input> tag with -> in attribute" do
    html = %(
      <input data-action="input->autocomplete#search">
      <span>some text</span>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<input data-action="input->autocomplete#search"> <span>some text</span>), fragment.to_html.squish
    assert_equal %(<input data-action="input->autocomplete#search"> <span>some text</span>), fragment.outer_html.squish
  end

  test "non-closing <img> tag" do
    html = %(
      <img src="src">
      <span>test</span>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<img src="src"> <span>test</span>), fragment.to_html.squish
    assert_equal %(<img src="src"> <span>test</span>), fragment.outer_html.squish
  end

  test "non-closing <br> tag" do
    html = %(
      <br>
      <span>test</span>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<br> <span>test</span>), fragment.to_html.squish
    assert_equal %(<br> <span>test</span>), fragment.outer_html.squish
  end

  test "non-closing <hr> tag" do
    html = %(
      <hr>
      <span>test</span>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<hr> <span>test</span>), fragment.to_html.squish
    assert_equal %(<hr> <span>test</span>), fragment.outer_html.squish
  end

  test "<div> in <p>" do
    html = %(
      <p>
        <div>Invalid div</div>
      </p>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<p> </p><div>Invalid div</div> <p></p>), fragment.to_html.squish
    assert_equal %(<p> </p><div>Invalid div</div> <p></p>), fragment.outer_html.squish
  end

  test "<body> with attributes" do
    html = %(
      <body class="bg-green-200">
        <h1>Hello World</h1>
      </body>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<body class="bg-green-200"> <h1>Hello World</h1> </body>), fragment.to_html.squish
    assert_equal %(<body class="bg-green-200"> <h1>Hello World</h1> </body>), fragment.outer_html.squish
  end

  test "<head> alongside <body>" do
    html = %(
      <head></head>
      <body></body>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<head></head> <body></body>), fragment.to_html.squish
    assert_equal %(<head></head> <body></body>), fragment.outer_html.squish
  end

  test "<head> alongside <body> with content" do
    html = %(
      <head>
        <meta name="attribute" content="value">
      </head>

      <body class="bg-green-200">
        <h1>Hello World</h1>
      </body>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<head> <meta name="attribute" content="value"> </head> <body class="bg-green-200"> <h1>Hello World</h1> </body>), fragment.to_html.squish
    assert_equal %(<head> <meta name="attribute" content="value"> </head> <body class="bg-green-200"> <h1>Hello World</h1> </body>), fragment.outer_html.squish
  end

  test "<head> alongside <body> inside <html>" do
    html = %(
      <html>
        <head></head>
        <body></body>
      </html>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<html><head></head> <body> </body></html>), fragment.to_html.squish
    assert_equal %(<html><head></head> <body> </body></html>), fragment.outer_html.squish
  end

  test "<head> alongside <body> inside <html> with doctype and content" do
    html = %(
      <!DOCTYPE html>
      <html>
        <head>
          <title>Title</title>
        </head>
        <body id="body">
          <h1>Header</h1>
        </body>
      </html>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<!DOCTYPE html><html><head> <title>Title</title> </head> <body id="body"> <h1>Header</h1> </body></html>), fragment.to_html.squish
    assert_equal %(<!DOCTYPE html><html><head> <title>Title</title> </head> <body id="body"> <h1>Header</h1> </body></html>), fragment.outer_html.squish
  end

  test "<head> alongside <body> inside <html> with content" do
    html = %(
      <html>
        <head>
          <meta name="attribute" content="value">
        </head>

        <body class="bg-green-200">
          <h1>Hello World</h1>
        </body>
      </html>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<html><head> <meta name="attribute" content="value"> </head> <body class="bg-green-200"> <h1>Hello World</h1> </body></html>), fragment.to_html.squish
    assert_equal %(<html><head> <meta name="attribute" content="value"> </head> <body class="bg-green-200"> <h1>Hello World</h1> </body></html>), fragment.outer_html.squish
  end

  test "<title>" do
    html = %(
      <title>Title</title>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<title>Title</title>), fragment.to_html.squish
    assert_equal %(<title>Title</title>), fragment.outer_html.squish
  end

  test "<title> in <head>" do
    html = %(
      <head>
        <title>Title</title>
      </head>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<head> <title>Title</title> </head>), fragment.to_html.squish
    assert_equal %(<head> <title>Title</title> </head>), fragment.outer_html.squish
  end

  test "non-closed <meta>" do
    html = %(
      <meta name="title" content="value">
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<meta name="title" content="value">), fragment.to_html.squish
    assert_equal %(<meta name="title" content="value">), fragment.outer_html.squish
  end

  test "closed <meta>" do
    html = %(
      <meta name="title" content="value" />
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<meta name="title" content="value">), fragment.to_html.squish
    assert_equal %(<meta name="title" content="value">), fragment.outer_html.squish
  end

  test "non-closed <meta> in <head>" do
    html = %(
      <head>
        <meta name="title" content="value">
      </head>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<head> <meta name="title" content="value"> </head>), fragment.to_html.squish
    assert_equal %(<head> <meta name="title" content="value"> </head>), fragment.outer_html.squish
  end

  test "closed <meta> in <head>" do
    html = %(
      <head>
        <meta name="title" content="value" />
      </head>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<head> <meta name="title" content="value"> </head>), fragment.to_html.squish
    assert_equal %(<head> <meta name="title" content="value"> </head>), fragment.outer_html.squish
  end

  test "uppercase tags" do
    html = %(
      <DIV CLASS="div">
        <IMG CLASS="img">
        <SPAN CLASS="span"></SPAN>
      </DIV>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<div class="div"> <img class="img"> <span class="span"></span> </div>), fragment.to_html.squish
    assert_equal %(<div class="div"> <img class="img"> <span class="span"></span> </div>), fragment.outer_html.squish
  end

  test "boolean attribute on <div> tag" do
    html = %(
      <div data-reflex-permanent></div>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<div data-reflex-permanent=""></div>), fragment.to_html.squish
    assert_equal %(<div data-reflex-permanent=""></div>), fragment.outer_html.squish
  end

  test "boolean attribute with attribute name as value on <div> tag" do
    html = %(
      <div data-reflex-permanent="data-reflex-permanent"></div>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<div data-reflex-permanent="data-reflex-permanent"></div>), fragment.to_html.squish
    assert_equal %(<div data-reflex-permanent="data-reflex-permanent"></div>), fragment.outer_html.squish
  end

  test "boolean attribute on non-closed <input> tag" do
    html = %(
      <input required>
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<input required="">), fragment.to_html.squish
    assert_equal %(<input required="">), fragment.outer_html.squish
  end

  test "boolean attribute on closed <input> tag" do
    html = %(
      <input required />
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<input required="">), fragment.to_html.squish
    assert_equal %(<input required="">), fragment.outer_html.squish
  end

  test "boolean attribute with attribute name as value on non-closed <input> tag" do
    html = %(
      <input required="required">
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<input required="required">), fragment.to_html.squish
    assert_equal %(<input required="required">), fragment.outer_html.squish
  end

  test "boolean attribute with attribute name as value on closed <input> tag" do
    html = %(
      <input required="required" />
    )
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<input required="required">), fragment.to_html.squish
    assert_equal %(<input required="required">), fragment.outer_html.squish
  end

  test "should parse comments" do
    html = %(
      <!-- Hello Comment -->
      <div data-attribute="present" some-attribute checked>Content</div>
    )

    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<!-- Hello Comment --> <div data-attribute="present" some-attribute="" checked="">Content</div>), fragment.to_html.squish
    assert_equal %(<!-- Hello Comment --> <div data-attribute="present" some-attribute="" checked="">Content</div>), fragment.outer_html.squish
  end

  test "should parse comments with quotes" do
    html = %(
      <!-- Hello "Comment" -->
      <div data-attribute="present" some-attribute checked>Content</div>
    )

    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<!-- Hello "Comment" --> <div data-attribute="present" some-attribute="" checked="">Content</div>), fragment.to_html.squish
    assert_equal %(<!-- Hello "Comment" --> <div data-attribute="present" some-attribute="" checked="">Content</div>), fragment.outer_html.squish
  end

  test "case-sensitive attributes" do
    html = %(<div data-someThing="value">1</div>)

    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<div data-something="value">1</div>), fragment.to_html.squish
    assert_equal %(<div data-something="value">1</div>), fragment.outer_html.squish
  end

  test "case-sensitive <svg> tags" do
    html = "<svg><feSpecularLighting><fePointLight/></feSpecularLighting></svg>"

    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<svg><feSpecularLighting><fePointLight></fePointLight></feSpecularLighting></svg>), fragment.to_html.squish
    assert_equal %(<svg><feSpecularLighting><fePointLight></fePointLight></feSpecularLighting></svg>), fragment.outer_html.squish
  end

  test "non-standard HTML attributes (Alpine.js-like)" do
    html = %(<button @click.prevent="something">Button</button>)

    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal %(<button @click.prevent="something">Button</button>), fragment.to_html.squish
    assert_equal %(<button @click.prevent="something">Button</button>), fragment.outer_html.squish
  end

  test "<template> tag" do
    html = "<template></template>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<template></template>", fragment.to_html.squish
    assert_equal "<template></template>", fragment.outer_html.squish
  end

  test "<template> with <div>" do
    html = "<template><div>1</div></template>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<template><div>1</div></template>", fragment.to_html.squish
    assert_equal "<template><div>1</div></template>", fragment.outer_html.squish
  end

  test "<template> with <table>" do
    html = "<template><table><tr><td></td></tr></table></template>"
    fragment = StimulusReflex::HTML::DocumentFragment.new(html)

    assert_equal "<template><table><tbody><tr><td></td></tr></tbody></table></template>", fragment.to_html.squish
    assert_equal "<template><table><tbody><tr><td></td></tr></tbody></table></template>", fragment.outer_html.squish
  end

  test "should extract a fragment of the HTML" do
    raw_html = <<-HTML
      <div id="container">
        <h1 id="title">Home#index</h1>
      </div>
    HTML

    fragment = StimulusReflex::HTML::DocumentFragment.new(raw_html)

    inner_title = "Home#index"
    outer_title = %(<h1 id="title">#{inner_title}</h1>)
    inner_container = outer_title
    outer_container = %(<div id="container"> #{inner_container} </div>)

    assert_equal raw_html.squish, fragment.to_html.squish
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

    inner_body = %(<h1>Home#index</h1> <p>Find me in app/views/home/index.html.erb</p>)
    outer_body = %(<body id="body"> #{inner_body} </body>)

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

    inner_p = %(Find me in app/views/home/index.html.erb)
    outer_p = %(<p>#{inner_p}</p>)
    inner_body = %(<h1>Home#index</h1> #{outer_p})
    outer_body = %(<body id="body"> #{inner_body} </body>)
    inner_html = %(<head> <title>StimulusReflex Test</title> <meta name="viewport" content="width=device-width,initial-scale=1"> <meta name="csrf-param" content="authenticity_token"> <meta name="csrf-token" content="token"> <link rel="stylesheet" href="/assets/application.css" data-turbo-track="reload"> <script src="/assets/application.js" data-turbo-track="reload" defer="defer"></script> </head> #{outer_body})
    outer_html = %(<html>#{inner_html}</html>)

    assert_equal "<!DOCTYPE html>#{outer_html}", fragment.to_html.squish
    assert_equal "<!DOCTYPE html>#{outer_html}", fragment.outer_html.squish

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
end
