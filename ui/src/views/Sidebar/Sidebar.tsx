import { Box, Flex, Stack, Text, Divider } from '@chakra-ui/react';
import { NavLink } from 'react-router-dom';
import IconImage from '@/assets/images/multiwoven-logo.svg';
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
import Workspace from './Workspace/Workspace';

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
        <NavLink to={menuItem.disabled ? '' : menuItem.link} key={`${index}-${idx}`}>
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

<<<<<<< HEAD
const SideBarFooter = () => (
  <Stack>
    <Profile />
  </Stack>
);

const Sidebar = (): JSX.Element => {
=======
const Sidebar = (): JSX.Element => {
  const { logoUrl = LOGO_URL } = useConfigStore.getState().configs;

>>>>>>> 2f52a500 (fix(CE): sidebar responsiveness)
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
<<<<<<< HEAD
=======
          </Stack>
          <Stack
            marginTop='20px'
            spacing='6'
            overflow='hidden auto'
            height='100%'
            justify='space-between'
            shouldWrapChildren
          >
            <Stack
              gap='16px'
              overflow='hidden auto'
              height='100%'
              justify='space-between'
              css={{
                '&::-webkit-scrollbar': {
                  width: '2px',
                },
                '&::-webkit-scrollbar-thumb': {
                  backgroundColor: 'var(--chakra-colors-gray-400)',
                },
              }}
            >
              <Workspace />
              {menus.map(renderMenuSection)}
            </Stack>
            <Stack spacing='0'>
              <NavLink to='/settings'>
                {({ isActive }) => (
                  <NavButton
                    label='Settings'
                    icon={FiSettings}
                    location='workspace'
                    isActive={isActive}
                  />
                )}
              </NavLink>
              <NavLink to='https://docs.squared.ai/guides/core-concepts'>
                <NavButton label='Documentation' icon={FiBookOpen} />
              </NavLink>
              <Profile />
            </Stack>
>>>>>>> 2f52a500 (fix(CE): sidebar responsiveness)
          </Stack>
          <Stack
            paddingX='6px'
            marginTop='20px'
            spacing='6'
            shouldWrapChildren
            overflow='hidden auto'
            css={{
              '&::-webkit-scrollbar': {
                width: '2px',
              },
              '&::-webkit-scrollbar-thumb': {
                backgroundColor: 'var(--chakra-colors-gray-400)',
              },
            }}
          >
            <Workspace />
            {menus.map(renderMenuSection)}
            <Box />
            <Stack spacing='0'>
              <NavLink to='/settings'>
                <NavButton label='Settings' icon={FiSettings} />
              </NavLink>
              <NavLink to='https://docs.squared.ai/guides/core-concepts'>
                <NavButton label='Documentation' icon={FiBookOpen} />
              </NavLink>
            </Stack>
          </Stack>
          <SideBarFooter />
        </Stack>
      </Flex>
    </Flex>
  );
};

export default Sidebar;
