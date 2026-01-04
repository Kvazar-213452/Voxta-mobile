import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { HashRouter, Routes, Route } from 'react-router-dom';
import ChatRoom from './ChatRoom.tsx';
import MainPage from './MainPage.tsx';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <HashRouter>
      <Routes>
        <Route path="/chat/:id" element={<ChatRoom />} />
        <Route path="/" element={<MainPage />} />
      </Routes>
    </HashRouter>
  </StrictMode>
);
