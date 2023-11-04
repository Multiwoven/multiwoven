import React from 'react';
import { Route, Routes } from 'react-router-dom';
import { Layout } from '../src/layouts/main'
import { BlankPage } from '../src/layouts/blank'
import { Login } from "./views/Login";
import { Sources } from "./components/sources/index";
// import { AddSources } from "./components/source/add";
// import { ChannelList } from "./components/channels/channelList";
import './App.scss';
import { Destination } from './components/destination';
import DestinationSelector from './components/destination/new';
import { DestinationConnect } from './components/destination/connect';
import Dashboard from './components/Dashboard/Dashboard';
import SourceSelector from './components/sources/new';
import { SourceConnect } from './components/sources/connect';

export default function App() {
  return (
    <div className="app-container">
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          
          <Route path="/sources" element={<Sources />} />
          <Route path="/sources/new" element={<SourceSelector />} />
          <Route path="/sources/connect" element={<SourceConnect />} />

          <Route path="/destinations" element={<Destination />} />
          <Route path="/destinations/new" element={<DestinationSelector />} />
          <Route path="/destinations/connect" element={<DestinationConnect />} />
          {/* 
          <Route path="/sources/new" element={<AddSources />} />
          <Route path="/channels" element={<ChannelList />} /> */}
        </Route>
        <Route path="/login" element={<BlankPage />}>
          <Route index element={<Login />} />
        </Route>

        {/* 

        <Route path="/404" element={<BlankPage />}>
          <Route path="*"  element={<NoMatch />} />
        </Route> */}
      </Routes>
    </div>
  );
};

function Home() {
  return (
    <div>
      <h2>Home</h2>
    </div>
  );
}
