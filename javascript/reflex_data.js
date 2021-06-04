import { extractElementAttributes, extractElementDataset } from "./attributes";
import { getReflexRoots } from "./reflexes";
import { uuidv4 } from "./utils";
import { elementToXPath } from "./utils";

export default class ReflexData {
  constructor(options, reflexElement, controllerElement) {
    this.options = options;
    this.reflexElement = reflexElement;
    this.controllerElement = controllerElement;
  }

  get attrs() {
    return (
      this.options["attrs"] || extractElementAttributes(this.reflexElement)
    );
  }

  get reflexId() {
    return this.options["reflexId"] || uuidv4();
  }

  get selectors() {
    const selectors =
      this.options["selectors"] || getReflexRoots(this.reflexElement);
    if (typeof selectors === "string") {
      return [selectors];
    } else {
      return selectors;
    }
  }

  get resolveLate() {
    return this.options["resolveLate"] || false;
  }

  get dataset() {
    return extractElementDataset(this.reflexElement);
  }

  get innerHTML() {
    return this.options["includeInnerHTML"] ? this.reflexElement.innerHTML : "";
  }

  get textContent() {
    return this.options["includeTextContent"]
      ? this.reflexElement.textContent
      : "";
  }

  get xpathController() {
    return elementToXPath(this.controllerElement);
  }

  get xpathElement() {
    return elementToXPath(this.reflexElement);
  }

  valueOf() {
    return {
      attrs: this.attrs,
      dataset: this.dataset,
      selectors: this.selectors,
      reflexId: this.reflexId,
      resolveLate: this.resolveLate,
      xpathController: this.xpathController,
      xpathElement: this.xpathElement,
      inner_html: this.innerHTML,
      text_content: this.textContent
    };
  }
}
