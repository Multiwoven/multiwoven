import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { expect, describe, it, beforeEach } from '@jest/globals';
import '@testing-library/jest-dom/jest-globals';
import '@testing-library/jest-dom';
import { ChakraProvider } from '@chakra-ui/react';
import { FormikProps } from 'formik';
import SyncScheduleOptionsContainer from '../SyncScheduleOptionsContainer';

type ScheduleFormValues = {
  schedule_type: string;
  sync_interval: number;
  sync_interval_unit: string;
  cron_expression: string;
};

jest.mock('../ScheduleTypeSelector', () => ({
  __esModule: true,
  default: ({ formik }: { formik: FormikProps<ScheduleFormValues> }) => (
    <div data-testid='schedule-type-selector'>
      <button onClick={() => formik.setFieldValue('schedule_type', 'interval')}>Interval</button>
      <button onClick={() => formik.setFieldValue('schedule_type', 'cron_expression')}>Cron</button>
    </div>
  ),
}));

jest.mock('../CronScheduleType', () => ({
  __esModule: true,
  default: ({ formik }: { formik: FormikProps<ScheduleFormValues> }) => (
    <div data-testid='cron-schedule-type'>
      <input
        data-testid='cron-input'
        value={formik.values.cron_expression}
        onChange={(e) => formik.setFieldValue('cron_expression', e.target.value)}
      />
    </div>
  ),
}));

const TestWrapper = ({ formik }: { formik: FormikProps<ScheduleFormValues> }) => {
  return (
    <ChakraProvider>
      <SyncScheduleOptionsContainer formik={formik} />
    </ChakraProvider>
  );
};

describe('SyncScheduleOptionsContainer', () => {
  let formik: FormikProps<ScheduleFormValues>;

  beforeEach(() => {
    const values: ScheduleFormValues = {
      schedule_type: 'interval',
      sync_interval: 0,
      sync_interval_unit: 'minutes',
      cron_expression: '',
    };
    formik = {
      values,
      handleChange: jest.fn((e: React.ChangeEvent<HTMLInputElement>) => {
        (values as Record<string, unknown>)[e.target.name] = e.target.value;
      }) as FormikProps<ScheduleFormValues>['handleChange'],
      setFieldValue: jest.fn((name: string, value: unknown) => {
        (values as Record<string, unknown>)[name] = value;
        return Promise.resolve();
      }) as FormikProps<ScheduleFormValues>['setFieldValue'],
    } as FormikProps<ScheduleFormValues>;
  });

  it('renders ScheduleTypeSelector', () => {
    render(<TestWrapper formik={formik} />);
    expect(screen.getByTestId('schedule-type-selector')).toBeInTheDocument();
  });

  it('renders interval configuration when schedule_type is interval', () => {
    render(<TestWrapper formik={formik} />);
    expect(screen.getByText('Schedule Configuration')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Enter a value')).toBeInTheDocument();
  });

  it('renders cron configuration when schedule_type is cron_expression', () => {
    formik.values.schedule_type = 'cron_expression';
    render(<TestWrapper formik={formik} />);
    const cronButton = screen.getByText('Cron');
    fireEvent.click(cronButton);
    expect(screen.getByTestId('cron-schedule-type')).toBeInTheDocument();
  });

  it('updates sync_interval when input changes', () => {
    render(<TestWrapper formik={formik} />);
    const input = screen.getByPlaceholderText('Enter a value');
    fireEvent.change(input, { target: { value: '5', name: 'sync_interval' } });
    expect(formik.handleChange).toHaveBeenCalled();
  });

  it('updates sync_interval_unit when select changes', () => {
    render(<TestWrapper formik={formik} />);
    const select = screen.getByRole('combobox');
    fireEvent.change(select, { target: { value: 'hours', name: 'sync_interval_unit' } });
    expect(formik.handleChange).toHaveBeenCalled();
  });
});
