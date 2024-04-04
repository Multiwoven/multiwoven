import React, { useEffect, useState } from 'react';
import { Navigate } from 'react-router-dom';
import Cookies from 'js-cookie';
import Loader from './components/Loader';

interface ProtectedProps {
  children: JSX.Element;
}

const Protected: React.FC<ProtectedProps> = ({ children }) => {
  const [isLoggedIn, setIsLoggedIn] = useState<boolean | null>(null);

  useEffect(() => {
    const authToken = Cookies.get('authToken');
    setIsLoggedIn(!!authToken);
  }, []);

  if (isLoggedIn === null) {
    return <Loader />;
  }

  if (!isLoggedIn) {
    return <Navigate to='/sign-in' replace />;
  }

  return children;
};

export default Protected;
