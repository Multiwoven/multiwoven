import { MAIN_PAGE_ROUTES } from "@/routes";
import { SidebarContainer } from "./styles";
import { NavLink } from "react-router-dom";
import { Box, Button, FormControl, Input, Image, Heading, Text, Link, Container } from '@chakra-ui/react';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import { PhoneIcon, MoonIcon, UpDownIcon } from '@chakra-ui/icons'
import Icon from '../../assets/images/icon.png';
import { useState } from "react";
import Cookies from 'js-cookie';

const Sidebar = () => {
  const [logoutPop, setLogoutPop] = useState(false);
  const navigate = useNavigate();

  const handleWorkPlace = () => {
    setLogoutPop(!logoutPop);
  }
  const handleLogout=(event: Event)=>{
    event.stopPropagation();
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
      <Container w='230px' display='flex' margin={0} padding={0} flexDir='row' className='flex flex-col align-center justify-center'>
        <Box padding={4} width={'100%'} bg='white' minH={'100vh'} color='black' borderRight={'1px'} borderRightColor={'#e5e7eb'}>
          <Button padding={3} pt={5} pb={5} position={'relative'} w={'100%'} onClick={() => handleWorkPlace()}>
            <img width={25} src={Icon} />
            <Box padding={2} width={'100%'}>
              <Text fontSize={13} textAlign="left" mt={0} w={'100%'}>Multiwoven</Text>
              <Text fontSize={11} textAlign="left" fontWeight='normal' mt={0} w={'100%'}>ID 345678</Text>
            </Box>
            <UpDownIcon fontSize={12} />
            {logoutPop && <Box fontWeight={'normal'} borderRadius={6} background={'white'} position={'absolute'} top={42} left={0} padding={4} pt={5} pb={5} border={'1px'} borderColor={'#e5e7eb'} width={'100%'}>
              <Text fontSize={14} textAlign="left" mt={0} w={'100%'}>multiwoven@gmail.com</Text>
              <Text fontSize={14} textAlign="left" mt={5} w={'100%'}>Workplace setting</Text>
              <Text fontSize={14} textAlign="left" mt={3} w={'100%'}>Add an account</Text>
              <Text fontSize={14} textAlign="left" mt={5} w={'100%'} onClick={(e)=> handleLogout(e)}>Logout</Text>
            </Box>}
          </Button>
          <Text mt={6} w={'100%'}>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}><PhoneIcon mr={3} /> Get Started</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}> <MoonIcon mr={3} /> Inbox</Link>
          </Text>
          <Text mt={6} w={'100%'}>
            <Text display='flex' pl={4} mb={2} textAlign="left" fontSize="12px" fontWeight={600} letterSpacing={2} color="gray.500">
              YOUR BUSINESS </Text>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}><PhoneIcon mr={3} /> Destination</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}> <MoonIcon mr={3} /> Source</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}><PhoneIcon mr={3} /> Destination</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}> <MoonIcon mr={3} /> Source</Link>
          </Text>
          <Text mt={6} w={'100%'}>
            <Text display='flex' pl={4} mb={2} textAlign="left" fontSize="12px" fontWeight={600} letterSpacing={2} color="gray.500">
              SELLER TOOLS </Text>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}><PhoneIcon mr={3} /> Destination</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}> <MoonIcon mr={3} /> Source</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}><PhoneIcon mr={3} /> Destination</Link>
            <Link fontWeight={500} mb={1} borderRadius={10} display={'flex'} alignItems={'center'} width={'100%'} padding={2} pl={4} as={RouterLink} to="/login" color="#4b5563" fontSize={14} _hover={{ background: '#731447', color: 'white' }}> <MoonIcon mr={3} /> Source</Link>
          </Text>
        </Box>
      </Container>
    </>
  );
};

export default Sidebar;
