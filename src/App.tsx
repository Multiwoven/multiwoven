import { Routes, Route } from "react-router-dom";
import { MAIN_PAGE_ROUTES, AUTH_ROUTES } from "./routes";
import Heading from "./components/Heading";
import MainLayout from "./views/MainLayout";

const App = () => {
  return (
    <div className="md:container md:mx-auto">
      <Routes>
        {AUTH_ROUTES.map(({ url, component, name }) => (
          <Route path={url} element={component} key={name} />
        ))}
        
        <Route path="/" element={<MainLayout />}>
          {MAIN_PAGE_ROUTES.map(({ url, component, name }) => (
            <Route path={url} element={component} key={name} />
          ))}
        </Route>
        
        <Route
          path="*"
          element={<Heading size="small">Page Not Found</Heading>}
        />
      </Routes>
    </div>
  );
};

export default App;
