const App = window.App = window.App || {};
App.cable = App.cable || ActionCable.createConsumer();

export default App;
