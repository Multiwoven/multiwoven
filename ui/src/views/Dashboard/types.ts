import { ReportObject } from '@/services/dashboard';

export type Dataset = {
  label: string;
  data: number[];
  backgroundColor: string;
};

export type ChartData = {
  labels: string[];
  datasets: Dataset[];
};

export type DataOptions = 'failed_count' | 'success_count' | 'total_count' | 'time_slice';

export type ChartDataType = {
  xData: ReportObject[];
  yData: ReportObject[];
  xDataPoints: DataOptions[];
  yDataPoints: DataOptions[];
  yLabels: Record<string, string>;
  backgroundColors: Record<string, string>;
};
