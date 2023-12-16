import { MAIN_PAGE_ROUTES } from "@/routes";
import { SidebarContainer } from "./styles";
import { NavLink } from "react-router-dom";

const Sidebar = () => {
  return (
    <SidebarContainer>
      {MAIN_PAGE_ROUTES.map((pageRoutes) => (
        <div className="text-sm leading-6 cursor-pointer">
          <NavLink to={pageRoutes.url}>{pageRoutes.name}</NavLink>
        </div>
      ))}
    </SidebarContainer>
  );
};

export default Sidebar;
