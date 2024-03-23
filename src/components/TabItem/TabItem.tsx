import { Tab, Text } from '@chakra-ui/react';

type TabItemProps = {
  text: string;
  action: () => void;
};

const TabItem = ({ text, action }: TabItemProps): JSX.Element => {
  return (
    <Tab
      _selected={{
        backgroundColor: 'gray.100',
        borderRadius: '4px',
        color: 'black.500',
      }}
      color='black.200'
      height='30px'
      px='24px'
      py='6px'
      onClick={action}
    >
      <Text fontSize='xs' fontWeight='semibold'>
        {text}
      </Text>
    </Tab>
  );
};

export default TabItem;
