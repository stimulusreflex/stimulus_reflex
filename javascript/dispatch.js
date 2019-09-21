const eventCallbackMappings = {
  'stimulus-reflex:before': 'reflexStart',
  'stimulus-reflex:success': 'reflexSuccess',
  'stimulus-reflex:error': 'reflexError',
  'stimulus-reflex:complete': 'reflexComplete',
};

export default (name, detail, stimulusApplication) => {
  const attrs = detail.attrs;
  let elements = [];
  if (attrs.id) {
    elements = document.querySelectorAll(`#${attrs.id}`);
  } else {
    let selectors = [];
    for (const key in attrs) {
      if (key.indexOf('.') >= 0) continue;
      if (key === 'value') continue;
      if (key === 'checked') continue;
      if (key === 'selected') continue;
      if (!attrs.hasOwnProperty(key)) continue;
      selectors.push(`[${key}="${attrs[key]}"]`);
    }
    try {
      elements = document.querySelectorAll(selectors.join(''));
    } catch (error) {
      console.log(
        'StimulusReflex encountered an error identifying the Stimulus element. Consider adding an #id to the element.',
        error,
        detail
      );
    }
  }

  let controller = null;
  const element = elements.length === 1 ? elements[0] : null;
  const callback = eventCallbackMappings[name];
  const evt = new Event(name, { bubbles: true, cancelable: true });
  evt.detail = detail;

  if (element)
    controller = stimulusApplication.getControllerForElementAndIdentifier(element, attrs['data-controller']);
  evt.stimulusController = controller;

  if (controller) {
    if (typeof controller[callback] === 'function') controller[callback](detail);
  } else {
    console.log(
      'StimulusReflex was unable to identify the Stimulus controller. Consider adding an #id to the element.'
    );
  }

  document.dispatchEvent(evt);
};
