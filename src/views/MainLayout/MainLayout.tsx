import Sidebar from "@/views/Sidebar";
import { Box } from "@chakra-ui/layout";
import { Outlet } from "react-router-dom";

const MainLayout = (): JSX.Element => {
  return (
    <Box display="flex">
      <Sidebar />
      <Outlet />
    </Box>
  );
};

export default MainLayout;
