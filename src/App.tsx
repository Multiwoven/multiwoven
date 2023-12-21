import { Outlet, Routes, Route } from "react-router-dom";
import { MAIN_PAGE_ROUTES, AUTH_ROUTES } from "./routes"; // Assuming you have AUTH_ROUTES
import Sidebar from "./views/Sidebar";
import Heading from "./components/Heading";

const App = () => {
  return (
    <div className="md:container md:mx-auto">
      <Routes>
        {/* Routes without Sidebar */}
        {AUTH_ROUTES.map((authRoute) => (
          <Route path={authRoute.url} element={authRoute.component} key={authRoute.name} />
        ))}
      
        {/* Routes with Sidebar */}
        <Route
          path="/"
          element={
            <div className="flex p-4">
              <Sidebar />
              <Outlet />
            </div>
          }
        >
          {MAIN_PAGE_ROUTES.map((pageRoute) => (
            <Route path={pageRoute.url} element={pageRoute.component} key={pageRoute.name} />
          ))}
        </Route>
        <Route path="*" element={<Heading size="small">Page Not Found</Heading>} />
      </Routes>
    </div>
  );
};

export default App;
