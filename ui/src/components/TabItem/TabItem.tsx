import { Tab, Text } from '@chakra-ui/react';
import { TabBadge } from './TabBadge';

type TabItemProps = {
  text: string;
  action: () => void;
  isBadgeVisible?: boolean;
  badgeText?: string;
  extra?: JSX.Element;
<<<<<<< HEAD
};

const TabItem = ({ text, action, isBadgeVisible, badgeText, extra }: TabItemProps): JSX.Element => {
=======
  icon?: JSX.Element;
  flex?: number | string;
  testId?: string;
} & TabProps;

const TabItem = ({
  text,
  action,
  isBadgeVisible,
  badgeText,
  extra,
  icon,
  testId,
  height = '30px',
  px = '24px',
  py = '6px',
  ...props
}: TabItemProps): JSX.Element => {
>>>>>>> deba42b89 (feat(CE): data-testid hooks for models, Data Apps, and workflows (#1835))
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
<<<<<<< HEAD
=======
      data-testid={testId ?? `tab-item-${text}`}
      {...props}
>>>>>>> deba42b89 (feat(CE): data-testid hooks for models, Data Apps, and workflows (#1835))
    >
      <Text fontSize='xs' fontWeight='semibold'>
        {text}
      </Text>
      {isBadgeVisible && badgeText ? <TabBadge text={badgeText} /> : null}
      {extra}
    </Tab>
  );
};

export default TabItem;
