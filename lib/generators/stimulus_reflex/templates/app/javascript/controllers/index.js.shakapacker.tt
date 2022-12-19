import { application } from "./application"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const controllers = definitionsFromContext(require.context("controllers", true, /_controller\.js$/))
application.load(controllers)
