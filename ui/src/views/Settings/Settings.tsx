import { Tab, TabIndicator, TabList, Tabs, Box, Text } from '@chakra-ui/react';
import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';
import { useState } from 'react';
import Workspace from './Workspace';

enum SETTINGS {
  WORKSPACE = 'workspace',
}

const TabName = ({ title, filterConnectors }: { title: string; filterConnectors: () => void }) => (
  <Tab
    _selected={{
      backgroundColor: 'gray.100',
      borderRadius: '4px',
      color: 'black.500',
    }}
    color='black.200'
    onClick={filterConnectors}
    paddingX='24px'
    width='128px'
  >
    <Text size='xs' fontWeight='semibold'>
      {title}
    </Text>
  </Tab>
);

const Settings = () => {
  const [activeSection, setActiveSection] = useState<SETTINGS>(SETTINGS.WORKSPACE);

  return (
<<<<<<< HEAD
    <Box width='100%' display='flex' flexDirection='column' alignItems='center'>
      <ContentContainer>
        <TopBar
          name={'Settings'}
          ctaName=''
          ctaButtonVariant='solid'
          onCtaClicked={() => {}}
          isCtaVisible={false}
        />
        <Box display='flex' flexDirection='column' gap='20px'>
          <Tabs
            size='md'
            variant='indicator'
            background='gray.300'
            padding={1}
            borderRadius='8px'
            borderStyle='solid'
            borderWidth='1px'
            borderColor='gray.400'
            width='fit-content'
          >
            <TabList gap='8px'>
              <TabName
                title='Workspace'
                filterConnectors={() => setActiveSection(SETTINGS.WORKSPACE)}
              />
            </TabList>
            <TabIndicator />
          </Tabs>
          {activeSection === SETTINGS.WORKSPACE && <Workspace />}
        </Box>
      </ContentContainer>
    </Box>
=======
    <ContentContainer>
      <TopBar name={'Settings'} ctaName='' ctaButtonVariant='solid' />
      <Box display='flex' flexDirection='column' gap='20px'>
        <TabsWrapper
          index={activeTab}
          onChange={(tabIndex) => handleTabOnChange(tabLocations[tabIndex])}
        >
          <TabList gap='8px'>
            <RoleAccess location='workspace' type='item' action={UserActions.Read}>
              <TabItem text='Workspace' />
            </RoleAccess>
            <RoleAccess location='user' type='item' action={UserActions.Read}>
              <RoleAccess location='user' type='item' action={UserActions.Create}>
                <TabItem text='Members' />
              </RoleAccess>
            </RoleAccess>
            <RoleAccess location='user' type='item' action={UserActions.Read}>
              <TabItem text='Profile' />
            </RoleAccess>

            <RoleAccess location='audit_logs' type='item' action={UserActions.Read}>
              <TabItem text='Audit Logs' />
            </RoleAccess>
            <RoleAccess location='alerts' type='item' action={UserActions.Read}>
              <TabItem text='Alerts' />
            </RoleAccess>
          </TabList>
        </TabsWrapper>
        {children}
      </Box>
    </ContentContainer>
>>>>>>> 6e1cfad3 (fix(CE): Content centered at max width)
  );
};

export default Settings;
