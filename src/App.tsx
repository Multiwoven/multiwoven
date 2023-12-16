import { Outlet } from "react-router";
import { MAIN_PAGE_ROUTES } from "./routes";
import Sidebar from "./views/Sidebar";
import { Routes, Route } from "react-router-dom";
import Heading from "./components/Heading";

const App = () => {
  return (
    <div className="md:container md:mx-auto">
      <div className="flex p-4">
        <Sidebar />
        <Outlet />
        <Routes>
          {MAIN_PAGE_ROUTES.map((pageRoutes) => (
            <Route path={pageRoutes.url} element={pageRoutes.component} />
          ))}
          <Route path="*" element={<Heading>Page Not Found</Heading>} />
        </Routes>
      </div>
    </div>
  );
};

export default App;
