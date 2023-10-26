import React from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import Home from './views/Home/Home';
import './tailwind.css';

const App: React.FC = () => {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen text-center bg-gray-200">
      <Router>
        <div className="flex w-full">
          {/* Sidebar */}
          <div className="w-64 bg-gray-800 min-h-screen text-white">
            <div className="p-4">
              <p>Sidebar</p>
            </div>
          </div>
          {/* Main Content */}
          <div className="flex-grow">
            <Switch>
              <Route exact path="/" component={Home} />
            </Switch>
          </div>
        </div>
      </Router>
    </div>
  );
};

export default App;

