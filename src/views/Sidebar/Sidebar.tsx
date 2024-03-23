import { Box, Flex, Stack, Text, Divider } from '@chakra-ui/react';
import { NavLink } from 'react-router-dom';
import IconImage from '../../assets/images/multiwoven-logo.png';
import {
  FiSettings,
  FiDatabase,
  FiTable,
  FiBookOpen,
  FiGrid,
  FiRefreshCcw,
  FiUsers,
  FiHome,
} from 'react-icons/fi';
import { NavButton } from './navButton';
import Profile from './Profile';

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
    heading: null,
    menu: [{ title: 'Dashboard', link: '/', Icon: FiHome }],
  },
  {
    heading: 'SETUP',
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
    heading: 'DEFINE',
    menu: [{ title: 'Models', link: '/define/models', Icon: FiTable }],
  },
  {
    heading: 'ACTIVATE',
    menu: [
      { title: 'Syncs', link: '/activate/syncs', Icon: FiRefreshCcw },
      {
        title: 'Audiences',
        link: '/audiences',
        Icon: FiUsers,
        disabled: true,
      },
    ],
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

const SideBarFooter = () => (
  <Stack position='absolute' bottom='0' left='0px' right='0px' margin='24px 16px'>
    <Box />
    <Stack spacing='0'>
      <NavButton label='Settings' icon={FiSettings} disabled={true} />
      <NavLink to='https://docs.multiwoven.com/get-started/introduction'>
        <NavButton label='Documentation' icon={FiBookOpen} />
      </NavLink>
    </Stack>
    <Profile />
  </Stack>
);

const Sidebar = (): JSX.Element => {
  return (
    <Flex
      position='relative'
      as='section'
      minH='100vh'
      bg='bg.canvas'
      borderRightWidth='1px'
      borderRightStyle='solid'
      borderRightColor='gray.400'
    >
      <Flex flex='1' bg='bg.surface' maxW={{ base: 'full', sm: 'xs' }} paddingX={4} paddingY={6}>
        <Stack justify='space-between' spacing='1' width='full'>
          <Stack spacing='6' shouldWrapChildren>
            <Flex justifyContent='center'>
              <img width={160} src={IconImage} alt='IconImage' />
            </Flex>
            <Box bgColor='gray.300'>
              <Divider orientation='horizontal' />
            </Box>
            {menus.map(renderMenuSection)}
            <SideBarFooter />
          </Stack>
        </Stack>
      </Flex>
    </Flex>
  );
};

export default Sidebar;
