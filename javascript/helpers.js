export const dispatch = (name, detail, stimulusApplication) => {
  const attrs = detail.attrs;
  let elements;
  if (attrs.id) {
    elements = document.querySelectorAll(`#${attrs.id}`);
  } else {
    let selectors = [];
    for (const key in attrs) {
      if (key === 'value') continue;
      if (key === 'checked') continue;
      if (key === 'selected') continue;
      if (!attrs.hasOwnProperty(key)) continue;
      selectors.push(`[${key}="${attrs[key]}"]`);
    }
    elements = document.querySelectorAll(selectors.join(''));
  }
  const element = elements.length === 1 ? elements[0] : null;
  const evt = new Event(name, { bubbles: true, cancelable: true });
  evt.detail = detail;
  evt.stimulusController = element
    ? stimulusApplication.getControllerForElementAndIdentifier(element, attrs['data-controller'])
    : null;

  const methods = ['beforeStimulate', 'reflexSuccess', 'reflexError', 'reflexComplete'];
  methods.forEach(method => {
    if (typeof evt.stimulusController[method] === 'function') evt.stimulusController[method](detail);
  });

  document.dispatchEvent(evt);
};
