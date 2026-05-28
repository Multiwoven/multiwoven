import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import React from 'react';
import { FormikProps } from 'formik';
import ScheduleTypeSelector from '../ScheduleTypeSelector';

type ScheduleFormValues = {
  schedule_type: string;
};

const TestWrapper = ({ formik }: { formik: FormikProps<ScheduleFormValues> }) => {
  return (
    <ChakraProvider>
      <ScheduleTypeSelector formik={formik} />
    </ChakraProvider>
  );
};

describe('ScheduleTypeSelector', () => {
  let formik: FormikProps<ScheduleFormValues>;

  beforeEach(() => {
    const values: ScheduleFormValues = { schedule_type: 'interval' };
    formik = {
      values,
      setFieldValue: jest.fn((name: string, value: unknown) => {
        (values as Record<string, unknown>)[name] = value;
        return Promise.resolve();
      }) as FormikProps<ScheduleFormValues>['setFieldValue'],
      handleChange: jest.fn((e: React.ChangeEvent<HTMLInputElement>) => {
        (values as Record<string, unknown>)[e.target.name] = e.target.value;
      }) as FormikProps<ScheduleFormValues>['handleChange'],
    } as FormikProps<ScheduleFormValues>;
  });

  it('renders schedule type selector', () => {
    render(<TestWrapper formik={formik} />);
    expect(screen.getByText('Schedule type')).toBeInTheDocument();
  });

  it('renders interval and cron options', () => {
    render(<TestWrapper formik={formik} />);
    expect(screen.getByText('Interval')).toBeInTheDocument();
    expect(screen.getByText('Cron Expression')).toBeInTheDocument();
  });

  it('updates schedule_type when option is selected', () => {
    render(<TestWrapper formik={formik} />);
    const cronRadio = screen.getByLabelText(/Cron Expression/i);
    fireEvent.click(cronRadio);
    // The RadioGroup uses onClick which calls handleChange, not setFieldValue directly
    expect(formik.handleChange).toHaveBeenCalled();
  });
});
