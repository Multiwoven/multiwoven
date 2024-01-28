import { Box, Flex, Stack, Text, Divider } from "@chakra-ui/react";
import { NavLink } from "react-router-dom";
import IconImage from "../../assets/images/multiwoven-logo.png";
import {
  FiSettings,
  FiDatabase,
  FiTable,
  FiPieChart,
  FiMinimize,
  FiMinimize2,
  FiBookOpen,
} from "react-icons/fi";
import { HomeIcon } from "@heroicons/react/24/outline";
import { NavButton } from "./navButton";

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
  { heading: null, menu: [{ title: "Dashboard", link: "/", Icon: HomeIcon }] },
  {
    heading: "SETUP",
    menu: [
      { title: "Sources", link: "/setup/sources", Icon: FiDatabase },
      { title: "Destinations", link: "/destinations", Icon: FiMinimize },
    ],
  },
  {
    heading: "DEFINE",
    menu: [{ title: "Models", link: "/define/models", Icon: FiTable }],
  },
  {
    heading: "ACTIVATE",
    menu: [
      { title: "Syncs", link: "/syncs", Icon: FiMinimize2 },
      { title: "Audiences", link: "/audiences", Icon: FiPieChart },
    ],
  },
];

const renderMenuSection = (section: MenuSection, index: number) => (
  <Stack key={index}>
    {section.heading && (
      <Box paddingX="17px" marginTop="20px" marginBottom="5px">
        <Text textStyle="sm" color="fg.subtle" fontWeight="medium">
          {section.heading}
        </Text>
      </Box>
    )}
    <Stack spacing="0">
      {section.menu.map((menuItem, idx) => (
        <NavLink to={menuItem.link} key={`${index}-${idx}`}>
          {({ isActive }) => (
            <NavButton
              label={menuItem.title}
              icon={menuItem.Icon}
              isActive={isActive}
            />
          )}
        </NavLink>
      ))}
    </Stack>
  </Stack>
);

const SideBarFooter = () => (
  <Stack position="absolute" bottom="0" left="0px" right="0px" margin="24px">
    <Box />
    <Stack spacing="0">
      <NavButton label="Settings" icon={FiSettings} />
      <NavButton label="Documentation" icon={FiBookOpen} />
    </Stack>
  </Stack>
);

const Sidebar = (): JSX.Element => {
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
        maxW={{ base: "full", sm: "xs" }}
        py={{ base: "6", sm: "8" }}
        px={{ base: "4", sm: "6" }}
      >
        <Stack justify="space-between" spacing="1" width="full">
          <Stack spacing="5" shouldWrapChildren>
            <Flex justifyContent="center">
              <img width={160} src={IconImage} alt="IconImage" />
            </Flex>
            <Divider borderBottomWidth="1px" />
            {menus.map(renderMenuSection)}
            <SideBarFooter />
          </Stack>
        </Stack>
      </Flex>
    </Flex>
  );
};

export default Sidebar;
