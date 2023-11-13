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
import { Settings } from './components/settings';
import { SourceShow } from './components/sources/show';
import { DestinationShow } from './components/destination/show';
import { Models } from './components/models';
import { ModelShow } from './components/models/show';
import ModelSelector from './components/models/new';
import ModelMethod from './components/models/method';
import { ModelDefine } from './components/models/define';

export default function App() {
  return (
    <div className="app-container">
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          
          <Route path="/sources" element={<Sources />} />
          <Route path="/sources/new" element={<SourceSelector />} />
          <Route path="/sources/connect" element={<SourceConnect />} />
          <Route path="/sources/show/:id" element={<SourceShow />} />

          <Route path="/destinations" element={<Destination />} />
          <Route path="/destinations/new" element={<DestinationSelector />} />
          <Route path="/destinations/connect" element={<DestinationConnect />} />
          <Route path="/destinations/show/:id" element={<DestinationShow />} />

          <Route path="/models" element={<Models />} />
          <Route path="/models/new" element={<ModelSelector />} />
          <Route path="/models/new/:id/method" element={<ModelMethod />} />
          <Route path="/models/new/:id/define" element={<ModelDefine />} />
          <Route path="/models/show/:id" element={<ModelShow />} />

          <Route path="/settings" element={<Settings />} />
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
