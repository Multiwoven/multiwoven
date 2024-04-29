import { Tab, TabIndicator, TabList, Tabs, Box, Text } from '@chakra-ui/react';
import ContentContainer from '@/components/ContentContainer';
import TopBar from '@/components/TopBar';
import { useState } from 'react';
import Workspace from './Workspace';

enum SETTINGS {
  WORKSPACE = 'workspace',
  MEMBERS = 'members',
  PROFILE = 'profile',
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
            width='136px'
          >
            <TabList gap='8px'>
              <TabName
                title='Workspace'
                filterConnectors={() => setActiveSection(SETTINGS.WORKSPACE)}
              />
              {/* TODO: Will uncomment this after we launch */}
              {/* <TabName
                title='Members'
                filterConnectors={() => setActiveSection(SETTINGS.MEMBERS)}
              />
              <TabName
                title='Profile'
                filterConnectors={() => setActiveSection(SETTINGS.PROFILE)}
              /> */}
            </TabList>
            <TabIndicator />
          </Tabs>
          {activeSection === SETTINGS.WORKSPACE && <Workspace />}
          {/* {activeSection === SETTINGS.MEMBERS && <Members />} */}
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default Settings;
