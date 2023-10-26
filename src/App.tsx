import React from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import Dashboard from './views/Dashboard';
import './App.css';

const App: React.FC = () => {
  return (
    <div className="app-container">
      <Router>
        <div className="flex w-full">
          {/* Sidebar */}
          <div className="w-64 bg-white shadow-lg min-h-screen p-4">
            {/* Header */}
            <div className="flex items-center space-x-4 mb-4">
              <div className="rounded-full p-2 bg-blue-500 text-white">
                {/* Icon or logo can go here */}
                M
              </div>
              <h1 className="text-2xl font-semibold">MyApp</h1>
            </div>
            
            {/* Navigation */}
            <nav className="space-y-2">
              <a href="/" className="block px-4 py-2 rounded-lg hover:bg-blue-100 hover:text-blue-600">Dashboard</a>
              <a href="/dashboard" className="block px-4 py-2 rounded-lg hover:bg-blue-100 hover:text-blue-600">Data Sources</a>
              {/* Additional links */}
            </nav>
          </div>

          {/* Main Content */}
          <div className="flex-grow p-4">
            <Switch>
              <Route exact path="/" component={Dashboard} />
              <Route path="/dashboard" component={Dashboard} />
            </Switch>
          </div>
        </div>
      </Router>
    </div>
  );
};

export default App;
