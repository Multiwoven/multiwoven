import { Breadcrumb, BreadcrumbItem, Text } from '@chakra-ui/react';
import { Step } from './types';
import { Link } from 'react-router-dom';

type BreadcrumbsProps = {
  steps: Step[];
};

const Breadcrumbs = ({ steps }: BreadcrumbsProps): JSX.Element => (
  <Breadcrumb separator='/' marginBottom='10px' color='gray.600'>
    {steps.map((step) => (
      <BreadcrumbItem key={step.name}>
        <Link to={step.url}>
          {step?.url > '' ? (
            <Text size='sm' color='black.100' fontWeight='regular'>
              {step.name}
            </Text>
          ) : (
            <Text size='sm' color='black.500' fontWeight='semibold'>
              {step.name}
            </Text>
          )}
        </Link>
      </BreadcrumbItem>
    ))}
  </Breadcrumb>
);

export default Breadcrumbs;
