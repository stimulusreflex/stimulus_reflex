import { ControllerMethods } from './controller';

export const controllers = {};

export const register = controller => {
  if (!controllers[controller.identifier]) {
    Object.assign(controller, ControllerMethods);
    controllers[controller.identifier] = controller;
  }
  return controller;
}
