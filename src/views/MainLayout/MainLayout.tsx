import Sidebar from "@/views/Sidebar";
import { Box } from "@chakra-ui/layout";
import { Outlet } from "react-router-dom";

const MainLayout = (): JSX.Element => {
  return (
    <Box display="flex" width={"100%"}>
      <Sidebar />
      <Box
        pl={0}
        bg={"#fcfcfc"}
        width={"100%"}
        maxW={"100%"}
        display="flex"
        flex={1}
        flexDir="row"
        className="flex"
      >
        <Outlet />
      </Box>
    </Box>
  );
};

export default MainLayout;
