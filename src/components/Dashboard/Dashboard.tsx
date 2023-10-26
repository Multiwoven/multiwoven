import React, { ReactNode } from 'react';

type DashboardProps = {
  children?: ReactNode;
};

const Dashboard: React.FC<DashboardProps> = ({ children }) => {
  return (
    <div className="h-screen flex overflow-hidden bg-gray-100">
      {/* Mobile Sidebar */}
      <div className="md:hidden">
        {/* Mobile Sidebar Toggle Button */}
        <button className="p-4 bg-blue-600 text-white">
          Toggle Sidebar
        </button>
        {/* Rest of your mobile sidebar code */}
      </div>

      {/* Desktop Sidebar */}
      <div className="hidden md:flex md:flex-shrink-0 lg:w-72 border-r border-gray-200 bg-white">
        {/* Logo or Branding */}
        <div className="p-4">
          MyApp
        </div>
        {/* Navigation links */}
        <nav className="mt-5 px-2">
          <a href="/dashboard" className="block p-3 rounded-md bg-blue-600 text-white mb-2">
            Dashboard
          </a>
          <a href="/settings" className="block p-3 rounded-md hover:bg-blue-600 hover:text-white">
            Settings
          </a>
          {/* Add more navigation links as needed */}
        </nav>
      </div>

      {/* Main Content */}
      <div className="flex flex-col w-0 flex-1 overflow-hidden">
        <div className="relative z-10 flex-shrink-0 flex h-16 bg-white shadow">
          {/* Navbar code */}
          <div className="w-full p-4">
            Dashboard Navbar
          </div>
        </div>

        <main className="flex-1 relative overflow-y-auto focus:outline-none p-4">
          {children} {/* Your main dashboard content will be injected here */}
        </main>
      </div>
    </div>
  );
};

export default Dashboard;
