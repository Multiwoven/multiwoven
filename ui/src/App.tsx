import { Routes, Route } from 'react-router-dom';
import { MAIN_PAGE_ROUTES, AUTH_ROUTES } from './routes';
import MainLayout from './views/MainLayout';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import PageNotFound from './views/PageNotFound';
import Protected from './protected-route';

const queryClient = new QueryClient();

const App = (): JSX.Element => {
  return (
    <QueryClientProvider client={queryClient}>
      <Routes>
        {AUTH_ROUTES.map(({ url, component, name }) => (
          <Route path={url} element={component} key={name} />
        ))}

        <Route path='/' element={<MainLayout />}>
          {MAIN_PAGE_ROUTES.map(({ url, component, name }) => (
            <Route path={url} key={name} element={<Protected>{component}</Protected>} />
          ))}
        </Route>

        <Route path='*' element={<PageNotFound />} />
      </Routes>
      {/* <ReactQueryDevtools initialIsOpen={false} /> */}
    </QueryClientProvider>
  );
};

export default App;
