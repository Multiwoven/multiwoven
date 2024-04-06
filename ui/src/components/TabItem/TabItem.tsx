import { Tab, Text } from '@chakra-ui/react';
import { TabBadge } from './TabBadge';

type TabItemProps = {
  text: string;
  action: () => void;
  isBadgeVisible?: boolean;
  badgeText?: string;
  extra?: JSX.Element;
};

const TabItem = ({ text, action, isBadgeVisible, badgeText, extra }: TabItemProps): JSX.Element => {
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
      gap='6px'
    >
      <Text fontSize='xs' fontWeight='semibold'>
        {text}
      </Text>
      {isBadgeVisible && badgeText ? <TabBadge text={badgeText} isTabSelected={true} /> : null}
      {extra}
    </Tab>
  );
};

export default TabItem;
