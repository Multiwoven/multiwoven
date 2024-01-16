import { Routes, Route } from "react-router-dom";
import { MAIN_PAGE_ROUTES, AUTH_ROUTES } from "./routes";
import Heading from "./components/Heading";
import MainLayout from "./views/MainLayout";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const queryClient = new QueryClient();

const App = (): JSX.Element => {
  return (
    <QueryClientProvider client={queryClient}>
      <Routes>
        {AUTH_ROUTES.map((authRoute) => (
          <Route
            path={authRoute.url}
            element={authRoute.component}
            key={authRoute.name}
          />
        ))}
        <Route path="/" element={<MainLayout />}>
          {MAIN_PAGE_ROUTES.map((pageRoute) => (
            <Route
              path={pageRoute.url}
              element={pageRoute.component}
              key={pageRoute.name}
            />
          ))}
        </Route>
        <Route
          path="*"
          element={<Heading size="small">Page Not Found</Heading>}
        />
      </Routes>
    </QueryClientProvider>
  );
};
export default App;
