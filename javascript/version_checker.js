import Toastify from "toastify-js/src/toastify-es.js"
import CableReady from "cable_ready"

CableReady.operations.stimulusReflexVersionMismatch = operation => {
  const levels = {
    "info": {},
    "success": { background: "#198754", color: "white" },
    "warn": { background: "#ffc107", color: "black" },
    "error": { background: "#dc3545", color: "white" },
  }

  const defaults = {
    selector: setupToastify(),
    close: true,
    duration: 30 * 1000,
    gravity: "bottom",
    position: "right",
    newWindow: true,
    style: levels[operation.level || "info"]
  }

  Toastify({ ...defaults, ...operation }).showToast()
}

function setupToastify() {
  const id = "stimulus-reflex-toast-element"
  let element = document.querySelector(`#${id}`)

  if (!element) {
    element = document.createElement("div")
    element.id = id
    document.documentElement.appendChild(element)

    const styles = document.createElement("style")
    styles.innerHTML = `
      #${id} .toastify {
         padding: 12px 20px;
         color: #ffffff;
         display: inline-block;
         background: -webkit-linear-gradient(315deg, #73a5ff, #5477f5);
         background: linear-gradient(135deg, #73a5ff, #5477f5);
         position: fixed;
         opacity: 0;
         transition: all 0.4s cubic-bezier(0.215, 0.61, 0.355, 1);
         border-radius: 2px;
         cursor: pointer;
         text-decoration: none;
         max-width: calc(50% - 20px);
         z-index: 2147483647;
         bottom: -150px;
         right: 15px;
      }

      #${id} .toastify.on {
        opacity: 1;
      }

      #${id} .toast-close {
        background: transparent;
        border: 0;
        color: white;
        cursor: pointer;
        font-family: inherit;
        font-size: 1em;
        opacity: 0.4;
        padding: 0 5px;
      }
    `

    document.head.appendChild(styles)
  }

  return element
}
