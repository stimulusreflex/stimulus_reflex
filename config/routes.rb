StimulusReflex::Engine.routes.draw do
  post 'receive', to: 'application#receive'
end
