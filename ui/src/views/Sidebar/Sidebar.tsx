import { Box, Flex, Stack, Text, Divider, useMediaQuery } from '@chakra-ui/react';
import { NavLink } from 'react-router-dom';
import IconImage from '../../assets/images/multiwoven-logo.png';
import {
  FiSettings,
  FiDatabase,
  FiTable,
  FiBookOpen,
  FiGrid,
  FiRefreshCcw,
  FiBarChart2,
  FiTool,
} from 'react-icons/fi';
import { NavButton } from './navButton';
import Profile from './Profile';
import Workspace from './Workspace';

import mwTheme from '@/chakra.config';

type MenuItem = {
  title: string;
  link: string;
  Icon: any;
  disabled?: boolean;
};

type MenuSection = {
  heading: string | null;
  menu: MenuItem[];
};

type MenuArray = MenuSection[];

const menus: MenuArray = [
  {
    heading: 'DATA ACTIVATION',
    menu: [
      { title: 'Reports', link: '/', Icon: FiBarChart2 },
      { title: 'Models', link: '/define/models', Icon: FiTable },
      { title: 'Syncs', link: '/activate/syncs', Icon: FiRefreshCcw },
    ],
  },
  {
    heading: 'DATA INTEGRATION',
    menu: [
      { title: 'Sources', link: '/setup/sources', Icon: FiDatabase },
      {
        title: 'Destinations',
        link: '/setup/destinations',
        Icon: FiGrid,
      },
    ],
  },
  {
    heading: 'AI/ML INTEGRATION',
    menu: [{ title: 'ML Ops', link: '/ml-ops', Icon: FiTool }],
  },
];

const renderMenuSection = (section: MenuSection, index: number) => (
  <Stack key={index}>
    {section.heading && (
      <Box paddingX='16px'>
        <Text size='xs' color='gray.600' fontWeight='bold' letterSpacing='2.4px'>
          {section.heading}
        </Text>
      </Box>
    )}
    <Stack spacing='0'>
      {section.menu.map((menuItem, idx) => (
        <NavLink to={menuItem.link} key={`${index}-${idx}`}>
          {({ isActive }) => (
            <NavButton
              label={menuItem.title}
              icon={menuItem.Icon}
              isActive={isActive}
              disabled={menuItem.disabled}
            />
          )}
        </NavLink>
      ))}
    </Stack>
  </Stack>
);

const SideBarFooter = ({ isSticky }: { isSticky: boolean }) => (
  <Stack
    position={isSticky ? 'relative' : 'absolute'}
    bottom='0'
    left='0px'
    right='0px'
    margin={isSticky ? '24px 0px' : '24px 16px'}
  >
    <Box />
    <Stack spacing='0'>
      <NavLink to='/settings'>
        <NavButton label='Settings' icon={FiSettings} />
      </NavLink>
      <NavLink to='https://docs.squared.ai/guides/core-concepts'>
        <NavButton label='Documentation' icon={FiBookOpen} />
      </NavLink>
    </Stack>
    <Profile />
  </Stack>
);

const Sidebar = (): JSX.Element => {
  const { logoUrl } = mwTheme;
  const [isSmallerScreenResolution] = useMediaQuery('(max-height: 748px)');
  return (
    <Flex
      position='relative'
      as='section'
      minH='100vh'
      bg='bg.canvas'
      borderRightWidth='1px'
      borderRightStyle='solid'
      borderRightColor='gray.400'
      minWidth='240px'
      overflowY='auto'
      overflowX='hidden'
      sx={{
        '&::-webkit-scrollbar': {
          width: '2px',
        },
        '&::-webkit-scrollbar-thumb': {
          backgroundColor: 'gray.400',
        },
      }}
    >
      <Flex flex='1' bg='bg.surface' maxW={{ base: 'full', sm: 'xs' }} paddingX={4} paddingY={6}>
        <Stack justify='space-between' spacing='1' width='full'>
          <Stack spacing='6' shouldWrapChildren>
            <Flex justifyContent='center'>
              <img width={160} src={logoUrl ? logoUrl : IconImage} alt='IconImage' />
            </Flex>
            <Box bgColor='gray.300'>
              <Divider orientation='horizontal' />
            </Box>
            <Workspace />
            {menus.map(renderMenuSection)}
            <SideBarFooter isSticky={isSmallerScreenResolution} />
          </Stack>
        </Stack>
      </Flex>
    </Flex>
  );
};

export default Sidebar;
