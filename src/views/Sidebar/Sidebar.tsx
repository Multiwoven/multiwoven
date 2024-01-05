
import { Box, Button, Text, Link, Container } from '@chakra-ui/react';
import { Link as RouterLink, useNavigate, useLocation } from 'react-router-dom';
import { UpDownIcon } from '@chakra-ui/icons'
import { Icon } from '@chakra-ui/react'
import IconImage from '../../assets/images/icon.png';
import { useState } from "react";
import Cookies from 'js-cookie';
import {
  CircleStackIcon,
  TableCellsIcon,
  ChartBarSquareIcon,
  BookOpenIcon,
  ArrowPathIcon,
  HomeIcon,
  CogIcon,
  UserGroupIcon,
} from '@heroicons/react/24/outline'
const Sidebar = () => {
  const [logoutPop, setLogoutPop] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  const handleWorkPlace = () => {
    setLogoutPop(!logoutPop);
  }
  const handleLogout=()=>{
    // event.stopPropagation();
    Cookies.remove('authToken');
    navigate('/login')
  }
  return (
    // <SidebarContainer>
    //   {MAIN_PAGE_ROUTES.map((pageRoutes) => (
    //     <div className="text-sm leading-6 cursor-pointer" key={pageRoutes.name}>
    //       <NavLink to={pageRoutes.url}>{pageRoutes.name}</NavLink>
    //     </div>
    //   ))}
    // </SidebarContainer>
    <>
      <Container w='256px' display='flex' margin={0} padding={0} flexDir='row' className='flex flex-col align-center justify-center'>
        <Box position={'relative'} padding={4} width={'100%'} bg='black' minH={'100vh'} color='black' borderRight={'1px'} borderRightColor={'border'}>
          <Button padding={3} background={'nav_bg'} pt={6} pb={6} position={'relative'} w={'100%'} _hover={{ background: 'nav_bg', color: 'white' }} onClick={() => handleWorkPlace()}>
            <img width={25} src={IconImage} />
            <Box padding={2} width={'100%'}>
              <Text color={'white'} fontSize={13} textAlign="left" mt={0} w={'100%'}>Multiwoven</Text>
              <Text color={'nav_text'} fontSize={11} textAlign="left" fontWeight='normal' mt={0} w={'100%'}>ID 345678</Text>
            </Box>
            <UpDownIcon color={'nav_text'} fontSize={13} />
            {logoutPop && <Box fontWeight={'normal'} borderRadius={6} background={'white'} color={'nav_bg'} position={'absolute'} top={'55px'} left={0} padding={4} pt={5} pb={5} border={'1px'} borderColor={'border'} width={'100%'}>
              <Text fontSize={14} textAlign="left" mt={0} w={'100%'}>multiwoven@gmail.com</Text>
              <Text fontSize={14} textAlign="left" mt={5} w={'100%'}>Workplace setting</Text>
              <Text fontSize={14} textAlign="left" mt={3} w={'100%'}>Add an account</Text>
              <Text fontSize={14} textAlign="left" mt={5} w={'100%'} onClick={()=> handleLogout()}>Logout</Text>
            </Box>}
          </Button>
          <Text mt={6} w={'100%'}>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/" background={location.pathname === '/' ? 'nav_bg' : ''} color="white" fontSize={14} _hover={{ background: 'nav_bg', color: 'white' }}><Icon as={HomeIcon} color={'nav_text'} fontSize={18} mr={2} /> Get Started</Link>
          </Text>
          <Text mt={6} w={'100%'}>
            <Text display='flex' pl={4} mb={2} textAlign="left" fontSize="12px" fontWeight={600} letterSpacing={2} color="gray.500">
              SETUP </Text>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/sources " color="white" fontSize={14} _hover={{ background: 'nav_bg', color: 'white' }}><Icon as={CircleStackIcon} color={'nav_text'}  fontSize={18}  mr={2} /> Sources</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/destinations" color="white" fontSize={14} _hover={{ background: 'nav_bg', color: 'white' }}> <Icon as={TableCellsIcon} color={'nav_text'}  fontSize={18}  mr={2} /> Destination</Link>
            </Text>
          <Text mt={6} w={'100%'}>
            <Text display='flex' pl={4} mb={2} textAlign="left" fontSize="12px" fontWeight={600} letterSpacing={2} color="gray.500">
              DEFINE </Text>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4}
             as={RouterLink} to="/models"
              color="white" fontSize={14} background={location.pathname === '/models' ? 'nav_bg' : ''}  _hover={{ background: 'nav_bg', color: 'white' }}><Icon as={ChartBarSquareIcon} color={'nav_text'}  fontSize={18} mr={2} /> Models</Link>
          </Text>
          <Text mt={6} w={'100%'}>
            <Text display='flex' pl={4} mb={2} textAlign="left" fontSize="12px" fontWeight={600} letterSpacing={2} color="gray.500">
              ACTIVATE </Text>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="white" fontSize={14} _hover={{ background: 'nav_bg', color: 'white' }}><Icon as={ArrowPathIcon} color={'nav_text'}  fontSize={18} mr={2} /> Syncs</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="white" fontSize={14} _hover={{ background: 'nav_bg', color: 'white' }}> <Icon as={UserGroupIcon} color={'nav_text'}  fontSize={18} mr={2} /> Audiences</Link>
          </Text>


          <Text mt={6} w={'100%'} position={'absolute'} bottom={'60px'}>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="white" fontSize={14} _hover={{ background: 'nav_bg', color: 'white' }}><Icon as={CogIcon} color={'nav_text'}  fontSize={18} mr={2} /> Settings</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="white" fontSize={14} _hover={{ background: 'nav_bg', color: 'white' }}> <Icon as={BookOpenIcon} color={'nav_text'}  fontSize={18} mr={2} /> Documentation</Link>
          </Text>

        </Box>
      </Container>
    </>
  );
};

export default Sidebar;
