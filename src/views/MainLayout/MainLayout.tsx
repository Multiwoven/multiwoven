import Sidebar from "@/views/Sidebar";
import { Box, Container } from "@chakra-ui/layout";
import { Outlet } from "react-router-dom";

const MainLayout = (): JSX.Element => {
  return (
    <Box display="flex" width={'100%'}>
      <Sidebar />
      <Container width={'100%'} maxW={'100%'} display='flex' flex={1} flexDir='row' margin={6} border={'2px'} borderStyle={'dashed'} borderColor={'#ccc'} padding={4} className='flex'>
        <Outlet />
      </Container>
    </Box>
  );
};

export default MainLayout;
