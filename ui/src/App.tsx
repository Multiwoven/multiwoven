import { Routes, Route } from 'react-router-dom';
import { MAIN_PAGE_ROUTES, AUTH_ROUTES } from '@/routes';
import MainLayout from '@/views/MainLayout';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import PageNotFound from '@/views/PageNotFound';
import Protected from '@/protected-route';
import { useEffect, useState } from 'react';
import mwTheme from '@/chakra.config';
import { ChakraProvider } from '@chakra-ui/react';
import { useConfigStore } from '@/stores/useConfigStore';
import Loader from '@/components/Loader';

const queryClient = new QueryClient();

const App = (): JSX.Element => {
  const setConfigs = useConfigStore((state) => state.setConfigs);
  const [fetchingEnv, setFetchingEnv] = useState(true);

  const { brandName, favIconUrl } = mwTheme;

  useEffect(() => {
    if (document) {
      // Set document title using VITE_BRAND_NAME
      document.title = brandName;

      // Set the favicon
      const favicon = document?.getElementById('favicon') as HTMLLinkElement;
      if (favicon && favIconUrl > '') {
        favicon.href = favIconUrl;
      }
    }
  }, [brandName, favIconUrl]);

  useEffect(() => {
    (async () => {
      let serverEnvs: {
        VITE_API_HOST?: string;
      } = {};

      try {
        const response = await fetch('/env');
        serverEnvs = await response.json();
      } catch (err) {
        // show toast
      }

      setConfigs({
        apiHost: serverEnvs.VITE_API_HOST || import.meta.env.VITE_API_HOST,
      });
      setFetchingEnv(false);
    })();
  }, []);

  if (fetchingEnv) {
    return (
      <ChakraProvider theme={mwTheme}>
        <Loader />
      </ChakraProvider>
    );
  }

  return (
    <ChakraProvider theme={mwTheme}>
      <QueryClientProvider client={queryClient}>
        <Routes>
          {AUTH_ROUTES.map(({ url, component, name }) => (
            <Route path={url} element={component} key={name} />
          ))}

          <Route
            path='/'
            element={
              <Protected>
                <MainLayout />
              </Protected>
            }
          >
            {MAIN_PAGE_ROUTES.map(({ url, component, name }) => (
              <Route path={url} key={name} element={<Protected>{component}</Protected>} />
            ))}
          </Route>

          <Route path='*' element={<PageNotFound />} />
        </Routes>
        {/* <ReactQueryDevtools initialIsOpen={false} /> */}
      </QueryClientProvider>
    </ChakraProvider>
  );
};

export default App;
