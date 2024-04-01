# frozen_string_literal: true

require_relative "broadcaster_test_case"

module StimulusReflex
  class SelectorBroadcasterExamplesTest < StimulusReflex::BroadcasterTestCase
    test "morphs the contents of an element when selected by id" do
      assert_morph(
        selector: "#container",
        input_html: '<div id="container"><h1 id="title">Home#index</h1></div>',
        output_html: '<h1 id="title">Home#index</h1>'
      )

      assert_morph(
        selector: "#title",
        input_html: '<div id="container"><h1 id="title">Home#index</h1></div>',
        output_html: "Home#index"
      )
    end

    test "morphs the contents of an element when selected by tag" do
      # extract the body
      assert_morph(
        selector: "body",
        input_html: '<body id="body"><h1>Home#index</h1><p>Wassup</p></body>',
        output_html: "<h1>Home#index</h1><p>Wassup</p>"
      )
    end

    test "should properly handle a tr without the parent table" do
      assert_morph(
        selector: "#foo",
        input_html: "<div id='foo'><tr><td>1</td><td>2</td></tr></div>",
        output_html: "<tr><td>1</td><td>2</td></tr>"
      )

      assert_inner_html(
        selector: "#not-there",
        input_html: "<tr><td>1</td><td>2</td></tr>",
        output_html: "<tr><td>1</td><td>2</td></tr>"
      )
    end

    test "should properly handle a td without the parent table or td" do
      assert_inner_html(
        selector: "#not-there",
        input_html: "<td>1</td>",
        output_html: "<td>1</td>"
      )
    end

    test "should properly parse <tr>" do
      assert_inner_html(
        selector: "#not-there",
        input_html: '<tr data-foo="1" id="123" class="abc"><td>1</td><td>2</td></tr>',
        output_html: '<tr data-foo="1" id="123" class="abc"><td>1</td><td>2</td></tr>'
      )
    end

    test "should properly parse <td>" do
      assert_inner_html(
        selector: "#not-there",
        input_html: "<td>1</td>",
        output_html: "<td>1</td>"
      )
    end

    test "should properly parse <th>" do
      assert_inner_html(
        selector: "#not-there",
        input_html: "<th>1</th>",
        output_html: "<th>1</th>"
      )
    end

    test "should properly parse <thead>" do
      assert_inner_html(
        selector: "#not-there",
        input_html: "<thead><tr><th>1</th><th>2</th></tr></thead>",
        output_html: "<thead><tr><th>1</th><th>2</th></tr></thead>"
      )
    end

    test "should properly parse <tbody>" do
      assert_inner_html(
        selector: "#not-there",
        input_html: "<tbody><tr><th>1</th><th>2</th></tr></tbody>",
        output_html: "<tbody><tr><th>1</th><th>2</th></tr></tbody>"
      )
    end

    test "should properly parse <tfoot>" do
      assert_inner_html(
        selector: "#not-there",
        input_html: "<tfoot><tr><th>1</th><th>2</th></tr></tfoot>",
        output_html: "<tfoot><tr><th>1</th><th>2</th></tr></tfoot>"
      )
    end

    test "should properly parse <ul>" do
      assert_inner_html(
        selector: "#not-there",
        input_html: "<ul><li>1</li></ul>",
        output_html: "<ul><li>1</li></ul>"
      )
    end

    test "should properly parse <li>" do
      assert_inner_html(
        selector: "#not-there",
        input_html: "<li>1</li>",
        output_html: "<li>1</li>"
      )
    end
  end
end
