class ExamplesController < ApplicationController
  layout false

  def show
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.append_all("body", cable_ready_tag(cable_car.console_log(message: "Dear John,\n\nI'd hoped this day would never come. I loved you, but I don't recognize who you've become.\n\nIt's over, and I'm taking the kids.\n\nDon't try to contact me. I hope that Turbo Streams makes you happy in all of the ways that I never could.\n\nGladys")))
      end
    end
  end

  def create
    # respond with [{"html":"Created","selector":"#cable_car_output","operation":"innerHtml"}]
    render operations: cable_car.inner_html("#cable_car_output", html: "Created")
  end
  
  def update
    render operations: cable_car
      .inner_html("#cable_car_output", html: "Updated")
      .set_style("#explanation", name: "display", value: "block")
      .console_log(message: "You can chain together as many operations as you want, and they are executed in the order that they are specified. Operations use a simple JSON format; no executable code means no security issues.")
  end

  def destroy
    render operations: cable_car
      .inner_html("#cable_car_output", html: "Deleted")
      .console_log(message: "One of the most powerful features of CableReady is the ability to generate client side events. Your Stimulus controllers can capture these events, upgrading your sprinkles to magical nanorobots.")
      .dispatch_event(name: "example:destroyed")
  end
end
