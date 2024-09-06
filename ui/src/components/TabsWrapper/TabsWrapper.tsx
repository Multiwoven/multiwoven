import { Tabs, TabIndicator } from '@chakra-ui/react';

const TabsWrapper = ({ children }: { children: JSX.Element }) => (
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
    {children}
    <TabIndicator />
  </Tabs>
);

export default TabsWrapper;
