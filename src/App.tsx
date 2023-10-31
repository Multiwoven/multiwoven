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

export default function App() {
  return (
    <div className="app-container">
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Sources />} />
          <Route path="/sources" element={<Sources />} />
          <Route path="/destinations" element={<Destination />} />
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
