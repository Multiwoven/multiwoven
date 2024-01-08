// import React, { useState } from 'react';
import {
  Avatar,
  Box,
  Flex,
  HStack,
  IconButton,
  Stack,
  StackDivider,
  Text,
  Divider,
} from '@chakra-ui/react';
import { Link as RouterLink } from 'react-router-dom';
// import { useNavigate, useLocation } from 'react-router-dom';
import IconImage from '../../assets/images/multiwoven-logo.png';
import { FiSettings, FiMoreVertical, FiDatabase, FiTable, FiPieChart, FiMinimize, FiMinimize2, FiBookOpen } from 'react-icons/fi';
import { HomeIcon } from '@heroicons/react/24/outline';
// import Cookies from 'js-cookie';
import { NavButton } from './navButton';

type MenuItem = {
  title: string;
  link: string;
  Icon: any;
};

type MenuSection = {
  heading: string | null;
  menu: MenuItem[];
};

type MenuArray = MenuSection[];

const menus: MenuArray = [
  { heading: null, menu: [{ title: 'Dashboard', link: '/', Icon: HomeIcon }] },
  {
    heading: 'Setup',
    menu: [
      { title: 'Sources', link: '/sources', Icon: FiDatabase },
      { title: 'Destinations', link: '/destinations', Icon: FiMinimize },
    ],
  },
  { heading: 'Models', menu: [{ title: 'Models', link: '/models', Icon: FiTable }] },
  {
    heading: 'Activate',
    menu: [
      { title: 'Syncs', link: '/syncs', Icon: FiMinimize2 },
      { title: 'Audiences', link: '/audiences', Icon: FiPieChart },
    ],
  },
];

const Sidebar = () => {
  // const [logoutPop, setLogoutPop] = useState(false);
  // const navigate = useNavigate();
  // const location = useLocation();

  // const handleWorkPlace = () => {
  //   setLogoutPop(!logoutPop);
  // };

  // const handleLogout = () => {
  //   Cookies.remove('authToken');
  //   navigate('/login');
  // };

  return (
    <Flex
      position="relative"
      boxShadow="0px 0px 1px rgba(48, 49, 51, 0.05),0px 2px 4px rgba(48, 49, 51, 0.1);"
      minW="240px"
      borderColor="#e0e0e0"
      borderStyle="solid"
      as="section"
      minH="100vh"
      bg="bg.canvas"
    >
      <Flex
        flex="1"
        bg="bg.surface"
        boxShadow="sm"
        maxW={{ base: 'full', sm: 'xs' }}
        py={{ base: '6', sm: '8' }}
        px={{ base: '4', sm: '6' }}
      >
        <Stack justify="space-between" spacing="1" width="full">
          <Stack spacing="5" shouldWrapChildren>
            <Flex justifyContent="center">
              <img width={160} src={IconImage} alt="IconImage" />
            </Flex>
            <Divider borderBottomWidth="1px" />
            {menus.map((categoryItem, index) => (
              <Stack key={index}>
                {categoryItem?.heading && (
                  <Text textStyle="sm" color="fg.subtle" fontWeight="medium">
                    {categoryItem?.heading}
                  </Text>
                )}
                <Stack spacing="0">
                  {categoryItem?.menu.map((menuItem, index) => (
                    <RouterLink to={menuItem.link} key={index}>
                      <NavButton label={menuItem.title} icon={menuItem.Icon} w="full" />
                    </RouterLink>
                  ))}
                </Stack>
              </Stack>
            ))}
            <Stack spacing="7" divider={<StackDivider />}>
              <Box />
              <Stack spacing="0">
                <NavButton label="Documentation" icon={FiBookOpen} />
                <NavButton label="Settings" icon={FiSettings} />
              </Stack>
              <HStack spacing="3" justify="space-between">
                <HStack spacing="3">
                  <Avatar boxSize="10" src="https://i.pravatar.cc/300" />
                  <Box>
                    <Text textStyle="sm" fontWeight="medium">
                      John Doe
                    </Text>
                    <Text textStyle="sm" color="fg.muted">
                      john@chakra-ui.com
                    </Text>
                  </Box>
                </HStack>
                <IconButton variant="tertiary" icon={<FiMoreVertical />} aria-label="Open Menu" />
              </HStack>
            </Stack>
          </Stack>
        </Stack>
      </Flex>
    </Flex>
  );
};

export default Sidebar;
