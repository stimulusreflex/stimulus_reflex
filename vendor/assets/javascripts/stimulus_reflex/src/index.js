import { Methods } from './controller';

export const controllers = {};

export const register = controller => {
  if (!controllers[controller.identifier]) {
    Object.assign(controller, Methods);
    controllers[controller.identifier] = controller;
  }
  return controller;
}
